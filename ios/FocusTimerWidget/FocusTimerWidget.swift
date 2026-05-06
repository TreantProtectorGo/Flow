import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import UserNotifications
import WidgetKit

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

@available(iOS 26.0, *)
struct FocusTimerLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: AlarmAttributes<FocusTaskAlarmMetadata>.self) { context in
      FocusTimerLockScreenView(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          FocusTimerBrandView(iconSize: 18, font: .headline)
            .padding(.leading, FocusTimerStyle.expandedEdgeInset)
        }
        DynamicIslandExpandedRegion(.trailing) {
          FocusTimerProgressPill(progress: context.attributes.metadata?.pomodoroProgress)
            .padding(.trailing, FocusTimerStyle.expandedEdgeInset)
        }
        DynamicIslandExpandedRegion(.bottom) {
          FocusTimerExpandedIslandView(context: context)
        }
      } compactLeading: {
        FocusTimerGlyph(size: 14)
          .offset(x: -0.3, y: 1)
      } compactTrailing: {
        FocusTimerCountdownText(context: context, fallbackTitle: nil)
          .font(.caption.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(FocusTimerStyle.primary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .frame(width: 48, alignment: .trailing)
      } minimal: {
        FocusTimerGlyph(size: 16)
      }
      .keylineTint(FocusTimerStyle.primary)
    }
  }
}

@available(iOS 26.0, *)
private struct FocusTimerLockScreenView: View {
  let context: ActivityViewContext<AlarmAttributes<FocusTaskAlarmMetadata>>

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        FocusTimerBrandView(iconSize: 22, font: .headline)
        Spacer()
        FocusTimerProgressPill(progress: context.attributes.metadata?.pomodoroProgress)
      }

      FocusTimerCountdownText(context: context, fallbackTitle: "Focus")
        .font(.system(size: 34, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.primary)
        .lineLimit(1)
        .minimumScaleFactor(0.74)
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 14)
    .activityBackgroundTint(FocusTimerStyle.primary.opacity(0.16))
    .activitySystemActionForegroundColor(FocusTimerStyle.primary)
  }
}

@available(iOS 26.0, *)
private struct FocusTimerExpandedIslandView: View {
  let context: ActivityViewContext<AlarmAttributes<FocusTaskAlarmMetadata>>

  var body: some View {
    VStack(spacing: 10) {
      FocusTimerCountdownText(context: context, fallbackTitle: "Focus")
        .font(.system(size: 36, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .center)

      HStack(spacing: 10) {
        Spacer(minLength: 8)

        FocusTimerPrimaryControlButton(context: context)
      }
    }
    .padding(.top, 2)
    .padding(.horizontal, FocusTimerStyle.expandedEdgeInset)
  }
}

@available(iOS 26.0, *)
private struct FocusTimerCountdownText: View {
  let context: ActivityViewContext<AlarmAttributes<FocusTaskAlarmMetadata>>
  let fallbackTitle: String?

  @ViewBuilder
  var body: some View {
    if let pausedRemainingText {
      Text(pausedRemainingText)
    } else if let timerInterval {
      Text(timerInterval: timerInterval, countsDown: true, showsHours: false)
    } else if let fallbackTitle {
      Text(fallbackTitle)
    } else {
      EmptyView()
    }
  }

  private var timerInterval: ClosedRange<Date>? {
    switch context.state.mode {
    case .countdown(let countdown):
      return countdown.startDate...countdown.focusTimerEndDate
    case .alert(let alert):
      guard let fireDate = Calendar.current.nextDate(
        after: Date(),
        matching: DateComponents(hour: alert.time.hour, minute: alert.time.minute),
        matchingPolicy: .nextTime
      ) else {
        return nil
      }
      return Date()...fireDate
    case .paused:
      return nil
    @unknown default:
      return nil
    }
  }

  private var pausedRemainingText: String? {
    guard case .paused(let paused) = context.state.mode else {
      return nil
    }
    let remainingSeconds = max(
      0,
      Int(ceil(paused.totalCountdownDuration - paused.previouslyElapsedDuration))
    )
    return Self.formatDuration(seconds: remainingSeconds)
  }

  private static func formatDuration(seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let seconds = seconds % 60
    if hours > 0 {
      return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
    }
    return "\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
  }
}

private struct FocusTimerBrandView: View {
  let iconSize: CGFloat
  let font: Font

  var body: some View {
    HStack(spacing: 7) {
      FocusTimerGlyph(size: iconSize)
      Text("Flow")
        .font(font)
        .fontWeight(.semibold)
        .lineLimit(1)
    }
  }
}

private struct FocusTimerProgressPill: View {
  let progress: String?

  var body: some View {
    if let progress, !progress.isEmpty {
      Text(progress)
        .font(.caption.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(FocusTimerStyle.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(FocusTimerStyle.primary.opacity(0.16), in: Capsule())
    }
  }
}

@available(iOS 26.0, *)
private struct FocusTimerPrimaryControlButton: View {
  let context: ActivityViewContext<AlarmAttributes<FocusTaskAlarmMetadata>>

  var body: some View {
    if isPaused {
      Button(
        intent: FocusTimerResumeIntent(
          alarmId: context.attributes.metadata?.alarmId ?? "",
          taskId: context.attributes.metadata?.taskId ?? "",
          fireDateMillis: context.fireDateMillis ?? 0
        )
      ) {
        FocusTimerControlIcon(systemName: "play.fill")
      }
      .buttonStyle(.plain)
    } else {
      Button(
        intent: FocusTimerPauseIntent(
          alarmId: context.attributes.metadata?.alarmId ?? "",
          taskId: context.attributes.metadata?.taskId ?? "",
          fireDateMillis: context.fireDateMillis ?? 0
        )
      ) {
        FocusTimerControlIcon(systemName: "pause.fill")
      }
      .buttonStyle(.plain)
    }
  }

  private var isPaused: Bool {
    if case .paused = context.state.mode {
      return true
    }
    return false
  }
}

private struct FocusTimerControlIcon: View {
  let systemName: String

  var body: some View {
    Image(systemName: systemName)
      .font(.caption.weight(.bold))
      .foregroundStyle(.black.opacity(0.86))
      .frame(width: 26, height: 26)
      .background(FocusTimerStyle.primary, in: Circle())
      .accessibilityHidden(true)
  }
}

@available(iOS 26.0, *)
private extension ActivityViewContext where Attributes == AlarmAttributes<FocusTaskAlarmMetadata> {
  var fireDateMillis: Double? {
    switch state.mode {
    case .countdown(let countdown):
      return countdown.focusTimerEndDate.timeIntervalSince1970 * 1000
    case .alert(let alert):
      return Calendar.current.nextDate(
        after: Date(),
        matching: DateComponents(hour: alert.time.hour, minute: alert.time.minute),
        matchingPolicy: .nextTime
      ).map { $0.timeIntervalSince1970 * 1000 }
    case .paused:
      return nil
    @unknown default:
      return nil
    }
  }
}

@available(iOS 26.0, *)
private extension AlarmPresentationState.Mode.Countdown {
  var focusTimerEndDate: Date {
    startDate.addingTimeInterval(
      max(0, totalCountdownDuration - previouslyElapsedDuration)
    )
  }
}

private struct FocusTimerGlyph: View {
  let size: CGFloat

  var body: some View {
    ZStack {
      Circle()
        .stroke(FocusTimerStyle.primary, lineWidth: max(1.5, size * 0.12))

      Rectangle()
        .fill(FocusTimerStyle.primary)
        .frame(width: max(1.2, size * 0.1), height: size * 0.34)
        .offset(y: -size * 0.12)

      Rectangle()
        .fill(FocusTimerStyle.primary)
        .frame(width: size * 0.26, height: max(1.2, size * 0.1))
        .offset(x: size * 0.1)

      Capsule()
        .fill(FocusTimerStyle.primary)
        .frame(width: size * 0.38, height: max(1.5, size * 0.12))
        .offset(y: -size * 0.58)
    }
    .frame(width: size, height: size)
    .accessibilityLabel(Text("Focus timer"))
  }
}

private enum FocusTimerStyle {
  static let primary = Color(red: 0.67, green: 0.78, blue: 1.0)
  static let expandedEdgeInset: CGFloat = 8
}

private enum FocusTimerSystemNotifications {
  static let notificationPrefix = "focus.taskTimer"

  static func cancelPendingNotifications(taskId: String) async {
    guard !taskId.isEmpty else {
      return
    }

    let identifiers = await withCheckedContinuation { continuation in
      UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
        let prefix = "\(notificationPrefix).\(taskId)."
        continuation.resume(
          returning: requests
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        )
      }
    }

    UNUserNotificationCenter.current().removePendingNotificationRequests(
      withIdentifiers: identifiers
    )
  }
}

private enum FocusTimerSharedControlEvents {
  static let appGroupIdentifier = "group.com.shape.focus"
  static let eventsKey = "focus.taskTimer.controlEvents"

  static func append(
    action: String,
    taskId: String,
    alarmId: String,
    fireDateMillis: Double
  ) {
    guard
      !taskId.isEmpty,
      let defaults = UserDefaults(suiteName: appGroupIdentifier)
    else {
      return
    }

    let now = Date()
    let remainingSeconds = fireDateMillis > 0
      ? max(0, Int(ceil((fireDateMillis / 1000) - now.timeIntervalSince1970)))
      : nil
    var events = defaults.array(forKey: eventsKey) as? [[String: Any]] ?? []
    var event: [String: Any] = [
      "action": action,
      "taskId": taskId,
      "alarmId": alarmId,
      "occurredAt": now.timeIntervalSince1970 * 1000,
    ]
    if let remainingSeconds {
      event["remainingSeconds"] = remainingSeconds
    }
    events.append(event)
    defaults.set(events, forKey: eventsKey)
  }
}

@available(iOS 26.0, *)
struct FocusTimerPauseIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Pause timer"

  @Parameter(title: "Alarm ID")
  var alarmId: String
  @Parameter(title: "Task ID")
  var taskId: String
  @Parameter(title: "Fire Date")
  var fireDateMillis: Double

  init() {
    alarmId = ""
    taskId = ""
    fireDateMillis = 0
  }

  init(alarmId: String, taskId: String, fireDateMillis: Double) {
    self.alarmId = alarmId
    self.taskId = taskId
    self.fireDateMillis = fireDateMillis
  }

  func perform() async throws -> some IntentResult {
    guard let id = UUID(uuidString: alarmId) else {
      return .result()
    }
    try AlarmManager.shared.pause(id: id)
    FocusTimerSharedControlEvents.append(
      action: "pause",
      taskId: taskId,
      alarmId: alarmId,
      fireDateMillis: fireDateMillis
    )
    await FocusTimerSystemNotifications.cancelPendingNotifications(taskId: taskId)
    return .result()
  }
}

@available(iOS 26.0, *)
struct FocusTimerResumeIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Resume timer"

  @Parameter(title: "Alarm ID")
  var alarmId: String
  @Parameter(title: "Task ID")
  var taskId: String
  @Parameter(title: "Fire Date")
  var fireDateMillis: Double

  init() {
    alarmId = ""
    taskId = ""
    fireDateMillis = 0
  }

  init(alarmId: String, taskId: String, fireDateMillis: Double) {
    self.alarmId = alarmId
    self.taskId = taskId
    self.fireDateMillis = fireDateMillis
  }

  func perform() async throws -> some IntentResult {
    guard let id = UUID(uuidString: alarmId) else {
      return .result()
    }
    try AlarmManager.shared.resume(id: id)
    FocusTimerSharedControlEvents.append(
      action: "resume",
      taskId: taskId,
      alarmId: alarmId,
      fireDateMillis: fireDateMillis
    )
    return .result()
  }
}

@available(iOS 26.0, *)
struct FocusTimerStopIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Stop timer"

  @Parameter(title: "Alarm ID")
  var alarmId: String
  @Parameter(title: "Task ID")
  var taskId: String

  init() {
    alarmId = ""
    taskId = ""
  }

  init(alarmId: String, taskId: String) {
    self.alarmId = alarmId
    self.taskId = taskId
  }

  func perform() async throws -> some IntentResult {
    guard let id = UUID(uuidString: alarmId) else {
      return .result()
    }
    try AlarmManager.shared.stop(id: id)
    await FocusTimerSystemNotifications.cancelPendingNotifications(taskId: taskId)
    return .result()
  }
}

@main
@available(iOS 26.0, *)
struct FocusTimerWidgetBundle: WidgetBundle {
  var body: some Widget {
    FocusTimerLiveActivityWidget()
  }
}
