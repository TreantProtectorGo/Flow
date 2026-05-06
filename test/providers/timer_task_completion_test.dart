import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/models/task.dart';
import 'package:focus/providers/statistics_provider.dart';
import 'package:focus/providers/task_completion_event_provider.dart';
import 'package:focus/providers/task_provider.dart';
import 'package:focus/providers/timer_provider.dart';
import 'package:focus/services/focus_repository.dart';
import 'package:focus/services/notification_client.dart';
import 'package:focus/services/task_timer_system_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFocusRepository implements FocusRepository {
  final List<Task> tasks;
  final List<String?> insertedPomodoroTaskIds = <String?>[];
  int insertedPomodoroSessions = 0;

  _FakeFocusRepository({required this.tasks});

  @override
  Future<void> clearAllData() async {
    tasks.clear();
  }

  @override
  Future<List<Task>> getAllTasks() async {
    return List<Task>.from(tasks);
  }

  @override
  Future<void> insertPomodoroSession({
    String? taskId,
    required DateTime startTime,
    DateTime? endTime,
    required int duration,
    required bool completed,
    required String sessionType,
  }) async {
    insertedPomodoroSessions += 1;
    insertedPomodoroTaskIds.add(taskId);
  }

  @override
  Future<void> insertTask(Task task) async {
    tasks.add(task);
  }

  @override
  Future<void> softDeleteTask(String id) async {}

  @override
  Future<void> updateTask(Task task) async {
    final int index = tasks.indexWhere((Task item) => item.id == task.id);
    if (index != -1) {
      tasks[index] = task;
    }
  }
}

class _FakeNotificationClient implements NotificationClient {
  final List<String> canceledTaskIds = <String>[];
  int breakCompleteNotifications = 0;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelAllTaskReminders() async {}

  @override
  Future<void> cancelTaskReminder(String taskId) async {
    canceledTaskIds.add(taskId);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> reconcileTaskReminders({
    required Iterable<Task> tasks,
    required bool notificationsEnabled,
    required String title,
    required String Function(Task task) bodyBuilder,
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<void> scheduleDailyTaskReminder({
    required Task task,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<void> showBreakCompleteNotification({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    breakCompleteNotifications += 1;
  }

  @override
  Future<void> showFocusCompleteNotification({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<void> showTaskCompleteNotification({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {}
}

class _FakeTaskTimerSystemScheduler implements TaskTimerSystemScheduler {
  final List<TaskTimerPlan> scheduledPlans = <TaskTimerPlan>[];
  final List<String> canceledTaskIds = <String>[];
  final List<String> operations = <String>[];
  Completer<void>? cancelCompleter;

  @override
  Future<void> cancelTaskTimeline(String taskId) async {
    operations.add('cancel:$taskId');
    canceledTaskIds.add(taskId);
    await cancelCompleter?.future;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> rescheduleTaskTimeline(TaskTimerPlan plan) async {
    operations.add('reschedule:${plan.taskId}');
    scheduledPlans.add(plan);
  }

  @override
  Future<void> scheduleTaskTimeline(TaskTimerPlan plan) async {
    operations.add('schedule:${plan.taskId}');
    scheduledPlans.add(plan);
  }
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeStatisticsNotifier extends StatisticsNotifier {
  @override
  Future<void> loadStatistics() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'final pomodoro completion cancels reminder and emits celebration event',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'currentTaskId': 'task-1',
      });
      final _FakeFocusRepository repository = _FakeFocusRepository(
        tasks: <Task>[
          Task(
            id: 'task-1',
            title: 'Close sprint',
            pomodoroCount: 1,
            completedPomodoros: 0,
            priority: TaskPriority.high,
            status: TaskStatus.inProgress,
            createdAt: DateTime(2026, 3, 31, 9, 0),
            dailyReminderTime: '20:00',
          ),
        ],
      );
      final _FakeNotificationClient notifications = _FakeNotificationClient();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          focusRepositoryProvider.overrideWithValue(repository),
          notificationClientProvider.overrideWithValue(notifications),
          statisticsProvider.overrideWith(
            (Ref ref) => _FakeStatisticsNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskProvider.notifier).reloadTasks();
      await _flushMicrotasks();
      container.read(timerProvider.notifier).startTimer();
      container.read(timerProvider.notifier).skipTimer();
      await _flushMicrotasks();

      final Task completedTask = container
          .read(taskProvider)
          .completedTasks
          .single;
      final TaskCompletionEvent? event = container.read(
        taskCompletionEventProvider,
      );

      expect(repository.insertedPomodoroSessions, equals(1));
      expect(completedTask.status, equals(TaskStatus.completed));
      expect(notifications.canceledTaskIds, contains('task-1'));
      expect(event?.taskTitle, equals('Close sprint'));
    },
  );

  test('completion event includes next task in the same AI section', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final DateTime createdAt = DateTime(2026, 4, 19, 9, 0);
    final _FakeFocusRepository repository = _FakeFocusRepository(
      tasks: <Task>[
        Task(
          id: 'task-1',
          title: 'Outline',
          pomodoroCount: 1,
          completedPomodoros: 0,
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
          createdAt: createdAt.add(const Duration(seconds: 2)),
          isAIGenerated: true,
          aiSessionId: 'section-1',
        ),
        Task(
          id: 'task-2',
          title: 'Draft',
          pomodoroCount: 1,
          completedPomodoros: 0,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: createdAt.add(const Duration(seconds: 1)),
          isAIGenerated: true,
          aiSessionId: 'section-1',
        ),
        Task(
          id: 'task-3',
          title: 'Other section',
          pomodoroCount: 1,
          completedPomodoros: 0,
          priority: TaskPriority.low,
          status: TaskStatus.pending,
          createdAt: createdAt,
          isAIGenerated: true,
          aiSessionId: 'section-2',
        ),
      ],
    );
    final _FakeNotificationClient notifications = _FakeNotificationClient();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        focusRepositoryProvider.overrideWithValue(repository),
        notificationClientProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);

    await container.read(taskProvider.notifier).reloadTasks();
    await _flushMicrotasks();
    await container.read(taskProvider.notifier).markTaskAsCompleted('task-1');
    final TaskCompletionEvent? event = container.read(
      taskCompletionEventProvider,
    );

    expect(event?.taskId, equals('task-1'));
    expect(event?.nextTaskId, equals('task-2'));
    expect(event?.nextTaskTitle, equals('Draft'));
  });

  test('starting timer schedules the full current task timeline', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'currentTaskId': 'task-1',
    });
    final _FakeFocusRepository repository = _FakeFocusRepository(
      tasks: <Task>[
        Task(
          id: 'task-1',
          title: 'Build feature',
          pomodoroCount: 2,
          completedPomodoros: 0,
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
          createdAt: DateTime(2026, 4, 19, 9, 1),
          isAIGenerated: true,
          aiSessionId: 'section-1',
        ),
        Task(
          id: 'task-2',
          title: 'Write tests',
          pomodoroCount: 1,
          completedPomodoros: 0,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime(2026, 4, 19, 9, 0),
          isAIGenerated: true,
          aiSessionId: 'section-1',
        ),
      ],
    );
    final _FakeTaskTimerSystemScheduler systemScheduler =
        _FakeTaskTimerSystemScheduler();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        focusRepositoryProvider.overrideWithValue(repository),
        notificationClientProvider.overrideWithValue(_FakeNotificationClient()),
        taskTimerSystemSchedulerProvider.overrideWithValue(systemScheduler),
        statisticsProvider.overrideWith((Ref ref) => _FakeStatisticsNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(taskProvider.notifier).reloadTasks();
    await _flushMicrotasks();
    container.read(timerProvider.notifier).startTimer();
    await _flushMicrotasks();

    expect(systemScheduler.scheduledPlans, hasLength(1));
    expect(systemScheduler.scheduledPlans.single.taskId, 'task-1');
    expect(systemScheduler.scheduledPlans.single.nextTaskId, 'task-2');
    expect(systemScheduler.scheduledPlans.single.phases, hasLength(3));
  });

  test(
    'starting timer without a task schedules one focus and short break',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final _FakeFocusRepository repository = _FakeFocusRepository(
        tasks: <Task>[],
      );
      final _FakeTaskTimerSystemScheduler systemScheduler =
          _FakeTaskTimerSystemScheduler();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          focusRepositoryProvider.overrideWithValue(repository),
          notificationClientProvider.overrideWithValue(
            _FakeNotificationClient(),
          ),
          taskTimerSystemSchedulerProvider.overrideWithValue(systemScheduler),
          statisticsProvider.overrideWith(
            (Ref ref) => _FakeStatisticsNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskProvider.notifier).reloadTasks();
      await _flushMicrotasks();
      container.read(timerProvider.notifier).startTimer();
      await _flushMicrotasks();

      expect(systemScheduler.scheduledPlans, hasLength(1));
      final TaskTimerPlan plan = systemScheduler.scheduledPlans.single;
      expect(plan.taskId, startsWith('standalone:'));
      expect(plan.nextTaskId, isNull);
      expect(
        plan.phases.map((TaskTimerPhase phase) => phase.kind),
        <TaskTimerPhaseKind>[
          TaskTimerPhaseKind.focus,
          TaskTimerPhaseKind.shortBreak,
        ],
      );
    },
  );

  test(
    'running standalone timer syncs app time after wall-clock elapsed',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      DateTime fakeNow = DateTime(2026, 4, 20, 10, 0);
      final _FakeFocusRepository repository = _FakeFocusRepository(
        tasks: <Task>[],
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          focusRepositoryProvider.overrideWithValue(repository),
          notificationClientProvider.overrideWithValue(
            _FakeNotificationClient(),
          ),
          timerClockProvider.overrideWithValue(() => fakeNow),
          statisticsProvider.overrideWith(
            (Ref ref) => _FakeStatisticsNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskProvider.notifier).reloadTasks();
      await _flushMicrotasks();
      final TimerProvider timer = container.read(timerProvider.notifier);
      timer.startTimer();
      await _flushMicrotasks();

      fakeNow = fakeNow.add(const Duration(seconds: 90));
      await timer.syncTimerWithSystemClockForTesting();

      expect(timer.timeLeftInSeconds, 23 * 60 + 30);
    },
  );

  test('running task timer syncs app time after wall-clock elapsed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'currentTaskId': 'task-1',
    });
    DateTime fakeNow = DateTime(2026, 4, 20, 10, 0);
    final _FakeFocusRepository repository = _FakeFocusRepository(
      tasks: <Task>[
        Task(
          id: 'task-1',
          title: 'Build feature',
          pomodoroCount: 2,
          completedPomodoros: 0,
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
          createdAt: DateTime(2026, 4, 19, 9, 1),
        ),
      ],
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        focusRepositoryProvider.overrideWithValue(repository),
        notificationClientProvider.overrideWithValue(_FakeNotificationClient()),
        timerClockProvider.overrideWithValue(() => fakeNow),
        statisticsProvider.overrideWith((Ref ref) => _FakeStatisticsNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(taskProvider.notifier).reloadTasks();
    await _flushMicrotasks();
    final TimerProvider timer = container.read(timerProvider.notifier);
    timer.startTimer();
    await _flushMicrotasks();

    fakeNow = fakeNow.add(const Duration(seconds: 90));
    await timer.syncTimerWithSystemClockForTesting();

    expect(timer.timeLeftInSeconds, 23 * 60 + 30);
  });

  test('switching current task resets a running focus timer', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'currentTaskId': 'task-1',
    });
    DateTime fakeNow = DateTime(2026, 4, 20, 10, 0);
    final _FakeFocusRepository repository = _FakeFocusRepository(
      tasks: <Task>[
        Task(
          id: 'task-1',
          title: 'Build feature',
          pomodoroCount: 2,
          completedPomodoros: 0,
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
          createdAt: DateTime(2026, 4, 19, 9, 1),
        ),
        Task(
          id: 'task-2',
          title: 'Write tests',
          pomodoroCount: 1,
          completedPomodoros: 0,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime(2026, 4, 19, 9, 0),
        ),
      ],
    );
    final _FakeTaskTimerSystemScheduler systemScheduler =
        _FakeTaskTimerSystemScheduler();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        focusRepositoryProvider.overrideWithValue(repository),
        notificationClientProvider.overrideWithValue(_FakeNotificationClient()),
        taskTimerSystemSchedulerProvider.overrideWithValue(systemScheduler),
        timerClockProvider.overrideWithValue(() => fakeNow),
        statisticsProvider.overrideWith((Ref ref) => _FakeStatisticsNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(taskProvider.notifier).reloadTasks();
    await _flushMicrotasks();
    final TimerProvider timer = container.read(timerProvider.notifier);
    timer.startTimer();
    await _flushMicrotasks();

    fakeNow = fakeNow.add(const Duration(seconds: 90));
    await timer.syncTimerWithSystemClockForTesting();
    await container.read(taskProvider.notifier).setCurrentTask('task-2');
    await _flushMicrotasks();

    expect(timer.state, TimerState.stopped);
    expect(timer.mode, TimerMode.focus);
    expect(timer.timeLeftInSeconds, 25 * 60);
    expect(repository.insertedPomodoroSessions, equals(1));
    expect(repository.insertedPomodoroTaskIds, <String?>['task-1']);
    expect(systemScheduler.canceledTaskIds, contains('task-1'));
  });

  test(
    'resuming standalone timer reschedules the background timeline',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final _FakeFocusRepository repository = _FakeFocusRepository(
        tasks: <Task>[],
      );
      final _FakeTaskTimerSystemScheduler systemScheduler =
          _FakeTaskTimerSystemScheduler();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          focusRepositoryProvider.overrideWithValue(repository),
          notificationClientProvider.overrideWithValue(
            _FakeNotificationClient(),
          ),
          taskTimerSystemSchedulerProvider.overrideWithValue(systemScheduler),
          statisticsProvider.overrideWith(
            (Ref ref) => _FakeStatisticsNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskProvider.notifier).reloadTasks();
      await _flushMicrotasks();
      final TimerProvider timer = container.read(timerProvider.notifier);
      timer.startTimer();
      await _flushMicrotasks();
      await timer.pauseTimer();
      await _flushMicrotasks();
      timer.startTimer();
      await _flushMicrotasks();

      expect(systemScheduler.canceledTaskIds, hasLength(1));
      expect(systemScheduler.scheduledPlans, hasLength(2));
      expect(
        systemScheduler.scheduledPlans.first.taskId,
        startsWith('standalone:'),
      );
      expect(
        systemScheduler.scheduledPlans.last.taskId,
        startsWith('standalone:'),
      );
    },
  );

  test('resuming task timer reschedules the background timeline', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'currentTaskId': 'task-1',
    });
    final _FakeFocusRepository repository = _FakeFocusRepository(
      tasks: <Task>[
        Task(
          id: 'task-1',
          title: 'Build feature',
          pomodoroCount: 2,
          completedPomodoros: 0,
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
          createdAt: DateTime(2026, 4, 19, 9, 1),
        ),
      ],
    );
    final _FakeTaskTimerSystemScheduler systemScheduler =
        _FakeTaskTimerSystemScheduler();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        focusRepositoryProvider.overrideWithValue(repository),
        notificationClientProvider.overrideWithValue(_FakeNotificationClient()),
        taskTimerSystemSchedulerProvider.overrideWithValue(systemScheduler),
        statisticsProvider.overrideWith((Ref ref) => _FakeStatisticsNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(taskProvider.notifier).reloadTasks();
    await _flushMicrotasks();
    final TimerProvider timer = container.read(timerProvider.notifier);
    timer.startTimer();
    await _flushMicrotasks();
    await timer.pauseTimer();
    await _flushMicrotasks();
    timer.startTimer();
    await _flushMicrotasks();

    expect(systemScheduler.canceledTaskIds, <String>['task-1']);
    expect(systemScheduler.scheduledPlans, hasLength(2));
    expect(systemScheduler.scheduledPlans.first.taskId, 'task-1');
    expect(systemScheduler.scheduledPlans.last.taskId, 'task-1');
  });

  test(
    'stopping standalone timer allows a new background timeline on next start',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final _FakeFocusRepository repository = _FakeFocusRepository(
        tasks: <Task>[],
      );
      final _FakeTaskTimerSystemScheduler systemScheduler =
          _FakeTaskTimerSystemScheduler();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          focusRepositoryProvider.overrideWithValue(repository),
          notificationClientProvider.overrideWithValue(
            _FakeNotificationClient(),
          ),
          taskTimerSystemSchedulerProvider.overrideWithValue(systemScheduler),
          statisticsProvider.overrideWith(
            (Ref ref) => _FakeStatisticsNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskProvider.notifier).reloadTasks();
      await _flushMicrotasks();
      final TimerProvider timer = container.read(timerProvider.notifier);
      timer.startTimer();
      await _flushMicrotasks();
      await timer.stopTimer();
      await _flushMicrotasks();
      timer.startTimer();
      await _flushMicrotasks();

      expect(systemScheduler.canceledTaskIds, hasLength(1));
      expect(systemScheduler.scheduledPlans, hasLength(2));
      expect(
        systemScheduler.scheduledPlans.first.taskId,
        startsWith('standalone:'),
      );
      expect(
        systemScheduler.scheduledPlans.last.taskId,
        startsWith('standalone:'),
      );
    },
  );

  test('standalone timer stops after its short break completes', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _FakeFocusRepository repository = _FakeFocusRepository(
      tasks: <Task>[],
    );
    final _FakeNotificationClient notifications = _FakeNotificationClient();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        focusRepositoryProvider.overrideWithValue(repository),
        notificationClientProvider.overrideWithValue(notifications),
        statisticsProvider.overrideWith((Ref ref) => _FakeStatisticsNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(taskProvider.notifier).reloadTasks();
    await _flushMicrotasks();
    final TimerProvider timer = container.read(timerProvider.notifier);
    timer.startTimer();
    timer.skipTimer();
    await _flushMicrotasks();
    timer.skipTimer();
    await _flushMicrotasks();

    expect(timer.state, TimerState.stopped);
    expect(timer.mode, TimerMode.focus);
    expect(notifications.breakCompleteNotifications, 1);
  });

  test('skip waits for current system timeline cancellation', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'currentTaskId': 'task-1',
    });
    final _FakeFocusRepository repository = _FakeFocusRepository(
      tasks: <Task>[
        Task(
          id: 'task-1',
          title: 'Build feature',
          pomodoroCount: 2,
          completedPomodoros: 0,
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
          createdAt: DateTime(2026, 4, 19, 9, 1),
        ),
      ],
    );
    final _FakeTaskTimerSystemScheduler systemScheduler =
        _FakeTaskTimerSystemScheduler()..cancelCompleter = Completer<void>();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        focusRepositoryProvider.overrideWithValue(repository),
        notificationClientProvider.overrideWithValue(_FakeNotificationClient()),
        taskTimerSystemSchedulerProvider.overrideWithValue(systemScheduler),
        statisticsProvider.overrideWith((Ref ref) => _FakeStatisticsNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(taskProvider.notifier).reloadTasks();
    await _flushMicrotasks();
    final TimerProvider timer = container.read(timerProvider.notifier);
    timer.startTimer();
    await _flushMicrotasks();

    final Future<void> skip = timer.skipTimer();
    await _flushMicrotasks();

    expect(systemScheduler.canceledTaskIds, <String>['task-1']);
    expect(timer.state, TimerState.running);
    expect(timer.mode, TimerMode.focus);

    systemScheduler.cancelCompleter!.complete();
    await skip;
    await _flushMicrotasks();

    expect(timer.state, TimerState.running);
    expect(timer.mode, TimerMode.shortBreak);
  });

  test('pause waits for current system timeline cancellation', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'currentTaskId': 'task-1',
    });
    final _FakeFocusRepository repository = _FakeFocusRepository(
      tasks: <Task>[
        Task(
          id: 'task-1',
          title: 'Build feature',
          pomodoroCount: 2,
          completedPomodoros: 0,
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
          createdAt: DateTime(2026, 4, 19, 9, 1),
        ),
      ],
    );
    final _FakeTaskTimerSystemScheduler systemScheduler =
        _FakeTaskTimerSystemScheduler()..cancelCompleter = Completer<void>();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        focusRepositoryProvider.overrideWithValue(repository),
        notificationClientProvider.overrideWithValue(_FakeNotificationClient()),
        taskTimerSystemSchedulerProvider.overrideWithValue(systemScheduler),
        statisticsProvider.overrideWith((Ref ref) => _FakeStatisticsNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(taskProvider.notifier).reloadTasks();
    await _flushMicrotasks();
    final TimerProvider timer = container.read(timerProvider.notifier);
    timer.startTimer();
    await _flushMicrotasks();

    final Future<void> pause = timer.pauseTimer();
    await _flushMicrotasks();

    expect(timer.state, TimerState.paused);
    expect(systemScheduler.canceledTaskIds, <String>['task-1']);
    expect(systemScheduler.scheduledPlans, hasLength(1));

    systemScheduler.cancelCompleter!.complete();
    await pause;
    timer.startTimer();
    await _flushMicrotasks();

    expect(systemScheduler.scheduledPlans, hasLength(2));
    expect(systemScheduler.scheduledPlans.last.taskId, 'task-1');
  });

  test(
    'native pause event syncs task timer without canceling timeline',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'currentTaskId': 'task-1',
      });
      final _FakeFocusRepository repository = _FakeFocusRepository(
        tasks: <Task>[
          Task(
            id: 'task-1',
            title: 'Build feature',
            pomodoroCount: 2,
            completedPomodoros: 0,
            priority: TaskPriority.high,
            status: TaskStatus.inProgress,
            createdAt: DateTime(2026, 4, 19, 9, 1),
          ),
        ],
      );
      final _FakeTaskTimerSystemScheduler systemScheduler =
          _FakeTaskTimerSystemScheduler();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          focusRepositoryProvider.overrideWithValue(repository),
          notificationClientProvider.overrideWithValue(
            _FakeNotificationClient(),
          ),
          taskTimerSystemSchedulerProvider.overrideWithValue(systemScheduler),
          statisticsProvider.overrideWith(
            (Ref ref) => _FakeStatisticsNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskProvider.notifier).reloadTasks();
      await _flushMicrotasks();
      final TimerProvider timer = container.read(timerProvider.notifier);
      timer.startTimer();
      await _flushMicrotasks();

      timer.applySystemControlEvent(
        TaskTimerSystemControlEvent(
          action: 'pause',
          taskId: 'task-1',
          alarmId: 'alarm-1',
          remainingSeconds: 90,
          occurredAt: DateTime(2026, 4, 20, 10, 1),
        ),
      );

      expect(timer.state, TimerState.paused);
      expect(timer.timeLeftInSeconds, 90);
      expect(systemScheduler.canceledTaskIds, isEmpty);
    },
  );

  test(
    'native standalone pause event restores timer after cold start',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final _FakeFocusRepository repository = _FakeFocusRepository(
        tasks: <Task>[],
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          focusRepositoryProvider.overrideWithValue(repository),
          notificationClientProvider.overrideWithValue(
            _FakeNotificationClient(),
          ),
          statisticsProvider.overrideWith(
            (Ref ref) => _FakeStatisticsNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskProvider.notifier).reloadTasks();
      await _flushMicrotasks();
      final TimerProvider timer = container.read(timerProvider.notifier);

      timer.applySystemControlEvent(
        TaskTimerSystemControlEvent(
          action: 'pause',
          taskId: 'standalone:123',
          alarmId: 'alarm-1',
          remainingSeconds: 90,
          occurredAt: DateTime(2026, 4, 20, 10, 1),
        ),
      );

      expect(timer.state, TimerState.paused);
      expect(timer.timeLeftInSeconds, 90);
    },
  );
}
