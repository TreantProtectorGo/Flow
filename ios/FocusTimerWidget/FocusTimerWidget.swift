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
          .offset(y: 1.5)
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
    if let fireDate {
      Text(timerInterval: Date()...fireDate, countsDown: true)
    } else if let fallbackTitle {
      Text(fallbackTitle)
    } else {
      EmptyView()
    }
  }

  private var fireDate: Date? {
    switch context.state.mode {
    case .countdown(let countdown):
      return countdown.fireDate
    case .alert(let alert):
      return Calendar.current.nextDate(
        after: Date(),
        matching: DateComponents(hour: alert.time.hour, minute: alert.time.minute),
        matchingPolicy: .nextTime
      )
    case .paused:
      return nil
    @unknown default:
      return nil
    }
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
          taskId: context.attributes.metadata?.taskId ?? ""
        )
      ) {
        FocusTimerControlIcon(systemName: "play.fill")
      }
      .buttonStyle(.plain)
    } else {
      Button(
        intent: FocusTimerPauseIntent(
          alarmId: context.attributes.metadata?.alarmId ?? "",
          taskId: context.attributes.metadata?.taskId ?? ""
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

@available(iOS 26.0, *)
struct FocusTimerPauseIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Pause timer"

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
    try AlarmManager.shared.pause(id: id)
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
    try AlarmManager.shared.resume(id: id)
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
