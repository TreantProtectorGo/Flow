import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../providers/task_completion_event_provider.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/calendar_quick_add_planner.dart';
import '../services/calendar_service.dart';
import '../utils/snackbar_util.dart';
import '../widgets/dialogs/delete_confirmation_dialog.dart';
import '../widgets/task_form_dialog.dart';
import 'ai_chat_screen.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});
  static const CalendarService _calendarService = CalendarService();
  static const Duration _aiSessionGap = Duration(minutes: 2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    ref.listen<TaskCompletionEvent?>(taskCompletionEventProvider, (
      TaskCompletionEvent? previous,
      TaskCompletionEvent? next,
    ) {
      if (next != null && next.eventId != previous?.eventId) {
        SnackBarUtil.showSuccessSnackBar(
          context,
          message: l10n.taskCelebrationMessage(next.taskTitle),
        );
        if (next.nextTaskId != null) {
          _showNextTaskPrompt(
            context: context,
            ref: ref,
            completedTaskId: next.taskId,
            nextTaskId: next.nextTaskId!,
            l10n: l10n,
          );
        }
      }
    });

    ref.listen<PendingNextTaskPrompt?>(pendingNextTaskPromptProvider, (
      PendingNextTaskPrompt? previous,
      PendingNextTaskPrompt? next,
    ) {
      if (next == null ||
          (previous?.completedTaskId == next.completedTaskId &&
              previous?.nextTaskId == next.nextTaskId)) {
        return;
      }
      _showNextTaskPrompt(
        context: context,
        ref: ref,
        completedTaskId: next.completedTaskId,
        nextTaskId: next.nextTaskId,
        l10n: l10n,
      );
      ref.read(pendingNextTaskPromptProvider.notifier).state = null;
    });

    final taskNotifier = ref.watch(taskProvider);
    final timerNotifier = ref.watch(timerProvider);
    final currentTask = taskNotifier.currentTask;
    final isTimerRunning = timerNotifier.isRunning;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Content area with task list
            Expanded(
              child: taskNotifier.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Active timer task card (pinned at top)
                          if (currentTask != null && isTimerRunning)
                            _buildActiveTimerCard(
                              currentTask,
                              timerNotifier,
                              theme,
                              context,
                              ref,
                              l10n,
                            ),

                          if (currentTask != null && isTimerRunning)
                            const SizedBox(height: 20),

                          // In-progress tasks (exclude the currently running task to avoid duplicate)
                          if (taskNotifier.inProgressTasks
                              .where(
                                (task) =>
                                    !(currentTask != null &&
                                        isTimerRunning &&
                                        task.id == currentTask.id),
                              )
                              .isNotEmpty) ...[
                            _buildSectionHeader(l10n.inProgress, theme),
                            const SizedBox(height: 15),
                            ...taskNotifier.inProgressTasks
                                .where(
                                  (task) =>
                                      !(currentTask != null &&
                                          isTimerRunning &&
                                          task.id == currentTask.id),
                                )
                                .map(
                                  (task) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _buildTaskCard(
                                      task,
                                      theme,
                                      context,
                                      ref,
                                      l10n,
                                    ),
                                  ),
                                ),
                            const SizedBox(height: 30),
                          ],

                          // Pending tasks
                          _buildSectionHeader(l10n.pending, theme),
                          const SizedBox(height: 15),

                          if (taskNotifier.pendingTasks.isEmpty)
                            _buildEmptyState(l10n.emptyPendingTasks, theme)
                          else
                            ..._buildPendingTaskWidgets(
                              tasks: taskNotifier.pendingTasks,
                              theme: theme,
                              context: context,
                              ref: ref,
                              l10n: l10n,
                            ),

                          const SizedBox(height: 30),

                          // Completed tasks
                          if (taskNotifier.completedTasks.isNotEmpty) ...[
                            _buildSectionHeader(l10n.completed, theme),
                            const SizedBox(height: 15),
                            ...taskNotifier.completedTasks.map(
                              (task) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Opacity(
                                  opacity: 0.6,
                                  child: _buildTaskCard(
                                    task,
                                    theme,
                                    context,
                                    ref,
                                    l10n,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(
                            height: 100,
                          ), // Add bottom padding for FAB
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAIChatScreen(context),
        icon: const Icon(Icons.auto_awesome),
        label: Text(l10n.addTask),
      ),
    );
  }

  void _openAIChatScreen(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => const AIChatScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showEditTaskDialog(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TaskFormDialog(task: task),
    );

    if (result != null && context.mounted) {
      // Check if this is a delete action
      if (result['action'] == 'delete') {
        _showDeleteConfirmDialog(context, ref, task);
        return;
      }

      // Update task with new values
      final updatedTask = task.copyWith(
        title: result['title'],
        description: result['description'],
        pomodoroCount: result['pomodoroCount'],
        priority: result['priority'],
        status: result['status'],
        dailyReminderTime: result['dailyReminderTime'],
      );

      await ref.read(taskProvider.notifier).updateTask(updatedTask);
    }
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: task.title,
    );

    if (confirmed == true) {
      ref.read(taskProvider.notifier).deleteTask(task.id);
    }
  }

  Widget _buildEmptyState(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.task_alt, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTimerCard(
    Task task,
    TimerProvider timerNotifier,
    ThemeData theme,
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/timer'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.timer,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.focusingNow,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getModeDisplay(timerNotifier.mode, l10n),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timerNotifier.timeDisplayString,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  task.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.dailyReminderTime != null &&
                    task.status != TaskStatus.completed) ...[
                  const SizedBox(height: 8),
                  _buildReminderBadge(
                    context: context,
                    theme: theme,
                    l10n: l10n,
                    reminderTime: task.dailyReminderTime!,
                    backgroundColor: theme.colorScheme.surface.withValues(
                      alpha: 0.28,
                    ),
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ],
                const SizedBox(height: 8),
                // Pomodoro progress display
                Row(
                  children: [
                    Text(
                      l10n.pomodoroProgress(
                        task.completedPomodoros,
                        task.pomodoroCount,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (task.completedPomodoros >= task.pomodoroCount)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.check_circle,
                          size: 14,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: timerNotifier.progress,
                          minHeight: 8,
                          backgroundColor: theme.colorScheme.surface.withValues(
                            alpha: 0.3,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => _quickAddTaskToCalendar(
                        context,
                        task,
                        timerNotifier.focusTimeInMinutes,
                        l10n,
                      ),
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: Text(l10n.addToCalendar),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => context.go('/timer'),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: Text(l10n.view),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    Task task,
    ThemeData theme,
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    bool showCalendarButton = true,
  }) {
    final taskNotifier = ref.watch(taskProvider);
    final timerNotifier = ref.watch(timerProvider);
    final isCurrentTask = taskNotifier.currentTaskId == task.id;
    final isTimerRunning = timerNotifier.isRunning && isCurrentTask;

    Color priorityColor;
    Color priorityBackgroundColor;

    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = theme.colorScheme.error;
        priorityBackgroundColor = theme.colorScheme.errorContainer;
        break;
      case TaskPriority.medium:
        priorityColor = theme.colorScheme.tertiary;
        priorityBackgroundColor = theme.colorScheme.tertiaryContainer;
        break;
      case TaskPriority.low:
        priorityColor = theme.colorScheme.primary;
        priorityBackgroundColor = theme.colorScheme.primaryContainer;
        break;
    }

    // Calculate pomodoro progress
    final pomodoroProgress = task.completedPomodoros / task.pomodoroCount;
    final progressColor = pomodoroProgress >= 1.0
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    return Dismissible(
      key: Key(task.id),
      direction: task.status != TaskStatus.completed
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.check,
          color: theme.colorScheme.onTertiaryContainer,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        // Mark as completed directly
        await ref.read(taskProvider.notifier).markTaskAsCompleted(task.id);
        return false; // Don't actually dismiss, just update state
      },
      child: Card(
        elevation: isCurrentTask ? 4 : 2,
        margin: EdgeInsets.zero,
        surfaceTintColor: theme.colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isCurrentTask
              ? BorderSide(color: theme.colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => _showEditTaskDialog(context, ref, task),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: task.status == TaskStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (task.status != TaskStatus.completed) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () =>
                            _startPomodoroForTask(context, ref, task, l10n),
                        icon: Icon(
                          isCurrentTask ? Icons.play_arrow : Icons.timer,
                          size: 16,
                        ),
                        label: Text(
                          isCurrentTask ? l10n.continueButton : l10n.start,
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 28),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          backgroundColor: isCurrentTask
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer,
                          foregroundColor: isCurrentTask
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ],
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (task.dailyReminderTime != null &&
                    task.status != TaskStatus.completed) ...[
                  const SizedBox(height: 8),
                  _buildReminderBadge(
                    context: context,
                    theme: theme,
                    l10n: l10n,
                    reminderTime: task.dailyReminderTime!,
                    backgroundColor: theme.colorScheme.secondaryContainer
                        .withValues(alpha: 0.7),
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                  ),
                ],
                if (isTimerRunning ||
                    (task.status != TaskStatus.completed &&
                        (!task.isAIGenerated || showCalendarButton))) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isTimerRunning)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 13,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${l10n.focusingNow} ${timerNotifier.timeDisplayString}',
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: [
                                        const FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (task.status != TaskStatus.completed &&
                          !isTimerRunning &&
                          showCalendarButton) ...[
                        if (isTimerRunning) const SizedBox(width: 6),
                        IconButton.filledTonal(
                          onPressed: () => _quickAddTaskToCalendar(
                            context,
                            task,
                            timerNotifier.focusTimeInMinutes,
                            l10n,
                          ),
                          icon: const Icon(Icons.calendar_month, size: 16),
                          tooltip: l10n.addToCalendar,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(28, 28),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      if (task.status != TaskStatus.completed &&
                          !task.isAIGenerated) ...[
                        if (isTimerRunning ||
                            (!isTimerRunning && showCalendarButton))
                          const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => _openAIChatWithTask(context, task),
                          icon: Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: theme.colorScheme.secondary,
                          ),
                          tooltip: l10n.breakdownWithAI,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(28, 28),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: progressColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.pomodoroProgress(
                              task.completedPomodoros,
                              task.pomodoroCount,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: progressColor,
                            ),
                          ),
                          if (task.completedPomodoros >= task.pomodoroCount)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.check_circle,
                                size: 14,
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pomodoroProgress.clamp(0.0, 1.0),
                                minHeight: 3,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 1,
                        vertical: -2,
                      ),
                      padding: EdgeInsets.zero,
                      backgroundColor: priorityBackgroundColor,
                      label: Text(
                        task.priorityText(l10n),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: priorityColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderBadge({
    required BuildContext context,
    required ThemeData theme,
    required AppLocalizations l10n,
    required String reminderTime,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.notifications_active_outlined,
            size: 14,
            color: foregroundColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${l10n.dailyReminder}: ${_formatReminderTime(context, reminderTime)}',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatReminderTime(BuildContext context, String reminderTime) {
    final List<String> parts = reminderTime.split(':');
    final TimeOfDay timeOfDay = TimeOfDay(
      hour: int.parse(parts.first),
      minute: int.parse(parts.last),
    );
    return MaterialLocalizations.of(context).formatTimeOfDay(timeOfDay);
  }

  void _openAIChatWithTask(BuildContext context, Task task) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => AIChatScreen(
          initialMessage:
              '請幫我拆解這個任務：${task.title}${task.description != null ? '\n描述：${task.description}' : ''}',
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _startPomodoroForTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
    AppLocalizations l10n,
  ) {
    final taskNotifier = ref.read(taskProvider.notifier);
    final timerNotifier = ref.read(timerProvider.notifier);
    final isCurrentTask = ref.read(taskProvider).currentTaskId == task.id;

    // Set as current task
    taskNotifier.setCurrentTask(task.id);

    // If not current task or timer is stopped, reset and start
    if (!isCurrentTask || ref.read(timerProvider).isStopped) {
      // Switch to timer screen
      context.go('/timer');

      // Auto-start timer
      Future.delayed(const Duration(milliseconds: 300), () {
        timerNotifier.startTimer();
      });

      // Show notification message
      SnackBarUtil.showInfoSnackBar(
        context,
        message: l10n.startFocus(task.title),
      );
    } else {
      // Already current task, just switch screens
      context.go('/timer');

      SnackBarUtil.showInfoSnackBar(
        context,
        message: l10n.continueTask(task.title),
      );
    }
  }

  void _showNextTaskPrompt({
    required BuildContext context,
    required WidgetRef ref,
    required String completedTaskId,
    required String nextTaskId,
    required AppLocalizations l10n,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) {
        return;
      }

      final tasks = ref.read(taskProvider).tasks;
      final Task? completedTask = _findTaskById(tasks, completedTaskId);
      final Task? nextTask = _findTaskById(tasks, nextTaskId);
      if (nextTask == null || nextTask.status == TaskStatus.completed) {
        return;
      }

      final bool? shouldStart = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text(l10n.startNextTaskTitle),
          content: Text(
            l10n.startNextTaskMessage(
              completedTask?.title ?? '',
              nextTask.title,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.start),
            ),
          ],
        ),
      );

      if (shouldStart == true && context.mounted) {
        _startPomodoroForTask(context, ref, nextTask, l10n);
      }
    });
  }

  Task? _findTaskById(List<Task> tasks, String taskId) {
    for (final Task task in tasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  Future<void> _quickAddTaskToCalendar(
    BuildContext context,
    Task task,
    int focusMinutes,
    AppLocalizations l10n,
  ) async {
    try {
      final added = await _calendarService.quickAddTask(
        task,
        focusMinutes: focusMinutes,
      );
      if (!context.mounted) {
        return;
      }

      switch (added) {
        case CalendarAddResult.saved:
          SnackBarUtil.showSuccessSnackBar(
            context,
            message: l10n.calendarAdded(task.title),
          );
          break;
        case CalendarAddResult.opened:
          SnackBarUtil.showInfoSnackBar(
            context,
            message: l10n.calendarOpened(task.title),
          );
          break;
        case CalendarAddResult.canceled:
          SnackBarUtil.showInfoSnackBar(
            context,
            message: l10n.calendarAddCancelled,
          );
          break;
        case CalendarAddResult.duplicate:
          SnackBarUtil.showInfoSnackBar(
            context,
            message: l10n.calendarAlreadyAdded,
          );
          break;
        case CalendarAddResult.failed:
          SnackBarUtil.showErrorSnackBar(
            context,
            message: l10n.calendarAddFailed,
          );
          break;
      }
    } catch (_) {
      if (context.mounted) {
        SnackBarUtil.showErrorSnackBar(
          context,
          message: l10n.calendarAddFailed,
        );
      }
    }
  }

  List<Widget> _buildPendingTaskWidgets({
    required List<Task> tasks,
    required ThemeData theme,
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) {
    final groups = _groupPendingTasks(tasks);
    final focusMinutes = ref.watch(timerProvider).focusTimeInMinutes;
    final widgets = <Widget>[];

    for (final group in groups) {
      if (group.isAiSessionGroup) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildAiSessionToggleCard(
              group: group,
              theme: theme,
              context: context,
              ref: ref,
              l10n: l10n,
              onAddToCalendar: () => _quickAddTaskGroupToCalendar(
                context,
                group,
                focusMinutes,
                l10n,
              ),
              onDeleteSession: () => _deleteTaskGroup(context, ref, group),
            ),
          ),
        );
      } else {
        for (final task in group.tasks) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTaskCard(
                task,
                theme,
                context,
                ref,
                l10n,
                showCalendarButton: true,
              ),
            ),
          );
        }
      }
    }

    return widgets;
  }

  List<_TaskGroup> _groupPendingTasks(List<Task> tasks) {
    final groups = <_TaskGroup>[];
    var index = 0;

    while (index < tasks.length) {
      final task = tasks[index];
      if (!task.isAIGenerated) {
        groups.add(
          _TaskGroup(
            tasks: [task],
            isAiSessionGroup: false,
            sessionTitle: null,
            sessionId: null,
          ),
        );
        index += 1;
        continue;
      }

      final aiTasks = <Task>[task];
      var cursor = index + 1;
      var previous = task;
      final seedSessionId = task.aiSessionId;

      while (cursor < tasks.length) {
        final candidate = tasks[cursor];
        if (!candidate.isAIGenerated) {
          break;
        }

        if (seedSessionId != null && seedSessionId.isNotEmpty) {
          if (candidate.aiSessionId != seedSessionId) {
            break;
          }
        } else {
          final gap = previous.createdAt.difference(candidate.createdAt).abs();
          if (gap > _aiSessionGap) {
            break;
          }
        }

        aiTasks.add(candidate);
        previous = candidate;
        cursor += 1;
      }

      final aiTitle = task.aiSessionTitle?.trim();
      groups.add(
        _TaskGroup(
          tasks: aiTasks,
          isAiSessionGroup: aiTasks.length > 1,
          sessionTitle: (aiTitle != null && aiTitle.isNotEmpty)
              ? aiTitle
              : null,
          sessionId: seedSessionId,
        ),
      );
      index = cursor;
    }

    return groups;
  }

  Widget _buildAiSessionToggleCard({
    required _TaskGroup group,
    required ThemeData theme,
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required VoidCallback onAddToCalendar,
    required VoidCallback onDeleteSession,
  }) {
    final tasks = group.tasks;
    final groupTitle = group.sessionTitle ?? l10n.aiSessionGroup(tasks.length);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          collapsedIconColor: theme.colorScheme.onSecondaryContainer,
          iconColor: theme.colorScheme.onSecondaryContainer,
          backgroundColor: theme.colorScheme.surface,
          collapsedBackgroundColor: theme.colorScheme.secondaryContainer
              .withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  groupTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            l10n.aiSessionToggleHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                onPressed: onAddToCalendar,
                icon: const Icon(Icons.calendar_month, size: 18),
                tooltip: l10n.addToCalendar,
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onDeleteSession,
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: l10n.delete,
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          children: tasks
              .map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildTaskCard(
                    task,
                    theme,
                    context,
                    ref,
                    l10n,
                    showCalendarButton: false,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _quickAddTaskGroupToCalendar(
    BuildContext context,
    _TaskGroup group,
    int focusMinutes,
    AppLocalizations l10n,
  ) async {
    final tasks = group.tasks;
    if (tasks.isEmpty) {
      return;
    }

    try {
      final groupTitle =
          group.sessionTitle ?? l10n.aiSessionGroup(tasks.length);
      final entries = tasks
          .map(
            (task) => CalendarPlanEntry(
              title: task.title,
              description: task.description?.trim() ?? '',
              pomodoroCount: task.pomodoroCount,
            ),
          )
          .toList();

      final review = await _showGroupCalendarReviewSheet(
        context: context,
        l10n: l10n,
        groupTitle: groupTitle,
        entries: entries,
        focusMinutes: focusMinutes,
      );
      if (review == null) {
        return;
      }

      final added = await _calendarService.quickAddPlanEntries(
        planTitle: groupTitle,
        entries: entries,
        focusMinutes: focusMinutes,
        startFrom: review.startFrom,
        scheduleMode: review.scheduleMode,
        spreadDays: review.spreadDays,
        exportFingerprint: review.exportFingerprint,
      );

      if (!context.mounted) {
        return;
      }

      switch (added) {
        case CalendarAddResult.saved:
          SnackBarUtil.showSuccessSnackBar(
            context,
            message: l10n.calendarAdded(groupTitle),
          );
          break;
        case CalendarAddResult.opened:
          SnackBarUtil.showInfoSnackBar(
            context,
            message: l10n.calendarOpened(groupTitle),
          );
          break;
        case CalendarAddResult.canceled:
          SnackBarUtil.showInfoSnackBar(
            context,
            message: l10n.calendarAddCancelled,
          );
          break;
        case CalendarAddResult.duplicate:
          SnackBarUtil.showInfoSnackBar(
            context,
            message: l10n.calendarAlreadyAdded,
          );
          break;
        case CalendarAddResult.failed:
          SnackBarUtil.showErrorSnackBar(
            context,
            message: l10n.calendarAddFailed,
          );
          break;
      }
    } catch (_) {
      if (context.mounted) {
        SnackBarUtil.showErrorSnackBar(
          context,
          message: l10n.calendarAddFailed,
        );
      }
    }
  }

  Future<_TaskGroupCalendarReviewSelection?> _showGroupCalendarReviewSheet({
    required BuildContext context,
    required AppLocalizations l10n,
    required String groupTitle,
    required List<CalendarPlanEntry> entries,
    required int focusMinutes,
  }) async {
    final locale = Localizations.localeOf(context).toLanguageTag();
    DateTime selectedStart = CalendarQuickAddPlanner.nextQuarterHour(
      DateTime.now(),
    );
    final suggestedDays = _detectRequestedDays(groupTitle, entries);
    CalendarPlanScheduleMode scheduleMode = suggestedDays > 1
        ? CalendarPlanScheduleMode.spreadByDay
        : CalendarPlanScheduleMode.singleDay;
    var spreadDays = math.max(1, suggestedDays);

    return showModalBottomSheet<_TaskGroupCalendarReviewSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final previewEvents = _calendarService.buildPlanPreview(
              planTitle: groupTitle,
              entries: entries,
              focusMinutes: focusMinutes,
              startFrom: selectedStart,
              scheduleMode: scheduleMode,
              spreadDays: spreadDays,
            );
            final dateText = DateFormat.yMMMd(locale).format(selectedStart);
            final timeText = MaterialLocalizations.of(
              sheetContext,
            ).formatTimeOfDay(TimeOfDay.fromDateTime(selectedStart));

            return SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.84,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reviewCalendarPlanTitle,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      groupTitle,
                      style: Theme.of(sheetContext).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final selectedDate = await showDatePicker(
                                context: sheetContext,
                                initialDate: selectedStart,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 2),
                                ),
                              );
                              if (selectedDate == null) {
                                return;
                              }
                              setSheetState(() {
                                selectedStart = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedStart.hour,
                                  selectedStart.minute,
                                );
                              });
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              '${l10n.calendarStartDateLabel}: $dateText',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final selectedTime = await showTimePicker(
                                context: sheetContext,
                                initialTime: TimeOfDay.fromDateTime(
                                  selectedStart,
                                ),
                              );
                              if (selectedTime == null) {
                                return;
                              }
                              setSheetState(() {
                                selectedStart = DateTime(
                                  selectedStart.year,
                                  selectedStart.month,
                                  selectedStart.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                );
                              });
                            },
                            icon: const Icon(Icons.schedule),
                            label: Text(
                              '${l10n.calendarStartTimeLabel}: $timeText',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.calendarScheduleModeLabel,
                      style: Theme.of(sheetContext).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.calendarScheduleSingleDay),
                          selected:
                              scheduleMode ==
                              CalendarPlanScheduleMode.singleDay,
                          onSelected: (selected) {
                            if (!selected) {
                              return;
                            }
                            setSheetState(() {
                              scheduleMode = CalendarPlanScheduleMode.singleDay;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: Text(
                            l10n.calendarScheduleSpreadDays(spreadDays),
                          ),
                          selected:
                              scheduleMode ==
                              CalendarPlanScheduleMode.spreadByDay,
                          onSelected: (selected) {
                            if (!selected) {
                              return;
                            }
                            setSheetState(() {
                              scheduleMode =
                                  CalendarPlanScheduleMode.spreadByDay;
                              spreadDays = math.max(2, spreadDays);
                            });
                          },
                        ),
                      ],
                    ),
                    if (scheduleMode ==
                        CalendarPlanScheduleMode.spreadByDay) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              min: 2,
                              max: math.max(2, entries.length).toDouble(),
                              divisions: math.max(1, entries.length - 2),
                              value: spreadDays
                                  .clamp(2, math.max(2, entries.length))
                                  .toDouble(),
                              onChanged: (value) {
                                setSheetState(() {
                                  spreadDays = value.round();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      l10n.calendarEventsPreview(previewEvents.length),
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: previewEvents.length,
                        itemBuilder: (context, index) {
                          final event = previewEvents[index];
                          final dateFormat = DateFormat.yMMMd(locale);
                          final start = DateFormat.jm(
                            locale,
                          ).format(event.start);
                          final end = DateFormat.jm(locale).format(event.end);
                          final sameDate =
                              event.start.year == event.end.year &&
                              event.start.month == event.end.month &&
                              event.start.day == event.end.day;
                          final subtitle = sameDate
                              ? '${dateFormat.format(event.start)}  $start - $end'
                              : '${dateFormat.format(event.start)} $start - ${dateFormat.format(event.end)} $end';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                event.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(subtitle),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final fingerprint = _calendarService
                                  .buildPlanExportFingerprint(
                                    planTitle: groupTitle,
                                    entries: entries,
                                    focusMinutes: focusMinutes,
                                    startFrom: selectedStart,
                                    scheduleMode: scheduleMode,
                                    spreadDays: spreadDays,
                                  );
                              Navigator.of(sheetContext).pop(
                                _TaskGroupCalendarReviewSelection(
                                  startFrom: selectedStart,
                                  scheduleMode: scheduleMode,
                                  spreadDays: spreadDays,
                                  exportFingerprint: fingerprint,
                                ),
                              );
                            },
                            child: Text(
                              l10n.addEventsToCalendar(previewEvents.length),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _detectRequestedDays(String groupTitle, List<CalendarPlanEntry> entries) {
    final titleDays = _extractDays(groupTitle);
    if (titleDays != null && titleDays > 1) {
      return titleDays;
    }

    var maxDay = 0;
    var found = 0;
    for (final entry in entries) {
      final day = _extractDayIndex(entry.title);
      if (day != null && day > 0) {
        found++;
        if (day > maxDay) {
          maxDay = day;
        }
      }
    }
    if (found >= math.max(2, entries.length ~/ 2) && maxDay > 1) {
      return maxDay;
    }
    return 1;
  }

  int? _extractDays(String text) {
    final english = RegExp(
      r'\\b(\\d{1,2})\\s*days?\\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (english != null) {
      return int.tryParse(english.group(1)!);
    }
    final chinese = RegExp(r'(\\d{1,2})\\s*天').firstMatch(text);
    if (chinese != null) {
      return int.tryParse(chinese.group(1)!);
    }
    return null;
  }

  int? _extractDayIndex(String text) {
    final english = RegExp(
      r'\\bday\\s*(\\d{1,2})\\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (english != null) {
      return int.tryParse(english.group(1)!);
    }
    final chinese = RegExp(r'第\\s*(\\d{1,2})\\s*天').firstMatch(text);
    if (chinese != null) {
      return int.tryParse(chinese.group(1)!);
    }
    return null;
  }

  Future<void> _deleteTaskGroup(
    BuildContext context,
    WidgetRef ref,
    _TaskGroup group,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final title = group.sessionTitle ?? l10n.aiSessionGroup(group.tasks.length);
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: title,
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final notifier = ref.read(taskProvider.notifier);
    final sessionId = group.sessionId?.trim();
    if (sessionId != null && sessionId.isNotEmpty) {
      await notifier.deleteAiSessionTasks(sessionId);
      return;
    }

    final currentTaskId = ref.read(taskProvider).currentTaskId;
    for (final task in group.tasks) {
      if (task.id == currentTaskId) {
        await notifier.setCurrentTask(null);
      }
      await notifier.deleteTask(task.id);
    }
  }
}

class _TaskGroup {
  final List<Task> tasks;
  final bool isAiSessionGroup;
  final String? sessionTitle;
  final String? sessionId;

  const _TaskGroup({
    required this.tasks,
    required this.isAiSessionGroup,
    required this.sessionTitle,
    required this.sessionId,
  });
}

class _TaskGroupCalendarReviewSelection {
  final DateTime startFrom;
  final CalendarPlanScheduleMode scheduleMode;
  final int spreadDays;
  final String exportFingerprint;

  const _TaskGroupCalendarReviewSelection({
    required this.startFrom,
    required this.scheduleMode,
    required this.spreadDays,
    required this.exportFingerprint,
  });
}

String _getModeDisplay(TimerMode mode, AppLocalizations l10n) {
  switch (mode) {
    case TimerMode.focus:
      return l10n.focusMode;
    case TimerMode.shortBreak:
      return l10n.shortBreakMode;
    case TimerMode.longBreak:
      return l10n.longBreakMode;
  }
}
