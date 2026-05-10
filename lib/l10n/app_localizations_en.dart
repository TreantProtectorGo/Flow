// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flow';

  @override
  String get taskPlan => 'Task Plan';

  @override
  String estimatedCompletionTime(String time) {
    return 'Estimated completion time: $time';
  }

  @override
  String get tasks => 'Tasks';

  @override
  String get timer => 'Timer';

  @override
  String get statistics => 'Statistics';

  @override
  String get settings => 'Settings';

  @override
  String get addTask => 'Add Task';

  @override
  String get editTask => 'Edit Task';

  @override
  String get deleteTask => 'Delete Task';

  @override
  String get update => 'Update';

  @override
  String get add => 'Add';

  @override
  String get taskTitle => 'Task Title';

  @override
  String get taskDescription => 'Task Description';

  @override
  String get taskDescriptionOptional => 'Task Description (Optional)';

  @override
  String get enterTaskTitle => 'Please enter task title';

  @override
  String get estimatedPomodoros => 'Estimated Pomodoros';

  @override
  String get estimated => 'Estimated';

  @override
  String get enterPomodoroCount => 'Please enter pomodoro count';

  @override
  String get pomodoroCountRange => 'Please enter a number between 1 and 20';

  @override
  String pomodoroCount(int count) {
    return '$count pomodoros';
  }

  @override
  String get priority => 'Priority';

  @override
  String get status => 'Status';

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String get dailyReminderTime => 'Reminder Time';

  @override
  String get dailyReminderHelper =>
      'Remind me every day until this task is completed';

  @override
  String get dailyReminderDisabledHelper =>
      'Turn on push notifications to use task reminders';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String get highPriority => 'High Priority';

  @override
  String get mediumPriority => 'Medium Priority';

  @override
  String get lowPriority => 'Low Priority';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get inProgress => 'In Progress';

  @override
  String get completed => 'Completed';

  @override
  String get noTasks => 'No Pending Tasks';

  @override
  String get noTasksMessage => 'No pending tasks';

  @override
  String get start => 'Start';

  @override
  String get continueButton => 'Continue';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get stop => 'Stop';

  @override
  String get reset => 'Reset';

  @override
  String get skip => 'Skip';

  @override
  String get focusTime => 'Focus Time';

  @override
  String get shortBreak => 'Short Break';

  @override
  String get longBreak => 'Long Break';

  @override
  String get breakTime => 'Break Time';

  @override
  String get pomodoroMode => 'Pomodoro';

  @override
  String get shortBreakMode => 'Short Break';

  @override
  String get longBreakMode => 'Long Break';

  @override
  String get selectTask => 'Select Task';

  @override
  String get clearSelection => 'Clear Selection';

  @override
  String get noAvailableTasks => 'No available tasks';

  @override
  String get addTasksFirst => 'Please add some tasks in the Tasks page first';

  @override
  String get noTaskSelected => 'No task selected';

  @override
  String get tapToSelect => 'Tap to select a task';

  @override
  String get currentTask => 'Current Task';

  @override
  String get switchTask => 'Switch';

  @override
  String completedSessions(int count) {
    return 'Completed $count focus sessions';
  }

  @override
  String startFocus(String taskTitle) {
    return 'Start Focus: $taskTitle';
  }

  @override
  String continueTask(String taskTitle) {
    return 'Continue Task: $taskTitle';
  }

  @override
  String get addToCalendar => 'Add to Calendar';

  @override
  String get addPlanToCalendar => 'Add Plan to Calendar';

  @override
  String calendarOpened(String taskTitle) {
    return 'Opened Calendar: $taskTitle';
  }

  @override
  String calendarAdded(String taskTitle) {
    return 'Added to Calendar: $taskTitle';
  }

  @override
  String get calendarAddCancelled => 'Calendar event creation cancelled';

  @override
  String get calendarAlreadyAdded => 'This plan was already added to Calendar';

  @override
  String get calendarAddFailed => 'Could not add to Calendar';

  @override
  String get addingToCalendar => 'Adding to Calendar...';

  @override
  String get reviewCalendarPlanTitle => 'Review Calendar Events';

  @override
  String get calendarScheduleModeLabel => 'Schedule Mode';

  @override
  String get calendarScheduleSingleDay => 'Single Day';

  @override
  String calendarScheduleSpreadDays(int count) {
    return 'Spread Across $count Days';
  }

  @override
  String get calendarStartDateLabel => 'Start Date';

  @override
  String get calendarStartTimeLabel => 'Start Time';

  @override
  String calendarEventsPreview(int count) {
    return '$count events will be created';
  }

  @override
  String addEventsToCalendar(int count) {
    return 'Add $count Events';
  }

  @override
  String taskAdded(String taskTitle) {
    return 'Task Added: $taskTitle';
  }

  @override
  String confirmDelete(String taskTitle) {
    return 'Are you sure you want to delete \"$taskTitle\"?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get edit => 'Edit';

  @override
  String get markComplete => 'Mark Complete';

  @override
  String get aiAnalysis => 'AI Analysis';

  @override
  String get aiBreakdownCard => 'Let AI Help Break Down Large Tasks';

  @override
  String get view => 'View';

  @override
  String timerRunning(String time) {
    return 'Timer Running $time';
  }

  @override
  String pomodoroCountText(int count) {
    return '$count Pomodoros';
  }

  @override
  String get aiTaskAnalysis => 'AI Task Analysis';

  @override
  String get taskName => 'Task Name';

  @override
  String get estimatedTime => 'Estimated Time';

  @override
  String get aiSuggestions => 'AI Suggestions';

  @override
  String get breakIntoSteps =>
      '• Break tasks into smaller steps to improve completion rate';

  @override
  String get takeBreaks =>
      '• Remember to take 5-minute breaks after each pomodoro';

  @override
  String get setClearStandards => '• Set clear completion criteria';

  @override
  String get highPrioritySuggestion =>
      '• High priority tasks should be handled first';

  @override
  String get longTaskSuggestion => '• Long tasks should be executed in stages';

  @override
  String minutesUnit(int count) {
    return '$count min';
  }

  @override
  String get todayStats => 'Today';

  @override
  String get weekStats => 'This Week';

  @override
  String get monthStats => 'This Month';

  @override
  String get streakDays => 'Focus Streak';

  @override
  String get days => 'days';

  @override
  String get completedToday => 'Completed Today';

  @override
  String get completedPomodoros => 'Completed Pomodoros';

  @override
  String get completedTasks => 'Completed Tasks';

  @override
  String get completionRate => 'Completion Rate';

  @override
  String get dailyAverage => 'Daily Average';

  @override
  String get progress => 'Progress';

  @override
  String get remaining => 'Remaining';

  @override
  String get completeOnePomodoroToStartStreak =>
      'Complete a pomodoro to start your streak!';

  @override
  String get startNewStreakToday => 'Start a new streak today!';

  @override
  String get goodStart => 'Good start!';

  @override
  String get keepGoing => 'Keep going!';

  @override
  String get awesome => 'Awesome!';

  @override
  String get focusMaster => 'You\'re a focus master!';

  @override
  String get legendaryStreak => 'Legendary streak!';

  @override
  String get todayGoal => 'Today\'s Goal';

  @override
  String get goalAchieved => 'Achieved';

  @override
  String get weekGoal => 'Weekly Goal';

  @override
  String get todayOverview => 'Today\'s Overview';

  @override
  String get weekOverview => 'Weekly Overview';

  @override
  String get monthOverview => 'Monthly Overview';

  @override
  String get todayTimeDistribution => 'Today\'s Time Distribution';

  @override
  String get weeklyTrend => 'Weekly Trend';

  @override
  String get incomplete => 'Incomplete';

  @override
  String get noPomodorosToday => 'No pomodoros completed today yet';

  @override
  String get noPomodorosThisWeek => 'No pomodoros completed this week yet';

  @override
  String get noPomodorosThisMonth => 'No pomodoros completed this month yet';

  @override
  String get pomodoros => 'pomodoros';

  @override
  String get dailyGoal => 'Daily Goal';

  @override
  String get weeklyGoal => 'Weekly Goal';

  @override
  String get focusHours => 'Focus Hours';

  @override
  String get pomodoroSettings => 'Pomodoro Settings';

  @override
  String get goalSettings => 'Goal Settings';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get appearanceSettings => 'Appearance Settings';

  @override
  String get aiSettings => 'AI Settings';

  @override
  String get dataAndSync => 'Data & Sync';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get focusDuration => 'Focus Duration';

  @override
  String get focusDurationSubtitle => 'Duration of each pomodoro session';

  @override
  String get shortBreakDuration => 'Short Break';

  @override
  String get shortBreakSubtitle => 'Break time after completing a pomodoro';

  @override
  String get longBreakDuration => 'Long Break';

  @override
  String get longBreakSubtitle => 'Break time after completing 4 pomodoros';

  @override
  String get longBreakFrequency => 'Long Break Frequency';

  @override
  String get longBreakFrequencySubtitle =>
      'Number of pomodoros before a long break';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String items(int count) {
    return '$count';
  }

  @override
  String get dailyGoalTitle => 'Daily Goal';

  @override
  String get dailyGoalSubtitle => 'Number of pomodoros to complete each day';

  @override
  String get weeklyGoalTitle => 'Weekly Goal';

  @override
  String get weeklyGoalSubtitle => 'Number of pomodoros to complete each week';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get pushNotificationsSubtitle => 'Send notification when timer ends';

  @override
  String get soundEffect => 'Sound Effect';

  @override
  String get soundEffectSubtitle => 'Choose sound when timer ends';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrationSubtitle => 'Vibrate when timer ends';

  @override
  String get defaultTaskReminder => 'Default Task Reminder';

  @override
  String get defaultTaskReminderSubtitle =>
      'Automatically turn on the daily reminder for the current session task';

  @override
  String get defaultTaskReminderTime => 'Default Task Reminder Time';

  @override
  String get defaultTaskReminderTimeSubtitle =>
      'Moves to the next unfinished task after the current one is completed';

  @override
  String get soundBell => 'Bell';

  @override
  String get soundBird => 'Bird';

  @override
  String get soundWave => 'Wave';

  @override
  String get soundNone => 'None';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeModeSubtitle => 'Choose app theme mode';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Choose app language';

  @override
  String get legalInformation => 'Legal';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle =>
      'View how Flow collects and uses your data';

  @override
  String get privacyPolicyOpenFailed => 'Could not open the privacy policy';

  @override
  String get aiTaskBreakdown => 'AI Task Breakdown';

  @override
  String get aiTaskBreakdownSubtitle =>
      'Allow AI to help break down complex tasks';

  @override
  String get smartSuggestions => 'Smart Suggestions';

  @override
  String get smartSuggestionsSubtitle =>
      'Get personalized suggestions based on habits';

  @override
  String get dataAnalysis => 'Data Analysis';

  @override
  String get dataAnalysisSubtitle => 'Allow data analysis to improve service';

  @override
  String get cloudSync => 'Cloud Sync';

  @override
  String get cloudSyncSubtitle => 'Automatically sync data to cloud';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportDataSubtitle => 'Download your statistics data';

  @override
  String get exportCSV => 'Export CSV';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get clearAllDataSubtitle => 'Delete all statistics and settings';

  @override
  String get clearData => 'Clear';

  @override
  String get deleteAccount => 'Delete';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete your account and all data';

  @override
  String get version => 'Flow v1.0.0';

  @override
  String get copyright => '© 2024 Flow Team';

  @override
  String get pending => 'To Do';

  @override
  String get activeTimer => 'Active Timer';

  @override
  String get focusingNow => 'Focusing Now';

  @override
  String get tapToViewTimer => 'Tap to view timer';

  @override
  String get emptyPendingTasks => 'No pending tasks';

  @override
  String get aiBreakdownDescription => 'Let AI help you break down big tasks';

  @override
  String get aiChatTitle => 'AI Assistant';

  @override
  String get thinking => 'Thinking...';

  @override
  String get clearConversation => 'Clear Conversation';

  @override
  String get newChat => 'New Chat';

  @override
  String get startNewChat => 'Start New Chat';

  @override
  String get confirmStartNewChat =>
      'Start a new chat? Current conversation will be cleared.';

  @override
  String get chatHistory => 'Chat History';

  @override
  String get noChatHistory => 'No chat history yet';

  @override
  String get confirmClearConversation =>
      'Are you sure you want to clear this chat?';

  @override
  String get clearConversationButton => 'Clear';

  @override
  String get sendMessage => 'Send message';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get askAiHelper => 'Ask AI Assistant...';

  @override
  String get creatingTasks => 'Creating...';

  @override
  String get createTasks => 'Create Tasks';

  @override
  String get editPlan => 'Edit Plan';

  @override
  String get createDirectly => 'Create';

  @override
  String get editTaskPlan => 'Edit Task Plan';

  @override
  String get saveAndCreate => 'Save & Create';

  @override
  String get creating => 'Creating...';

  @override
  String get mainGoal => 'Main Goal';

  @override
  String get enterMainGoal => 'Enter main goal';

  @override
  String totalTasks(int count) {
    return '$count tasks in total';
  }

  @override
  String totalPomodoros(int count) {
    return '$count pomodoros in total';
  }

  @override
  String get noTasksInPlan => 'No tasks in plan yet';

  @override
  String get newTask => 'New Task';

  @override
  String get mainGoalRequired => 'Main goal is required';

  @override
  String get atLeastOneTaskRequired => 'At least one task is required';

  @override
  String get enterTaskDescription => 'Enter task description';

  @override
  String get description => 'Description';

  @override
  String get cannotExtractTasks =>
      'Cannot extract tasks from conversation, please try to describe the tasks more clearly';

  @override
  String get aiResponseFailed => 'AI response failed';

  @override
  String tasksCreatedSuccess(int count) {
    return 'Successfully created $count tasks!';
  }

  @override
  String get failedToCreateTasks => 'Failed to create tasks';

  @override
  String taskCreationFailed(String error) {
    return 'Task creation failed: $error';
  }

  @override
  String confirmAction(String action) {
    return 'Confirm $action';
  }

  @override
  String confirmActionMessage(String action) {
    return 'Are you sure you want to $action? This action cannot be undone.';
  }

  @override
  String featureComingSoon(String action) {
    return '$action feature will be available in the official release';
  }

  @override
  String get hourShort => 'h';

  @override
  String get minuteShort => 'm';

  @override
  String get secondShort => 's';

  @override
  String get hour => 'hour';

  @override
  String get minute => 'minute';

  @override
  String get second => 'second';

  @override
  String get focusMode => 'Focus Time';

  @override
  String get thisWeekOverview => 'This Week Overview';

  @override
  String get thisMonthOverview => 'This Month Overview';

  @override
  String hours(String count) {
    return '$count hrs';
  }

  @override
  String get thisWeekGoal => 'This Week Goal';

  @override
  String get workDays => 'Active Days';

  @override
  String get bestDay => 'Best Day';

  @override
  String get monthlyHeatmap => 'Monthly Focus Heatmap';

  @override
  String get thisMonthTrend => 'This Month Trend';

  @override
  String get noPomodoros => 'No pomodoros completed today yet';

  @override
  String get thisWeekTrend => 'This Week Trend';

  @override
  String get noWeekStats => 'No statistics for this week yet';

  @override
  String get bestFocusTime => 'Best Focus Time (Last 30 Days)';

  @override
  String get noMonthStats => 'No statistics for this month yet';

  @override
  String count(int count) {
    return '$count';
  }

  @override
  String get consecutiveFocus => 'Consecutive Focus';

  @override
  String get notEnoughData => 'Not enough data yet';

  @override
  String get yourBestFocusTime => 'Your Best Focus Time';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';

  @override
  String get night => 'Night';

  @override
  String get morningTime => '6:00-12:00';

  @override
  String get afternoonTime => '12:00-18:00';

  @override
  String get eveningTime => '18:00-22:00';

  @override
  String get nightTime => '22:00-6:00';

  @override
  String completedPomodorosCount(int count) {
    return 'Completed $count pomodoros';
  }

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String get mondayShort => 'Mon';

  @override
  String get tuesdayShort => 'Tue';

  @override
  String get wednesdayShort => 'Wed';

  @override
  String get thursdayShort => 'Thu';

  @override
  String get fridayShort => 'Fri';

  @override
  String get saturdayShort => 'Sat';

  @override
  String get sundayShort => 'Sun';

  @override
  String pomodoroCountShort(int count) {
    return '$count pomodoros';
  }

  @override
  String get less => 'Less';

  @override
  String get more => 'More';

  @override
  String get helloAI => 'Hello! I\'m your AI assistant';

  @override
  String get aiDescription =>
      'I\'m your focus assistant, ready to help analyze tasks and provide suggestions';

  @override
  String get noTasksToSelect => 'No tasks available';

  @override
  String get pleaseAddTasksFirst => 'Please add some tasks first';

  @override
  String pomodoroProgress(int completed, int total) {
    return '$completed/$total';
  }

  @override
  String get breakdownWithAI => 'Break down with AI';

  @override
  String aiSessionGroup(int count) {
    return 'AI Session ($count tasks)';
  }

  @override
  String get aiSessionToggleHint => 'Tap to expand or collapse';

  @override
  String get notificationFocusCompleteTitle => 'Focus Time Complete';

  @override
  String get notificationFocusCompleteBody =>
      'Focus session complete. Time for a break!';

  @override
  String notificationFocusCompleteWithTask(String taskTitle) {
    return 'Focus session for \"$taskTitle\" complete. Time for a break!';
  }

  @override
  String get notificationBreakCompleteTitle => 'Break Complete';

  @override
  String get notificationLongBreakCompleteTitle => 'Long Break Complete';

  @override
  String get notificationBreakCompleteBody => 'Ready to focus again?';

  @override
  String get notificationChannelName => 'Timer Notifications';

  @override
  String get notificationChannelDescription =>
      'Pomodoro timer completion notifications';

  @override
  String get notificationTaskCompleteTitle => 'Task Complete!';

  @override
  String notificationTaskCompleteBody(String taskTitle) {
    return 'All pomodoros for \"$taskTitle\" have been completed';
  }

  @override
  String get notificationTaskReminderTitle => 'Time to work';

  @override
  String notificationTaskReminderBody(String taskTitle) {
    return 'Reminder: \"$taskTitle\" is waiting for you';
  }

  @override
  String get notificationTaskReminderChannelName => 'Task Reminders';

  @override
  String get notificationTaskReminderChannelDescription =>
      'Daily reminders for pending tasks';

  @override
  String notificationPomodoroFocusCompleteTitle(int completed, int total) {
    return 'Pomodoro $completed/$total complete';
  }

  @override
  String notificationPomodoroStartBreakBody(String breakName) {
    return 'Start $breakName';
  }

  @override
  String notificationPomodoroBreakCompleteTitle(String breakName) {
    return '$breakName complete';
  }

  @override
  String notificationPomodoroStartFocusBody(int pomodoroIndex) {
    return 'Start pomodoro $pomodoroIndex';
  }

  @override
  String notificationPomodoroNextTaskBody(String nextTaskTitle) {
    return 'Ready to start \"$nextTaskTitle\"?';
  }

  @override
  String get startNextTaskTitle => 'Start next task?';

  @override
  String startNextTaskMessage(String completedTaskTitle, String nextTaskTitle) {
    return '\"$completedTaskTitle\" is complete. Start \"$nextTaskTitle\" now?';
  }

  @override
  String taskCelebrationMessage(String taskTitle) {
    return '\"$taskTitle\" completed. Nice work.';
  }

  @override
  String get signInToEnableSync => 'Sign in to enable cloud sync';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get defaultAccountName => 'Flow User';

  @override
  String get signOut => 'Sign Out';

  @override
  String lastSynced(String time) {
    return 'Last synced: $time';
  }

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncing => 'Syncing…';

  @override
  String get syncError => 'Sync failed';

  @override
  String get signInFailed => 'Sign-in failed. Please try again.';

  @override
  String get signOutConfirmTitle => 'Confirm Sign Out';

  @override
  String get signOutConfirmMessage =>
      'Cloud sync will stop after signing out. Local data will not be deleted.';

  @override
  String get accountSection => 'Account';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get clearDataSuccess => 'All data cleared';

  @override
  String get clearDataFailed => 'Failed to clear data. Please try again.';

  @override
  String get manualAdd => 'Manual Add';

  @override
  String get describeTaskForAI => 'Describe Task for AI';

  @override
  String get aiGoal => 'Goal (what you want to achieve)';

  @override
  String get aiGoalRequired => 'Please enter a goal';

  @override
  String get aiDeadline => 'Deadline / Time limit (optional)';

  @override
  String get aiConstraints => 'Constraints (optional)';

  @override
  String get generatePlan => 'Generate Plan';

  @override
  String get chatWithAI => 'Chat with AI';

  @override
  String get aiPromptIntro =>
      'Please break down this task into actionable steps:';

  @override
  String get aiPromptOutputStyle =>
      'Please return concrete steps, estimated pomodoros for each step, and suggested priority order.';
}
