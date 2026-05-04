import ActivityKit
import AlarmKit
import SwiftUI
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
}

@available(iOS 26.0, *)
struct FocusTimerLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: AlarmAttributes<FocusTaskAlarmMetadata>.self) { context in
      FocusTimerLockScreenView(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 6) {
            FocusTimerGlyph(size: 18)
            Text("Flow")
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          if let progress = context.attributes.metadata?.pomodoroProgress, !progress.isEmpty {
            Text(progress)
              .monospacedDigit()
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          FocusTimerCountdownText(context: context, fallbackTitle: "Focus")
        }
      } compactLeading: {
        FocusTimerGlyph(size: 18)
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
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        HStack(spacing: 8) {
          FocusTimerGlyph(size: 22)
          Text("Flow")
            .font(.headline)
        }
        Spacer()
        if let progress = context.attributes.metadata?.pomodoroProgress, !progress.isEmpty {
          Text(progress)
            .font(.headline)
            .monospacedDigit()
        }
      }

      Text(context.attributes.metadata?.taskTitle ?? "")
        .font(.subheadline)
        .lineLimit(1)

      FocusTimerCountdownText(context: context, fallbackTitle: "Focus")
        .font(.title2)
        .monospacedDigit()
    }
    .padding()
    .activityBackgroundTint(FocusTimerStyle.primary.opacity(0.16))
    .activitySystemActionForegroundColor(FocusTimerStyle.primary)
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
}

@main
@available(iOS 26.0, *)
struct FocusTimerWidgetBundle: WidgetBundle {
  var body: some Widget {
    FocusTimerLiveActivityWidget()
  }
}
