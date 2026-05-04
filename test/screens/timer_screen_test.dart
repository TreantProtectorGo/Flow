import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/l10n/app_localizations.dart';
import 'package:focus/models/task.dart';
import 'package:focus/screens/timer_screen.dart';
import 'package:focus/services/focus_repository.dart';
import 'package:focus/services/notification_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFocusRepository implements FocusRepository {
  final List<Task> tasks;

  _FakeFocusRepository({required this.tasks});

  @override
  Future<void> clearAllData() async {}

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
  }) async {}

  @override
  Future<void> insertTask(Task task) async {}

  @override
  Future<void> softDeleteTask(String id) async {}

  @override
  Future<void> updateTask(Task task) async {}
}

class _FakeNotificationClient implements NotificationClient {
  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelAllTaskReminders() async {}

  @override
  Future<void> cancelTaskReminder(String taskId) async {}

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

void main() {
  testWidgets('current task card hides daily reminder details', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'currentTaskId': 'task-1',
    });
    final Task task = Task(
      id: 'task-1',
      title: 'Read design notes',
      pomodoroCount: 2,
      priority: TaskPriority.medium,
      status: TaskStatus.inProgress,
      createdAt: DateTime(2026, 5, 5, 9, 0),
      dailyReminderTime: '09:30',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          focusRepositoryProvider.overrideWithValue(
            _FakeFocusRepository(tasks: <Task>[task]),
          ),
          notificationClientProvider.overrideWithValue(
            _FakeNotificationClient(),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: TimerScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Read design notes'), findsOneWidget);
    expect(find.textContaining('Daily Reminder'), findsNothing);
    expect(find.byIcon(Icons.notifications_active_outlined), findsNothing);
  });
}
