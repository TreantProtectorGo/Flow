import Flutter
import EventKit
import EventKitUI
import UIKit
import UserNotifications

#if canImport(AlarmKit)
import AlarmKit
import SwiftUI
#endif

#if canImport(AlarmKit)
@available(iOS 26.0, *)
struct FocusTaskAlarmMetadata: AlarmMetadata {
  let taskId: String
  let nextTaskId: String?
  let sectionId: String?
  let phaseIndex: Int
  let payloadType: String
  let taskTitle: String
  let pomodoroProgress: String
  let alarmId: String
}
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, EKEventEditViewDelegate {
  private let eventStore = EKEventStore()
  private var pendingCalendarResult: FlutterResult?
  private var taskTimerChannel: FlutterMethodChannel?
  private var pendingTaskTimerPayload: [String: Any]?
  private let taskTimerAppGroupIdentifier = "group.com.shape.focus"
  private let taskTimerControlEventsKey = "focus.taskTimer.controlEvents"
  private let taskTimerNotificationPrefix = "focus.taskTimer"
  private let taskTimerAlarmIdsKeyPrefix = "focus.taskTimer.alarmIds"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required for flutter_local_notifications on iOS 10+
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let taskTimerChannel = FlutterMethodChannel(
        name: "focus/task_timer_system",
        binaryMessenger: controller.binaryMessenger
      )
      self.taskTimerChannel = taskTimerChannel
      taskTimerChannel.setMethodCallHandler { [weak self] call, result in
        self?.handleTaskTimerCall(call, result: result)
      }
      flushPendingTaskTimerPayload()
      flushPendingTaskTimerControlEvents()

      let channel = FlutterMethodChannel(
        name: "focus/calendar",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else {
          result(FlutterError(code: "UNAVAILABLE", message: "App delegate unavailable", details: nil))
          return
        }

        if call.method == "presentEventEditor" {
          guard
            let args = call.arguments as? [String: Any],
            let title = args["title"] as? String,
            let description = args["description"] as? String,
            let startMillis = args["startMillis"] as? NSNumber,
            let endMillis = args["endMillis"] as? NSNumber
          else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing event arguments", details: nil))
            return
          }

          let startDate = Date(timeIntervalSince1970: startMillis.doubleValue / 1000.0)
          let endDate = Date(timeIntervalSince1970: endMillis.doubleValue / 1000.0)
          self.presentCalendarEditor(
            title: title,
            details: description,
            startDate: startDate,
            endDate: endDate,
            result: result
          )
          return
        }

        if call.method == "saveEvents" {
          guard
            let args = call.arguments as? [String: Any],
            let events = args["events"] as? [[String: Any]]
          else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing events payload", details: nil))
            return
          }

          self.saveEvents(events, result: result)
          return
        }

        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    flushPendingTaskTimerControlEvents()
  }

  private func handleTaskTimerCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "scheduleTaskTimeline":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "BAD_ARGS", message: "Missing task timer plan", details: nil))
        return
      }
      scheduleTaskTimeline(args, result: result)
    case "cancelTaskTimeline":
      guard
        let args = call.arguments as? [String: Any],
        let taskId = args["taskId"] as? String
      else {
        result(FlutterError(code: "BAD_ARGS", message: "Missing taskId", details: nil))
        return
      }
      cancelTaskTimeline(taskId: taskId) {
        result(nil)
      }
    case "requestAuthorization":
      requestTaskTimerAuthorization(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestTaskTimerAuthorization(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
#if canImport(AlarmKit)
      if #available(iOS 26.0, *) {
        Task {
          do {
            let state = try await AlarmManager.shared.requestAuthorization()
            DispatchQueue.main.async {
              result(String(describing: state))
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil))
            }
          }
        }
        return
      }
#endif
      DispatchQueue.main.async {
        result("notificationsOnly")
      }
    }
  }

  private func scheduleTaskTimeline(_ args: [String: Any], result: @escaping FlutterResult) {
    guard
      let taskId = args["taskId"] as? String,
      let taskTitle = args["taskTitle"] as? String,
      let phases = args["phases"] as? [[String: Any]]
    else {
      result(FlutterError(code: "BAD_ARGS", message: "Invalid task timer plan", details: nil))
      return
    }

    cancelTaskTimeline(taskId: taskId) { [weak self] in
      guard let self = self else { return }

      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] _, _ in
        guard let self = self else { return }

#if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
          Task {
            let alarmIdsByPhase = await self.scheduleAlarmKitTimeline(
              taskId: taskId,
              taskTitle: taskTitle,
              sectionId: args["sectionId"] as? String,
              nextTaskId: args["nextTaskId"] as? String,
              phases: phases
            )
            await MainActor.run {
              UserDefaults.standard.set(
                alarmIdsByPhase.values.map { $0.uuidString },
                forKey: self.taskTimerAlarmIdsKey(taskId)
              )
              let alarmedPhaseIndexes = Set(alarmIdsByPhase.keys)
              for phase in phases {
                let phaseIndex = (phase["phaseIndex"] as? NSNumber)?.intValue ?? -1
                if alarmedPhaseIndexes.contains(phaseIndex) {
                  continue
                }
                self.scheduleTaskTimerNotification(
                  taskId: taskId,
                  taskTitle: taskTitle,
                  sectionId: args["sectionId"] as? String,
                  nextTaskId: args["nextTaskId"] as? String,
                  nextTaskTitle: args["nextTaskTitle"] as? String,
                  phase: phase
                )
              }
              result(nil)
            }
          }
          return
        }
#endif

        for phase in phases {
          self.scheduleTaskTimerNotification(
            taskId: taskId,
            taskTitle: taskTitle,
            sectionId: args["sectionId"] as? String,
            nextTaskId: args["nextTaskId"] as? String,
            nextTaskTitle: args["nextTaskTitle"] as? String,
            phase: phase
          )
        }

        DispatchQueue.main.async {
          result(nil)
        }
      }
    }
  }

  private func scheduleTaskTimerNotification(
    taskId: String,
    taskTitle: String,
    sectionId: String?,
    nextTaskId: String?,
    nextTaskTitle: String?,
    phase: [String: Any]
  ) {
    guard
      let phaseIndex = (phase["phaseIndex"] as? NSNumber)?.intValue,
      let endAtMillis = (phase["endAt"] as? NSNumber)?.doubleValue
    else {
      return
    }

    let endAt = Date(timeIntervalSince1970: endAtMillis / 1000.0)
    guard endAt > Date() else {
      return
    }

    let content = UNMutableNotificationContent()
    content.title = phase["alertTitle"] as? String ?? taskTitle
    content.body = phase["alertBody"] as? String ?? ""
    content.sound = .default
    content.userInfo = taskTimerPayload(
      taskId: taskId,
      sectionId: sectionId,
      nextTaskId: nextTaskId,
      phaseIndex: phaseIndex,
      payloadType: phase["payloadType"] as? String ?? "phaseEnd"
    )

    let components = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute, .second],
      from: endAt
    )
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    let request = UNNotificationRequest(
      identifier: taskTimerNotificationIdentifier(taskId: taskId, phaseIndex: phaseIndex),
      content: content,
      trigger: trigger
    )
    UNUserNotificationCenter.current().add(request)
  }

#if canImport(AlarmKit)
  @available(iOS 26.0, *)
  private func scheduleAlarmKitTimeline(
    taskId: String,
    taskTitle: String,
    sectionId: String?,
    nextTaskId: String?,
    phases: [[String: Any]]
  ) async -> [Int: UUID] {
    do {
      let authorization = try await AlarmManager.shared.requestAuthorization()
      guard authorization == .authorized else {
        return [:]
      }
    } catch {
      return [:]
    }

    var alarmIdsByPhase: [Int: UUID] = [:]
    for phase in phases {
      guard
        let phaseIndex = (phase["phaseIndex"] as? NSNumber)?.intValue,
        let endAtMillis = (phase["endAt"] as? NSNumber)?.doubleValue
      else {
        continue
      }

      let endAt = Date(timeIntervalSince1970: endAtMillis / 1000.0)
      guard endAt > Date() else {
        continue
      }

      let title = phase["alertTitle"] as? String ?? taskTitle
      let payloadType = phase["payloadType"] as? String ?? "phaseEnd"
      let completed = (phase["completedPomodorosAtEnd"] as? NSNumber)?.intValue ?? 0
      let total = (phase["totalPomodoros"] as? NSNumber)?.intValue ?? 0
      let progress = "\(completed)/\(total)"
      let accentColor = Color(red: 0.67, green: 0.78, blue: 1.0)
      let alarmId = UUID()
      let stopButton = AlarmButton(
        text: localizedResource("Stop"),
        textColor: accentColor,
        systemImageName: "stop.circle"
      )
      let pauseButton = AlarmButton(
        text: localizedResource("Pause"),
        textColor: accentColor,
        systemImageName: "pause.circle"
      )
      let resumeButton = AlarmButton(
        text: localizedResource("Resume"),
        textColor: accentColor,
        systemImageName: "play.circle"
      )
      let alert = AlarmPresentation.Alert(
        title: localizedResource(title),
        stopButton: stopButton
      )
      // Keep one AlarmKit countdown active at a time to avoid stacking multiple
      // system timer presentations for a single task timeline.
      guard phaseIndex == 0 else {
        continue
      }

      let countdown = AlarmPresentation.Countdown(title: localizedResource("Flow"), pauseButton: pauseButton)
      let paused = AlarmPresentation.Paused(title: localizedResource("Timer paused"), resumeButton: resumeButton)
      let presentation = AlarmPresentation(alert: alert, countdown: countdown, paused: paused)
      let metadata = FocusTaskAlarmMetadata(
        taskId: taskId,
        nextTaskId: nextTaskId,
        sectionId: sectionId,
        phaseIndex: phaseIndex,
        payloadType: payloadType,
        taskTitle: taskTitle,
        pomodoroProgress: progress,
        alarmId: alarmId.uuidString
      )
      let attributes = AlarmAttributes(
        presentation: presentation,
        metadata: metadata,
        tintColor: accentColor
      )
      let duration = max(1, endAt.timeIntervalSinceNow)
      let configuration = AlarmManager.AlarmConfiguration.timer(
        duration: duration,
        attributes: attributes
      )

      do {
        _ = try await AlarmManager.shared.schedule(id: alarmId, configuration: configuration)
        alarmIdsByPhase[phaseIndex] = alarmId
      } catch {
        continue
      }
    }

    return alarmIdsByPhase
  }

  @available(iOS 26.0, *)
  private func localizedResource(_ text: String) -> LocalizedStringResource {
    LocalizedStringResource(String.LocalizationValue(stringLiteral: text))
  }
#endif

  private func cancelTaskTimeline(taskId: String, completion: (() -> Void)? = nil) {
    UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
      guard let self = self else { return }
      let prefix = "\(self.taskTimerNotificationPrefix).\(taskId)."
      let identifiers = requests
        .map { $0.identifier }
        .filter { $0.hasPrefix(prefix) }
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
      self.cancelAlarmKitTimeline(taskId: taskId)
      DispatchQueue.main.async {
        completion?()
      }
    }
  }

  private func cancelAlarmKitTimeline(taskId: String) {
#if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
      let key = taskTimerAlarmIdsKey(taskId)
      let alarmIdStrings = UserDefaults.standard.stringArray(forKey: key) ?? []
      for alarmIdString in alarmIdStrings {
        guard let alarmId = UUID(uuidString: alarmIdString) else {
          continue
        }
        try? AlarmManager.shared.cancel(id: alarmId)
      }
      UserDefaults.standard.removeObject(forKey: key)
    }
#endif
  }

  private func taskTimerNotificationIdentifier(taskId: String, phaseIndex: Int) -> String {
    "\(taskTimerNotificationPrefix).\(taskId).\(phaseIndex)"
  }

  private func taskTimerAlarmIdsKey(_ taskId: String) -> String {
    "\(taskTimerAlarmIdsKeyPrefix).\(taskId)"
  }

  private func taskTimerPayload(
    taskId: String,
    sectionId: String?,
    nextTaskId: String?,
    phaseIndex: Int,
    payloadType: String
  ) -> [String: Any] {
    [
      "source": "taskTimer",
      "type": payloadType,
      "taskId": taskId,
      "nextTaskId": nextTaskId as Any,
      "sectionId": sectionId as Any,
      "phaseIndex": phaseIndex,
    ]
  }

  private func forwardTaskTimerPayload(_ payload: [String: Any]) {
    if let channel = taskTimerChannel {
      channel.invokeMethod("taskTimerPayload", arguments: payload)
      return
    }
    pendingTaskTimerPayload = payload
  }

  private func flushPendingTaskTimerPayload() {
    guard let payload = pendingTaskTimerPayload else {
      return
    }
    pendingTaskTimerPayload = nil
    forwardTaskTimerPayload(payload)
  }

  private func flushPendingTaskTimerControlEvents() {
    guard
      let channel = taskTimerChannel,
      let defaults = UserDefaults(suiteName: taskTimerAppGroupIdentifier),
      let events = defaults.array(forKey: taskTimerControlEventsKey) as? [[String: Any]],
      !events.isEmpty
    else {
      return
    }

    defaults.removeObject(forKey: taskTimerControlEventsKey)
    channel.invokeMethod("taskTimerControlEvents", arguments: events)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    if userInfo["source"] as? String == "taskTimer" {
      var payload: [String: Any] = [:]
      for (key, value) in userInfo {
        if let key = key as? String {
          payload[key] = value
        }
      }
      forwardTaskTimerPayload(payload)
      completionHandler()
      return
    }

    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }

  private func presentCalendarEditor(
    title: String,
    details: String,
    startDate: Date,
    endDate: Date,
    result: @escaping FlutterResult
  ) {
    if pendingCalendarResult != nil {
      result(FlutterError(code: "BUSY", message: "Calendar editor already open", details: nil))
      return
    }

    pendingCalendarResult = result

    requestEventAccess { [weak self] granted in
      guard let self = self else { return }

      guard granted else {
        self.completeCalendarResult(value: "canceled")
        return
      }

      DispatchQueue.main.async {
        guard let presenter = self.window?.rootViewController else {
          self.completeCalendarResult(value: "canceled")
          return
        }

        let event = EKEvent(eventStore: self.eventStore)
        event.title = title
        event.notes = details
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = self.eventStore.defaultCalendarForNewEvents

        let editor = EKEventEditViewController()
        editor.eventStore = self.eventStore
        editor.event = event
        editor.editViewDelegate = self
        presenter.present(editor, animated: true)
      }
    }
  }

  private func requestEventAccess(completion: @escaping (Bool) -> Void) {
    if #available(iOS 17.0, *) {
      eventStore.requestFullAccessToEvents { granted, _ in
        completion(granted)
      }
      return
    }

    eventStore.requestAccess(to: .event) { granted, _ in
      completion(granted)
    }
  }

  private func saveEvents(
    _ events: [[String: Any]],
    result: @escaping FlutterResult
  ) {
    requestEventAccess { [weak self] granted in
      guard let self = self else { return }
      guard granted else {
        DispatchQueue.main.async {
          result(0)
        }
        return
      }

      var savedCount = 0
      for eventData in events {
        guard
          let title = eventData["title"] as? String,
          let description = eventData["description"] as? String,
          let startMillis = eventData["startMillis"] as? NSNumber,
          let endMillis = eventData["endMillis"] as? NSNumber
        else {
          continue
        }

        let event = EKEvent(eventStore: self.eventStore)
        event.title = title
        event.notes = description
        event.startDate = Date(timeIntervalSince1970: startMillis.doubleValue / 1000.0)
        event.endDate = Date(timeIntervalSince1970: endMillis.doubleValue / 1000.0)
        event.calendar = self.eventStore.defaultCalendarForNewEvents

        do {
          try self.eventStore.save(event, span: .thisEvent, commit: false)
          savedCount += 1
        } catch {
          continue
        }
      }

      do {
        try self.eventStore.commit()
      } catch {
        // Ignore commit error; return saved count that was attempted.
      }

      DispatchQueue.main.async {
        result(savedCount)
      }
    }
  }

  func eventEditViewController(
    _ controller: EKEventEditViewController,
    didCompleteWith action: EKEventEditViewAction
  ) {
    controller.dismiss(animated: true)

    switch action {
    case .saved:
      completeCalendarResult(value: "saved")
    case .canceled, .deleted:
      completeCalendarResult(value: "canceled")
    @unknown default:
      completeCalendarResult(value: "canceled")
    }
  }

  private func completeCalendarResult(value: String) {
    DispatchQueue.main.async {
      self.pendingCalendarResult?(value)
      self.pendingCalendarResult = nil
    }
  }
}
