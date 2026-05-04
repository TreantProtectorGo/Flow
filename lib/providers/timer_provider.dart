import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/focus_repository.dart';
import '../services/notification_client.dart';
import '../services/task_timer_system_scheduler.dart';
import 'notification_strings_provider.dart';
import 'settings_provider.dart';
import 'statistics_provider.dart';
import 'task_provider.dart';

// Riverpod provider
final timerProvider = ChangeNotifierProvider<TimerProvider>((ref) {
  return TimerProvider(
    ref,
    repository: ref.watch(focusRepositoryProvider),
    notificationClient: ref.watch(notificationClientProvider),
  );
});

enum TimerState { stopped, running, paused }

enum TimerMode {
  focus, // Focus time: 25 minutes
  shortBreak, // Short break: 5 minutes
  longBreak, // Long break: 15 minutes
}

bool shouldTakeLongBreak({
  required int completedSessions,
  required int longBreakFrequency,
}) {
  final normalizedFrequency = longBreakFrequency <= 0 ? 4 : longBreakFrequency;
  return completedSessions > 0 && completedSessions % normalizedFrequency == 0;
}

class TimerProvider with ChangeNotifier {
  final Ref _ref;
  final FocusRepository _repository;
  final NotificationClient _notificationClient;
  Timer? _timer;

  // Debug mode: use short timers for testing (only in debug builds)
  static const bool _useDebugTimers =
      kDebugMode && false; // Set to true to enable

  // Timer settings (debug: 10s/5s/8s, release: 25m/5m/15m)
  int _focusTimeInMinutes = _useDebugTimers
      ? 1
      : 25; // 1 min in debug for faster testing
  int _shortBreakTimeInMinutes = _useDebugTimers ? 1 : 5;
  int _longBreakTimeInMinutes = _useDebugTimers ? 1 : 15;

  // In debug mode, use seconds instead of minutes for even faster testing
  int get _focusTimeInSeconds =>
      _useDebugTimers ? 10 : _focusTimeInMinutes * 60;
  int get _shortBreakTimeInSeconds =>
      _useDebugTimers ? 5 : _shortBreakTimeInMinutes * 60;
  int get _longBreakTimeInSeconds =>
      _useDebugTimers ? 8 : _longBreakTimeInMinutes * 60;

  // Current timer state
  TimerState _state = TimerState.stopped;
  TimerMode _mode = TimerMode.focus;
  int _timeLeftInSeconds = _useDebugTimers ? 10 : 25 * 60;
  int _totalTimeInSeconds = _useDebugTimers ? 10 : 25 * 60;

  // Session tracking
  int _currentSession = 1;
  int _completedSessions = 0;
  int _totalFocusSessions = 0;

  // Track current pomodoro session start time and ID
  DateTime? _currentSessionStartTime;
  String? _currentSessionId;
  String? _activeSystemTimelineId;
  bool _isStandaloneTimerRun = false;

  TimerProvider(
    this._ref, {
    required FocusRepository repository,
    required NotificationClient notificationClient,
  }) : _repository = repository,
       _notificationClient = notificationClient {
    _loadSettings();
  }

  // Getters
  TimerState get state => _state;
  TimerMode get mode => _mode;
  int get timeLeftInSeconds => _timeLeftInSeconds;
  int get totalTimeInSeconds => _totalTimeInSeconds;
  int get currentSession => _currentSession;
  int get completedSessions => _completedSessions;
  int get totalFocusSessions => _totalFocusSessions;
  int get focusTimeInMinutes => _focusTimeInMinutes;
  int get shortBreakTimeInMinutes => _shortBreakTimeInMinutes;
  int get longBreakTimeInMinutes => _longBreakTimeInMinutes;

  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isStopped => _state == TimerState.stopped;
  bool get isFocusMode => _mode == TimerMode.focus;
  bool get isBreakMode =>
      _mode == TimerMode.shortBreak || _mode == TimerMode.longBreak;

  double get progress => _totalTimeInSeconds > 0
      ? (_totalTimeInSeconds - _timeLeftInSeconds) / _totalTimeInSeconds
      : 0.0;

  String get timeDisplayString {
    final minutes = _timeLeftInSeconds ~/ 60;
    final seconds = _timeLeftInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getModeDisplayString(String Function(TimerMode) translator) {
    return translator(_mode);
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _focusTimeInMinutes = prefs.getInt('focusTime') ?? 25;
      _shortBreakTimeInMinutes = prefs.getInt('shortBreakTime') ?? 5;
      _longBreakTimeInMinutes = prefs.getInt('longBreakTime') ?? 15;
      _totalFocusSessions = prefs.getInt('totalFocusSessions') ?? 0;

      _updateTimeForCurrentMode();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading pomodoro settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('focusTime', _focusTimeInMinutes);
      await prefs.setInt('shortBreakTime', _shortBreakTimeInMinutes);
      await prefs.setInt('longBreakTime', _longBreakTimeInMinutes);
      await prefs.setInt('totalFocusSessions', _totalFocusSessions);
    } catch (e) {
      debugPrint('Error saving pomodoro settings: $e');
    }
  }

  void _updateTimeForCurrentMode() {
    switch (_mode) {
      case TimerMode.focus:
        _timeLeftInSeconds = _focusTimeInSeconds;
        _totalTimeInSeconds = _focusTimeInSeconds;
        break;
      case TimerMode.shortBreak:
        _timeLeftInSeconds = _shortBreakTimeInSeconds;
        _totalTimeInSeconds = _shortBreakTimeInSeconds;
        break;
      case TimerMode.longBreak:
        _timeLeftInSeconds = _longBreakTimeInSeconds;
        _totalTimeInSeconds = _longBreakTimeInSeconds;
        break;
    }
  }

  void startTimer() {
    if (_state == TimerState.running) return;

    _state = TimerState.running;

    // Record session start time (only on first start, resume after pause doesn't restart)
    if (_currentSessionStartTime == null && _mode == TimerMode.focus) {
      _currentSessionStartTime = DateTime.now();
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _isStandaloneTimerRun =
          _ref.read(taskProvider.notifier).currentTask == null;
      debugPrint(
        '⏱️ [TIMER] Starting new pomodoro session (ID: $_currentSessionId)',
      );
      unawaited(_scheduleSystemTimelineForCurrentTask());
    }

    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeftInSeconds <= 0) {
        _onTimerComplete();
      } else {
        _timeLeftInSeconds--;
        notifyListeners();
      }
    });
  }

  void pauseTimer() {
    if (_state != TimerState.running) return;

    _timer?.cancel();
    _state = TimerState.paused;
    if (_mode == TimerMode.focus) {
      unawaited(_cancelSystemTimelineForCurrentTask());
    }
    notifyListeners();
  }

  Future<void> stopTimer() async {
    _timer?.cancel();
    await _cancelSystemTimelineForCurrentTask();
    _state = TimerState.stopped;
    _isStandaloneTimerRun = false;

    // If in focus mode and has start time, record as incomplete session
    if (_mode == TimerMode.focus && _currentSessionStartTime != null) {
      await _recordPomodoroSession(completed: false);
    }

    _updateTimeForCurrentMode();
    notifyListeners();
  }

  void skipTimer() {
    unawaited(_cancelSystemTimelineForCurrentTask());
    _onTimerComplete();
  }

  Future<void> _onTimerComplete() async {
    _timer?.cancel();
    _state = TimerState.stopped;

    final currentTask = _ref.read(taskProvider.notifier).currentTask;
    final notificationStrings = _ref.read(notificationStringsProvider);
    final isLongBreak = _mode == TimerMode.longBreak;

    if (_mode == TimerMode.focus) {
      _completedSessions++;
      _totalFocusSessions++;

      // Record completed pomodoro session to database
      await _recordPomodoroSession(completed: true);

      // Check if this pomodoro will complete the task BEFORE incrementing
      // (completedPomodoros + 1) because we haven't incremented yet
      final willCompleteTask =
          currentTask != null &&
          (currentTask.completedPomodoros + 1) >= currentTask.pomodoroCount;

      // Notify task provider that a pomodoro was completed
      _ref.read(taskProvider.notifier).completePomodoroForCurrentTask();

      // Update statistics data
      _ref.read(statisticsProvider.notifier).loadStatistics();

      if (willCompleteTask) {
        // Task has completed all its pomodoros - show task complete notification and stop
        await _notificationClient.showTaskCompleteNotification(
          title: notificationStrings.taskCompleteTitle,
          body: notificationStrings.taskCompleteBody(currentTask.title),
          channelName: notificationStrings.channelName,
          channelDescription: notificationStrings.channelDescription,
        );

        debugPrint(
          '🎉 [TIMER] Task "${currentTask.title}" completed all pomodoros (${currentTask.pomodoroCount}/${currentTask.pomodoroCount})',
        );

        // Auto-complete the task
        await _ref
            .read(taskProvider.notifier)
            .markTaskAsCompleted(currentTask.id);

        // Reset to focus mode but don't auto-start
        await _cancelSystemTimelineForCurrentTask(taskId: currentTask.id);
        _mode = TimerMode.focus;
        _updateTimeForCurrentMode();
        _saveSettings();
        notifyListeners();
        return; // Stop here, don't auto-continue
      }

      // Show notification for focus session complete
      await _notificationClient.showFocusCompleteNotification(
        title: notificationStrings.focusCompleteTitle,
        body: currentTask != null
            ? notificationStrings.focusCompleteWithTask(currentTask.title)
            : notificationStrings.focusCompleteBody,
        channelName: notificationStrings.channelName,
        channelDescription: notificationStrings.channelDescription,
      );

      // Decide next phase: short break or long break
      final longBreakFrequency = _ref.read(settingsProvider).longBreakFrequency;
      if (shouldTakeLongBreak(
        completedSessions: _completedSessions,
        longBreakFrequency: longBreakFrequency,
      )) {
        _mode = TimerMode.longBreak;
      } else {
        _mode = TimerMode.shortBreak;
      }
    } else {
      // Show notification for break session complete
      await _notificationClient.showBreakCompleteNotification(
        title: isLongBreak
            ? notificationStrings.longBreakCompleteTitle
            : notificationStrings.breakCompleteTitle,
        body: notificationStrings.breakCompleteBody,
        channelName: notificationStrings.channelName,
        channelDescription: notificationStrings.channelDescription,
      );

      // Break ended, return to focus mode
      _mode = TimerMode.focus;
      _currentSession++;

      if (_isStandaloneTimerRun) {
        _isStandaloneTimerRun = false;
        _activeSystemTimelineId = null;
        _updateTimeForCurrentMode();
        _saveSettings();
        notifyListeners();
        return;
      }
    }

    _updateTimeForCurrentMode();
    _saveSettings();
    notifyListeners();

    // Auto-continue to next phase
    startTimer();
  }

  /// Record pomodoro session to database
  Future<void> _recordPomodoroSession({required bool completed}) async {
    if (_currentSessionStartTime == null) {
      debugPrint('⚠️ [TIMER] Cannot record session: no start time');
      return;
    }

    try {
      final endTime = DateTime.now();
      final durationSeconds = endTime
          .difference(_currentSessionStartTime!)
          .inSeconds;
      // Round to nearest minute, with minimum 1 minute for completed sessions
      final duration = completed
          ? durationSeconds < 60
                ? 1
                : (durationSeconds / 60).round()
          : (durationSeconds / 60).round();
      final currentTask = _ref.read(taskProvider.notifier).currentTask;

      await _repository.insertPomodoroSession(
        taskId: currentTask?.id,
        startTime: _currentSessionStartTime!,
        endTime: endTime,
        duration: duration,
        completed: completed,
        sessionType: _mode.name,
      );

      debugPrint('✅ [TIMER] Pomodoro session recorded to database');
      debugPrint('   - Task: ${currentTask?.title ?? "No associated task"}');
      debugPrint('   - Duration: $duration minutes');
      debugPrint('   - Completed: $completed');

      // Reset session tracking
      _currentSessionStartTime = null;
      _currentSessionId = null;
    } catch (e) {
      debugPrint('❌ [TIMER] Failed to record pomodoro session: $e');
    }
  }

  Future<void> switchToFocusMode() async {
    if (_mode == TimerMode.focus) return;

    // If a focus timer is running, record the incomplete session first
    if (_state == TimerState.running && _currentSessionStartTime != null) {
      await _recordPomodoroSession(completed: false);
    }

    await stopTimer();
    _mode = TimerMode.focus;
    _updateTimeForCurrentMode();
    notifyListeners();
  }

  Future<void> switchToBreakMode() async {
    if (isBreakMode) return;

    await stopTimer();
    _mode = TimerMode.shortBreak;
    _updateTimeForCurrentMode();
    notifyListeners();
  }

  // Set timer duration (in minutes)
  void setFocusTime(int minutes) {
    _focusTimeInMinutes = minutes;
    if (_mode == TimerMode.focus) {
      _updateTimeForCurrentMode();
    }
    _saveSettings();
    unawaited(_rescheduleSystemTimelineForCurrentTask());
    notifyListeners();
  }

  void setShortBreakTime(int minutes) {
    _shortBreakTimeInMinutes = minutes;
    if (_mode == TimerMode.shortBreak) {
      _updateTimeForCurrentMode();
    }
    _saveSettings();
    unawaited(_rescheduleSystemTimelineForCurrentTask());
    notifyListeners();
  }

  void setLongBreakTime(int minutes) {
    _longBreakTimeInMinutes = minutes;
    if (_mode == TimerMode.longBreak) {
      _updateTimeForCurrentMode();
    }
    _saveSettings();
    unawaited(_rescheduleSystemTimelineForCurrentTask());
    notifyListeners();
  }

  Future<void> _scheduleSystemTimelineForCurrentTask() async {
    final Task? currentTask = _ref.read(taskProvider.notifier).currentTask;
    final DateTime? startAt = _currentSessionStartTime;
    if (startAt == null || _mode != TimerMode.focus) {
      return;
    }

    final NotificationStrings strings = _ref.read(notificationStringsProvider);
    final TaskTimerPlan plan;
    if (currentTask == null) {
      final String timelineId =
          'standalone:${_currentSessionId ?? startAt.millisecondsSinceEpoch}';
      plan =
          TaskTimerPlan.createStandalone(
            id: timelineId,
            title: strings.pomodoroMode,
            startAt: startAt,
            focusMinutes: _focusTimeInMinutes,
            shortBreakMinutes: _shortBreakTimeInMinutes,
            firstFocusSeconds: _timeLeftInSeconds,
          ).withAlertText(
            (TaskTimerPhase phase) => _phaseAlertTitle(phase, strings),
            (TaskTimerPhase phase) => _phaseAlertBody(phase, strings),
          );
    } else {
      final Task? nextTask = _ref
          .read(taskProvider.notifier)
          .findNextIncompleteTaskAfter(currentTask.id);
      final int longBreakFrequency = _ref
          .read(settingsProvider)
          .longBreakFrequency;
      plan =
          TaskTimerPlan.create(
            task: currentTask,
            startAt: startAt,
            focusMinutes: _focusTimeInMinutes,
            shortBreakMinutes: _shortBreakTimeInMinutes,
            longBreakMinutes: _longBreakTimeInMinutes,
            longBreakFrequency: longBreakFrequency,
            nextTaskId: nextTask?.id,
            nextTaskTitle: nextTask?.title,
            firstFocusSeconds: _timeLeftInSeconds,
          ).withAlertText(
            (TaskTimerPhase phase) => _phaseAlertTitle(phase, strings),
            (TaskTimerPhase phase) => _phaseAlertBody(phase, strings),
          );
    }

    _activeSystemTimelineId = plan.taskId;
    await _ref
        .read(taskTimerSystemSchedulerProvider)
        .scheduleTaskTimeline(plan);
  }

  Future<void> _cancelSystemTimelineForCurrentTask({String? taskId}) async {
    final String? id =
        taskId ??
        _activeSystemTimelineId ??
        _ref.read(taskProvider.notifier).currentTask?.id;
    if (id == null) {
      return;
    }

    await _ref.read(taskTimerSystemSchedulerProvider).cancelTaskTimeline(id);
    if (_activeSystemTimelineId == id) {
      _activeSystemTimelineId = null;
    }
  }

  Future<void> _rescheduleSystemTimelineForCurrentTask() async {
    if (_state != TimerState.running || _mode != TimerMode.focus) {
      return;
    }

    await _cancelSystemTimelineForCurrentTask();
    await _scheduleSystemTimelineForCurrentTask();
  }

  String _phaseAlertTitle(TaskTimerPhase phase, NotificationStrings strings) {
    switch (phase.payloadType) {
      case TaskTimerPayloadType.phaseEnd:
        return strings.pomodoroFocusCompleteTitle(
          phase.completedPomodorosAtEnd,
          phase.totalPomodoros,
        );
      case TaskTimerPayloadType.phaseStart:
        return strings.pomodoroBreakCompleteTitle(
          phase.kind == TaskTimerPhaseKind.longBreak
              ? strings.longBreak
              : strings.shortBreak,
        );
      case TaskTimerPayloadType.taskComplete:
      case TaskTimerPayloadType.nextTaskPrompt:
        return strings.taskCompleteTitle;
      case TaskTimerPayloadType.standaloneTimerComplete:
        return strings.breakCompleteTitle;
    }
  }

  String _phaseAlertBody(TaskTimerPhase phase, NotificationStrings strings) {
    switch (phase.payloadType) {
      case TaskTimerPayloadType.phaseEnd:
        final int longBreakFrequency = _ref
            .read(settingsProvider)
            .longBreakFrequency;
        final int normalizedLongBreakFrequency = longBreakFrequency <= 0
            ? 4
            : longBreakFrequency;
        final bool nextBreakIsLong =
            phase.completedPomodorosAtEnd > 0 &&
            phase.completedPomodorosAtEnd % normalizedLongBreakFrequency == 0;
        return strings.pomodoroStartBreakBody(
          nextBreakIsLong ? strings.longBreak : strings.shortBreak,
        );
      case TaskTimerPayloadType.phaseStart:
        return strings.pomodoroStartFocusBody(phase.pomodoroIndex + 1);
      case TaskTimerPayloadType.taskComplete:
        return strings.taskCompleteBody(
          _ref.read(taskProvider.notifier).currentTask?.title ?? '',
        );
      case TaskTimerPayloadType.nextTaskPrompt:
        return strings.pomodoroNextTaskBody(
          _ref
                  .read(taskProvider.notifier)
                  .findNextIncompleteTaskAfter(
                    _ref.read(taskProvider.notifier).currentTask?.id ?? '',
                  )
                  ?.title ??
              '',
        );
      case TaskTimerPayloadType.standaloneTimerComplete:
        return strings.breakCompleteBody;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
