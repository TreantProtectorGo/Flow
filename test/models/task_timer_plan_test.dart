import 'package:flutter_test/flutter_test.dart';
import 'package:focus/models/task.dart';
import 'package:focus/models/task_timer_plan.dart';

void main() {
  group('TaskTimerPlan', () {
    test('generates exact phase timeline for four pomodoros', () {
      final task = Task(
        id: 'task-1',
        title: 'Write report',
        pomodoroCount: 4,
        completedPomodoros: 0,
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        createdAt: DateTime(2026, 4, 19, 9, 0),
        aiSessionId: 'section-1',
      );
      final startAt = DateTime(2026, 4, 19, 10, 0);

      final plan = TaskTimerPlan.create(
        task: task,
        startAt: startAt,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakFrequency: 4,
        nextTaskId: 'task-2',
      );

      expect(plan.taskId, 'task-1');
      expect(plan.sectionId, 'section-1');
      expect(plan.nextTaskId, 'task-2');
      expect(plan.phases.map((phase) => phase.kind), <TaskTimerPhaseKind>[
        TaskTimerPhaseKind.focus,
        TaskTimerPhaseKind.shortBreak,
        TaskTimerPhaseKind.focus,
        TaskTimerPhaseKind.shortBreak,
        TaskTimerPhaseKind.focus,
        TaskTimerPhaseKind.shortBreak,
        TaskTimerPhaseKind.focus,
      ]);
      expect(plan.phases.map((phase) => phase.endAt).toList(), <DateTime>[
        DateTime(2026, 4, 19, 10, 25),
        DateTime(2026, 4, 19, 10, 30),
        DateTime(2026, 4, 19, 10, 55),
        DateTime(2026, 4, 19, 11, 0),
        DateTime(2026, 4, 19, 11, 25),
        DateTime(2026, 4, 19, 11, 30),
        DateTime(2026, 4, 19, 11, 55),
      ]);
      expect(plan.endsAt, DateTime(2026, 4, 19, 11, 55));
    });

    test('uses a long break between pomodoros when frequency is reached', () {
      final task = Task(
        id: 'task-1',
        title: 'Study',
        pomodoroCount: 3,
        completedPomodoros: 0,
        priority: TaskPriority.medium,
        status: TaskStatus.inProgress,
        createdAt: DateTime(2026, 4, 19, 9, 0),
      );

      final plan = TaskTimerPlan.create(
        task: task,
        startAt: DateTime(2026, 4, 19, 14, 0),
        focusMinutes: 20,
        shortBreakMinutes: 3,
        longBreakMinutes: 10,
        longBreakFrequency: 2,
      );

      expect(plan.phases.map((phase) => phase.kind), <TaskTimerPhaseKind>[
        TaskTimerPhaseKind.focus,
        TaskTimerPhaseKind.shortBreak,
        TaskTimerPhaseKind.focus,
        TaskTimerPhaseKind.longBreak,
        TaskTimerPhaseKind.focus,
      ]);
      expect(plan.endsAt, DateTime(2026, 4, 19, 15, 13));
    });

    test('generates standalone focus then short break timeline', () {
      final DateTime startAt = DateTime(2026, 4, 20, 23, 2);

      final TaskTimerPlan plan = TaskTimerPlan.createStandalone(
        id: 'standalone:123',
        title: 'Pomodoro',
        startAt: startAt,
        focusMinutes: 25,
        shortBreakMinutes: 5,
      );

      expect(plan.taskId, 'standalone:123');
      expect(plan.nextTaskId, isNull);
      expect(
        plan.phases.map((TaskTimerPhase phase) => phase.kind),
        <TaskTimerPhaseKind>[
          TaskTimerPhaseKind.focus,
          TaskTimerPhaseKind.shortBreak,
        ],
      );
      expect(
        plan.phases.map((TaskTimerPhase phase) => phase.payloadType),
        <TaskTimerPayloadType>[
          TaskTimerPayloadType.phaseEnd,
          TaskTimerPayloadType.standaloneTimerComplete,
        ],
      );
      expect(plan.phases.map((TaskTimerPhase phase) => phase.endAt), <DateTime>[
        DateTime(2026, 4, 20, 23, 27),
        DateTime(2026, 4, 20, 23, 32),
      ]);
    });
  });
}
