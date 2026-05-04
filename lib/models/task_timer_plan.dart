import 'dart:math' as math;

import 'task.dart';

enum TaskTimerPhaseKind { focus, shortBreak, longBreak }

enum TaskTimerPayloadType {
  phaseStart,
  phaseEnd,
  taskComplete,
  nextTaskPrompt,
  standaloneTimerComplete,
}

class TaskTimerPhase {
  final int phaseIndex;
  final TaskTimerPhaseKind kind;
  final int pomodoroIndex;
  final DateTime startAt;
  final DateTime endAt;
  final int completedPomodorosAtEnd;
  final int totalPomodoros;
  final String alertTitle;
  final String alertBody;
  final TaskTimerPayloadType payloadType;

  const TaskTimerPhase({
    required this.phaseIndex,
    required this.kind,
    required this.pomodoroIndex,
    required this.startAt,
    required this.endAt,
    required this.completedPomodorosAtEnd,
    required this.totalPomodoros,
    required this.alertTitle,
    required this.alertBody,
    required this.payloadType,
  });

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'phaseIndex': phaseIndex,
      'kind': kind.name,
      'pomodoroIndex': pomodoroIndex,
      'startAt': startAt.millisecondsSinceEpoch,
      'endAt': endAt.millisecondsSinceEpoch,
      'completedPomodorosAtEnd': completedPomodorosAtEnd,
      'totalPomodoros': totalPomodoros,
      'alertTitle': alertTitle,
      'alertBody': alertBody,
      'payloadType': payloadType.name,
    };
  }
}

class TaskTimerPlan {
  final String taskId;
  final String taskTitle;
  final String? sectionId;
  final String? nextTaskId;
  final String? nextTaskTitle;
  final DateTime startAt;
  final List<TaskTimerPhase> phases;

  const TaskTimerPlan({
    required this.taskId,
    required this.taskTitle,
    required this.sectionId,
    required this.nextTaskId,
    required this.nextTaskTitle,
    required this.startAt,
    required this.phases,
  });

  DateTime get endsAt => phases.last.endAt;

  static TaskTimerPlan create({
    required Task task,
    required DateTime startAt,
    required int focusMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    required int longBreakFrequency,
    String? nextTaskId,
    String? nextTaskTitle,
    int? firstFocusSeconds,
  }) {
    final int totalPomodoros = math.max(1, task.pomodoroCount);
    final int completedPomodoros = task.completedPomodoros.clamp(
      0,
      totalPomodoros,
    );
    final int remainingPomodoros = math.max(
      0,
      totalPomodoros - completedPomodoros,
    );
    final int normalizedLongBreakFrequency = longBreakFrequency <= 0
        ? 4
        : longBreakFrequency;
    final List<TaskTimerPhase> phases = <TaskTimerPhase>[];
    DateTime cursor = startAt;

    for (int offset = 0; offset < remainingPomodoros; offset++) {
      final int pomodoroIndex = completedPomodoros + offset + 1;
      final int focusSeconds = offset == 0 && firstFocusSeconds != null
          ? math.max(1, firstFocusSeconds)
          : math.max(1, focusMinutes * 60);
      final DateTime focusEnd = cursor.add(Duration(seconds: focusSeconds));
      final bool isFinalFocus = pomodoroIndex >= totalPomodoros;
      final TaskTimerPayloadType focusPayloadType = isFinalFocus
          ? (nextTaskId == null
                ? TaskTimerPayloadType.taskComplete
                : TaskTimerPayloadType.nextTaskPrompt)
          : TaskTimerPayloadType.phaseEnd;

      phases.add(
        TaskTimerPhase(
          phaseIndex: phases.length,
          kind: TaskTimerPhaseKind.focus,
          pomodoroIndex: pomodoroIndex,
          startAt: cursor,
          endAt: focusEnd,
          completedPomodorosAtEnd: pomodoroIndex,
          totalPomodoros: totalPomodoros,
          alertTitle: '',
          alertBody: '',
          payloadType: focusPayloadType,
        ),
      );
      cursor = focusEnd;

      if (isFinalFocus) {
        break;
      }

      final bool shouldUseLongBreak =
          pomodoroIndex > 0 &&
          pomodoroIndex % normalizedLongBreakFrequency == 0;
      final TaskTimerPhaseKind breakKind = shouldUseLongBreak
          ? TaskTimerPhaseKind.longBreak
          : TaskTimerPhaseKind.shortBreak;
      final int breakMinutes = shouldUseLongBreak
          ? longBreakMinutes
          : shortBreakMinutes;
      final DateTime breakEnd = cursor.add(
        Duration(seconds: math.max(1, breakMinutes * 60)),
      );

      phases.add(
        TaskTimerPhase(
          phaseIndex: phases.length,
          kind: breakKind,
          pomodoroIndex: pomodoroIndex,
          startAt: cursor,
          endAt: breakEnd,
          completedPomodorosAtEnd: pomodoroIndex,
          totalPomodoros: totalPomodoros,
          alertTitle: '',
          alertBody: '',
          payloadType: TaskTimerPayloadType.phaseStart,
        ),
      );
      cursor = breakEnd;
    }

    return TaskTimerPlan(
      taskId: task.id,
      taskTitle: task.title,
      sectionId: task.aiSessionId,
      nextTaskId: nextTaskId,
      nextTaskTitle: nextTaskTitle,
      startAt: startAt,
      phases: phases,
    );
  }

  static TaskTimerPlan createStandalone({
    required String id,
    required String title,
    required DateTime startAt,
    required int focusMinutes,
    required int shortBreakMinutes,
    int? firstFocusSeconds,
  }) {
    final int focusSeconds = firstFocusSeconds != null
        ? math.max(1, firstFocusSeconds)
        : math.max(1, focusMinutes * 60);
    final DateTime focusEnd = startAt.add(Duration(seconds: focusSeconds));
    final DateTime breakEnd = focusEnd.add(
      Duration(seconds: math.max(1, shortBreakMinutes * 60)),
    );

    return TaskTimerPlan(
      taskId: id,
      taskTitle: title,
      sectionId: null,
      nextTaskId: null,
      nextTaskTitle: null,
      startAt: startAt,
      phases: <TaskTimerPhase>[
        TaskTimerPhase(
          phaseIndex: 0,
          kind: TaskTimerPhaseKind.focus,
          pomodoroIndex: 1,
          startAt: startAt,
          endAt: focusEnd,
          completedPomodorosAtEnd: 1,
          totalPomodoros: 1,
          alertTitle: '',
          alertBody: '',
          payloadType: TaskTimerPayloadType.phaseEnd,
        ),
        TaskTimerPhase(
          phaseIndex: 1,
          kind: TaskTimerPhaseKind.shortBreak,
          pomodoroIndex: 1,
          startAt: focusEnd,
          endAt: breakEnd,
          completedPomodorosAtEnd: 1,
          totalPomodoros: 1,
          alertTitle: '',
          alertBody: '',
          payloadType: TaskTimerPayloadType.standaloneTimerComplete,
        ),
      ],
    );
  }

  TaskTimerPlan withAlertText(
    String Function(TaskTimerPhase phase) titleBuilder,
    String Function(TaskTimerPhase phase) bodyBuilder,
  ) {
    return TaskTimerPlan(
      taskId: taskId,
      taskTitle: taskTitle,
      sectionId: sectionId,
      nextTaskId: nextTaskId,
      nextTaskTitle: nextTaskTitle,
      startAt: startAt,
      phases: phases
          .map(
            (TaskTimerPhase phase) => TaskTimerPhase(
              phaseIndex: phase.phaseIndex,
              kind: phase.kind,
              pomodoroIndex: phase.pomodoroIndex,
              startAt: phase.startAt,
              endAt: phase.endAt,
              completedPomodorosAtEnd: phase.completedPomodorosAtEnd,
              totalPomodoros: phase.totalPomodoros,
              alertTitle: titleBuilder(phase),
              alertBody: bodyBuilder(phase),
              payloadType: phase.payloadType,
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'taskId': taskId,
      'taskTitle': taskTitle,
      'sectionId': sectionId,
      'nextTaskId': nextTaskId,
      'nextTaskTitle': nextTaskTitle,
      'startAt': startAt.millisecondsSinceEpoch,
      'endsAt': endsAt.millisecondsSinceEpoch,
      'phases': phases
          .map((TaskTimerPhase phase) => phase.toJson())
          .toList(growable: false),
    };
  }
}
