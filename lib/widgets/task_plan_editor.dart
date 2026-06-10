import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/pomodoro_time_utils.dart';
import '../utils/priority_utils.dart';
import '../utils/snackbar_util.dart';
import 'dialogs/delete_confirmation_dialog.dart';

/// Task Plan Editor - Allows users to adjust AI-generated plans before importing
///
/// Responsibilities:
/// 1. Display an editable task list
/// 2. Support adding, deleting, editing, and reordering tasks
/// 3. Validate and submit the final plan
class TaskPlanEditor extends ConsumerStatefulWidget {
  final TaskPlan initialPlan;

  const TaskPlanEditor({super.key, required this.initialPlan});

  @override
  ConsumerState<TaskPlanEditor> createState() => _TaskPlanEditorState();
}

class _TaskPlanEditorState extends ConsumerState<TaskPlanEditor> {
  late TaskPlan _editablePlan;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _editablePlan = widget.initialPlan;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: Text(l10n.editTaskPlan)),
      body: Column(
        children: [
          // Main goal editor
          _buildMainGoalEditor(theme, l10n),

          // Task list
          Expanded(child: _buildTaskList(theme, l10n)),

          // Bottom action bar with confirm button
          _buildBottomBar(theme, l10n),
        ],
      ),
      // M3 FAB for adding tasks (floats above bottom bar)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Position above bottom bar
        child: FloatingActionButton(
          onPressed: _handleAddTask,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMainGoalEditor(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.mainGoal,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _editablePlan.mainGoal,
            maxLines: null, // Allow multi-line for long goals
            textInputAction: TextInputAction.done,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: l10n.enterMainGoal,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (value) {
              setState(() {
                _editablePlan = _editablePlan.copyWith(mainGoal: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(ThemeData theme, AppLocalizations l10n) {
    if (_editablePlan.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noTasksInPlan,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _editablePlan.tasks.length,
      onReorder: _handleReorder,
      itemBuilder: (context, index) {
        final task = _editablePlan.tasks[index];
        return _EditableTaskCard(
          key: ValueKey(task.hashCode),
          task: task,
          index: index,
          onEdit: (editedTask) => _handleEditTask(index, editedTask),
          onDelete: () => _handleDeleteTask(index),
        );
      },
    );
  }

  Widget _buildBottomBar(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Task statistics
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.totalTasks(_editablePlan.tasks.length),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.totalPomodoros(_calculateTotalPomodoros()),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _calculateEstimatedTime(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Confirm button (M3 capsule style)
            FilledButton(
              onPressed: _isFormValid() && !_isCreating
                  ? _handleSaveAndCreate
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: const StadiumBorder(),
                disabledBackgroundColor:
                    theme.colorScheme.surfaceContainerHighest,
                disabledForegroundColor: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4),
              ),
              child: _isCreating
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.creating),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 20),
                        const SizedBox(width: 6),
                        Text(l10n.confirm),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isFormValid() {
    return _editablePlan.mainGoal.trim().isNotEmpty &&
        _editablePlan.tasks.isNotEmpty;
  }

  int _calculateTotalPomodoros() {
    return _editablePlan.tasks.fold(0, (sum, task) => sum + task.pomodoroCount);
  }

  /// 根據蕃茄鐘數量和用戶設定計算預計所需時間
  String _calculateEstimatedTime() {
    final totalPomodoros = _calculateTotalPomodoros();
    final timer = ref.read(timerProvider);
    final settings = ref.read(settingsProvider);
    final totalMinutes = calculateEstimatedMinutes(
      totalPomodoros: totalPomodoros,
      focusMinutes: timer.focusTimeInMinutes,
      shortBreakMinutes: timer.shortBreakTimeInMinutes,
      longBreakMinutes: timer.longBreakTimeInMinutes,
      longBreakFrequency: settings.longBreakFrequency,
    );
    final l10n = AppLocalizations.of(context)!;
    return formatEstimatedTime(totalMinutes, l10n);
  }

  /// Update estimated time automatically
  void _updateEstimatedTime() {
    final newTime = _calculateEstimatedTime();
    _editablePlan = _editablePlan.copyWith(estimatedTime: newTime);
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final tasks = List<TaskPlanItem>.from(_editablePlan.tasks);
      final item = tasks.removeAt(oldIndex);
      tasks.insert(newIndex, item);
      _editablePlan = _editablePlan.copyWith(tasks: tasks);
    });
  }

  void _handleEditTask(int index, TaskPlanItem editedTask) {
    setState(() {
      final tasks = List<TaskPlanItem>.from(_editablePlan.tasks);
      tasks[index] = editedTask;
      _editablePlan = _editablePlan.copyWith(tasks: tasks);
      _updateEstimatedTime(); // Auto-update time
    });
  }

  void _handleDeleteTask(int index) {
    setState(() {
      final tasks = List<TaskPlanItem>.from(_editablePlan.tasks);
      tasks.removeAt(index);
      _editablePlan = _editablePlan.copyWith(tasks: tasks);
      _updateEstimatedTime(); // Auto-update time
    });
  }

  void _handleAddTask() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      final newTask = TaskPlanItem(
        title: l10n.newTask,
        description: '',
        steps: [],
        pomodoroCount: 1,
        priority: 'medium',
      );
      final tasks = List<TaskPlanItem>.from(_editablePlan.tasks)..add(newTask);
      _editablePlan = _editablePlan.copyWith(tasks: tasks);
      _updateEstimatedTime(); // Auto-update time
    });
  }

  Future<void> _handleSaveAndCreate() async {
    if (_editablePlan.mainGoal.trim().isEmpty) {
      SnackBarUtil.showErrorSnackBar(
        context,
        message: AppLocalizations.of(context)!.mainGoalRequired,
      );
      return;
    }

    if (_editablePlan.tasks.isEmpty) {
      SnackBarUtil.showErrorSnackBar(
        context,
        message: AppLocalizations.of(context)!.atLeastOneTaskRequired,
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final taskNotifier = ref.read(taskProvider);
      final l10n = AppLocalizations.of(context)!;
      final aiSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final aiSessionTitle =
          (_editablePlan.sessionTitle?.trim().isNotEmpty ?? false)
          ? _editablePlan.sessionTitle!.trim()
          : _editablePlan.mainGoal.trim();

      // Create in reverse order to ensure the first task appears at the top
      for (final taskItem in _editablePlan.tasks.reversed) {
        TaskPriority priority;
        switch (taskItem.priority.toLowerCase()) {
          case 'high':
            priority = TaskPriority.high;
            break;
          case 'low':
            priority = TaskPriority.low;
            break;
          default:
            priority = TaskPriority.medium;
        }

        String? description = taskItem.description;
        if (taskItem.steps.isNotEmpty) {
          final stepsText = taskItem.steps
              .asMap()
              .entries
              .map((e) => '${e.key + 1}. ${e.value}')
              .join('\n');
          description = description.isEmpty
              ? stepsText
              : '$description\n\n$stepsText';
        }

        await taskNotifier.addTask(
          title: taskItem.title,
          description: description,
          pomodoroCount: taskItem.pomodoroCount,
          priority: priority,
          isAIGenerated: true,
          aiSessionId: aiSessionId,
          aiSessionTitle: aiSessionTitle,
        );

        await Future.delayed(const Duration(milliseconds: 10));
      }

      if (mounted) {
        SnackBarUtil.showSuccessSnackBar(
          context,
          message: l10n.tasksCreatedSuccess(_editablePlan.tasks.length),
        );

        // Pop twice (exit editor and chat screen)
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showErrorSnackBar(
          context,
          message: AppLocalizations.of(context)!.failedToCreateTasks,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}

/// Editable Task Card Widget
///
/// Responsibilities:
/// 1. Display information for a single task
/// 2. Support inline editing
/// 3. Handle deletion operations
class _EditableTaskCard extends StatefulWidget {
  final TaskPlanItem task;
  final int index;
  final ValueChanged<TaskPlanItem> onEdit;
  final VoidCallback onDelete;

  const _EditableTaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_EditableTaskCard> createState() => _EditableTaskCardState();
}

class _EditableTaskCardState extends State<_EditableTaskCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: ValueKey(widget.task.hashCode),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await DeleteConfirmationDialog.show(
              context,
              title: widget.task.title,
            ) ??
            false;
      },
      onDismissed: (direction) {
        widget.onDelete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              color: theme.colorScheme.onErrorContainer,
              size: 28,
            ),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task number badge
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      '${widget.index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and subtitle (expanded to take remaining space)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title - allows multi-line
                        TextFormField(
                          initialValue: widget.task.title,
                          maxLines: null, // Allow unlimited lines
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.taskTitle,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            widget.onEdit(widget.task.copyWith(title: value));
                          },
                        ),
                        const SizedBox(height: 4),
                        // Subtitle with pomodoro and priority
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildPomodoroEditor(theme, l10n),
                            _buildPrioritySelector(theme, l10n),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Action buttons - top aligned
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 22,
                          icon: Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                          ),
                          onPressed: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                        ),
                      ),
                      ReorderableDragStartListener(
                        index: widget.index,
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.drag_handle, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_isExpanded) _buildExpandedContent(theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildPomodoroEditor(ThemeData theme, AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_outlined,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () => _showPomodoroBottomSheet(theme, l10n),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.task.pomodoroCount}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          l10n.pomodoros,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showPomodoroBottomSheet(ThemeData theme, AppLocalizations l10n) {
    final initialIndex = widget.task.pomodoroCount - 1;
    int selectedValue = widget.task.pomodoroCount;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.estimatedPomodoros,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Wheel picker
                  SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        // Selection highlight
                        Center(
                          child: Container(
                            height: 50,
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        // Scrollable list
                        ListWheelScrollView.useDelegate(
                          controller: FixedExtentScrollController(
                            initialItem: initialIndex,
                          ),
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              selectedValue = index + 1;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= 20) return null;
                              final value = index + 1;
                              final isSelected = value == selectedValue;

                              return Center(
                                child: Text(
                                  '$value',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                      ),
                                ),
                              );
                            },
                            childCount: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Confirm button with emoji
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          widget.onEdit(
                            widget.task.copyWith(pomodoroCount: selectedValue),
                          );
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(l10n.confirm),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrioritySelector(ThemeData theme, AppLocalizations l10n) {
    final priority = widget.task.priority.toLowerCase();

    // Use PriorityUtils for DRY color mapping
    final bgColor = PriorityUtils.getBackgroundColor(
      priority,
      theme.colorScheme,
    );
    final fgColor = PriorityUtils.getForegroundColor(
      priority,
      theme.colorScheme,
    );

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _showPriorityBottomSheet(theme, l10n),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              priority == 'high'
                  ? l10n.priorityHigh
                  : priority == 'low'
                  ? l10n.priorityLow
                  : l10n.priorityMedium,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: fgColor),
          ],
        ),
      ),
    );
  }

  void _showPriorityBottomSheet(ThemeData theme, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Text(
                  l10n.priority,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Priority options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildPriorityOption(theme, l10n.priorityHigh, 'high'),
                    const SizedBox(height: 12),
                    _buildPriorityOption(theme, l10n.priorityMedium, 'medium'),
                    const SizedBox(height: 12),
                    _buildPriorityOption(theme, l10n.priorityLow, 'low'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriorityOption(ThemeData theme, String label, String value) {
    // Use PriorityUtils for DRY color mapping
    final bgColor = PriorityUtils.getBackgroundColor(value, theme.colorScheme);
    final fgColor = PriorityUtils.getForegroundColor(value, theme.colorScheme);
    final isSelected = widget.task.priority.toLowerCase() == value;

    return InkWell(
      onTap: () {
        widget.onEdit(widget.task.copyWith(priority: value));
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? bgColor
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: fgColor.withValues(alpha: 0.5), width: 2)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected ? fgColor : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: fgColor, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: widget.task.description,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.description,
              hintText: l10n.enterTaskDescription,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              widget.onEdit(widget.task.copyWith(description: value));
            },
          ),
        ],
      ),
    );
  }
}
