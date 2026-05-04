import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/models/task.dart';
import 'package:focus/providers/task_provider.dart';
import 'package:focus/services/focus_repository.dart';
import 'package:focus/services/notification_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFocusRepository implements FocusRepository {
  final List<Task> tasks;

  _FakeFocusRepository({required this.tasks});

  @override
  Future<void> clearAllData() async {
    tasks.clear();
  }

  @override
  Future<List<Task>> getAllTasks() async {
    return tasks.where((Task task) => task.deletedAt == null).toList();
  }

  @override
  Future<void> insertPomodoroSession({
    String? taskId,
    required DateTime startTime,
    DateTime? endTime,
    required int duration,
    required bool completed,
    required String sessionType,
  }) async {}

  @override
  Future<void> insertTask(Task task) async {
    tasks.add(task);
  }

  @override
  Future<void> softDeleteTask(String id) async {
    final int index = tasks.indexWhere((Task task) => task.id == id);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(
        deletedAt: DateTime(2026, 5, 5, 12, 0),
      );
    }
  }

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
  }) async {}

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

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('deleting an AI session deletes every task in that session', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'currentTaskId': 'session-task-2',
    });
    final _FakeFocusRepository repository = _FakeFocusRepository(
      tasks: <Task>[
        Task(
          id: 'other-task',
          title: 'Keep me',
          pomodoroCount: 1,
          priority: TaskPriority.low,
          status: TaskStatus.pending,
          createdAt: DateTime(2026, 5, 5, 11, 0),
        ),
        Task(
          id: 'session-task-1',
          title: 'Pending session task',
          pomodoroCount: 1,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime(2026, 5, 5, 10, 0),
          isAIGenerated: true,
          aiSessionId: 'session-a',
          dailyReminderTime: '09:30',
        ),
        Task(
          id: 'session-task-2',
          title: 'In-progress session task',
          pomodoroCount: 1,
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
          createdAt: DateTime(2026, 5, 5, 9, 0),
          isAIGenerated: true,
          aiSessionId: 'session-a',
        ),
        Task(
          id: 'session-task-3',
          title: 'Completed session task',
          pomodoroCount: 1,
          priority: TaskPriority.low,
          status: TaskStatus.completed,
          createdAt: DateTime(2026, 5, 5, 8, 0),
          isAIGenerated: true,
          aiSessionId: 'session-a',
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

    await container
        .read(taskProvider.notifier)
        .deleteAiSessionTasks('session-a');

    expect(
      container.read(taskProvider).tasks.map((Task task) => task.id),
      <String>['other-task'],
    );
    expect(container.read(taskProvider).currentTaskId, isNull);
    expect(
      repository.tasks
          .where((Task task) => task.aiSessionId == 'session-a')
          .every((Task task) => task.deletedAt != null),
      isTrue,
    );
    expect(notifications.canceledTaskIds, contains('session-task-1'));
    expect(notifications.canceledTaskIds, contains('session-task-2'));
    expect(notifications.canceledTaskIds, contains('session-task-3'));
  });
}
