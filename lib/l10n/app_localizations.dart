import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// 應用程式標題
  ///
  /// In zh, this message translates to:
  /// **'Flow'**
  String get appTitle;

  /// No description provided for @taskPlan.
  ///
  /// In zh, this message translates to:
  /// **'任务计划'**
  String get taskPlan;

  /// No description provided for @estimatedCompletionTime.
  ///
  /// In zh, this message translates to:
  /// **'预估完成时间：{time}'**
  String estimatedCompletionTime(String time);

  /// No description provided for @tasks.
  ///
  /// In zh, this message translates to:
  /// **'任務'**
  String get tasks;

  /// No description provided for @timer.
  ///
  /// In zh, this message translates to:
  /// **'計時器'**
  String get timer;

  /// No description provided for @statistics.
  ///
  /// In zh, this message translates to:
  /// **'統計'**
  String get statistics;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @addTask.
  ///
  /// In zh, this message translates to:
  /// **'新增任務'**
  String get addTask;

  /// No description provided for @editTask.
  ///
  /// In zh, this message translates to:
  /// **'編輯任務'**
  String get editTask;

  /// No description provided for @deleteTask.
  ///
  /// In zh, this message translates to:
  /// **'刪除任務'**
  String get deleteTask;

  /// No description provided for @update.
  ///
  /// In zh, this message translates to:
  /// **'更新'**
  String get update;

  /// No description provided for @add.
  ///
  /// In zh, this message translates to:
  /// **'新增'**
  String get add;

  /// No description provided for @taskTitle.
  ///
  /// In zh, this message translates to:
  /// **'任務標題'**
  String get taskTitle;

  /// No description provided for @taskDescription.
  ///
  /// In zh, this message translates to:
  /// **'任務描述'**
  String get taskDescription;

  /// No description provided for @taskDescriptionOptional.
  ///
  /// In zh, this message translates to:
  /// **'任務描述（選填）'**
  String get taskDescriptionOptional;

  /// No description provided for @enterTaskTitle.
  ///
  /// In zh, this message translates to:
  /// **'請輸入任務標題'**
  String get enterTaskTitle;

  /// No description provided for @estimatedPomodoros.
  ///
  /// In zh, this message translates to:
  /// **'預估番茄鐘數量'**
  String get estimatedPomodoros;

  /// No description provided for @estimated.
  ///
  /// In zh, this message translates to:
  /// **'預估'**
  String get estimated;

  /// No description provided for @enterPomodoroCount.
  ///
  /// In zh, this message translates to:
  /// **'請輸入番茄鐘數量'**
  String get enterPomodoroCount;

  /// No description provided for @pomodoroCountRange.
  ///
  /// In zh, this message translates to:
  /// **'請輸入 1 到 20 之間的數字'**
  String get pomodoroCountRange;

  /// No description provided for @pomodoroCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 個番茄鐘'**
  String pomodoroCount(int count);

  /// No description provided for @priority.
  ///
  /// In zh, this message translates to:
  /// **'優先級'**
  String get priority;

  /// No description provided for @status.
  ///
  /// In zh, this message translates to:
  /// **'狀態'**
  String get status;

  /// No description provided for @dailyReminder.
  ///
  /// In zh, this message translates to:
  /// **'每日提醒'**
  String get dailyReminder;

  /// No description provided for @dailyReminderTime.
  ///
  /// In zh, this message translates to:
  /// **'提醒時間'**
  String get dailyReminderTime;

  /// No description provided for @dailyReminderHelper.
  ///
  /// In zh, this message translates to:
  /// **'在任務完成前，每天於指定時間提醒我'**
  String get dailyReminderHelper;

  /// No description provided for @dailyReminderDisabledHelper.
  ///
  /// In zh, this message translates to:
  /// **'請先開啟推播通知，才能使用任務提醒'**
  String get dailyReminderDisabledHelper;

  /// No description provided for @priorityHigh.
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In zh, this message translates to:
  /// **'低'**
  String get priorityLow;

  /// No description provided for @highPriority.
  ///
  /// In zh, this message translates to:
  /// **'高優先級'**
  String get highPriority;

  /// No description provided for @mediumPriority.
  ///
  /// In zh, this message translates to:
  /// **'中優先級'**
  String get mediumPriority;

  /// No description provided for @lowPriority.
  ///
  /// In zh, this message translates to:
  /// **'低優先級'**
  String get lowPriority;

  /// No description provided for @statusPending.
  ///
  /// In zh, this message translates to:
  /// **'待辦'**
  String get statusPending;

  /// No description provided for @statusInProgress.
  ///
  /// In zh, this message translates to:
  /// **'進行中'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get statusCompleted;

  /// No description provided for @inProgress.
  ///
  /// In zh, this message translates to:
  /// **'進行中'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get completed;

  /// No description provided for @noTasks.
  ///
  /// In zh, this message translates to:
  /// **'暫無待辦任務'**
  String get noTasks;

  /// No description provided for @noTasksMessage.
  ///
  /// In zh, this message translates to:
  /// **'暫無待辦任務'**
  String get noTasksMessage;

  /// No description provided for @start.
  ///
  /// In zh, this message translates to:
  /// **'開始'**
  String get start;

  /// No description provided for @continueButton.
  ///
  /// In zh, this message translates to:
  /// **'繼續'**
  String get continueButton;

  /// No description provided for @pause.
  ///
  /// In zh, this message translates to:
  /// **'暫停'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In zh, this message translates to:
  /// **'繼續'**
  String get resume;

  /// No description provided for @stop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stop;

  /// No description provided for @reset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get reset;

  /// No description provided for @skip.
  ///
  /// In zh, this message translates to:
  /// **'跳過'**
  String get skip;

  /// No description provided for @focusTime.
  ///
  /// In zh, this message translates to:
  /// **'專注時間'**
  String get focusTime;

  /// No description provided for @shortBreak.
  ///
  /// In zh, this message translates to:
  /// **'短休息'**
  String get shortBreak;

  /// No description provided for @longBreak.
  ///
  /// In zh, this message translates to:
  /// **'長休息'**
  String get longBreak;

  /// No description provided for @breakTime.
  ///
  /// In zh, this message translates to:
  /// **'休息時間'**
  String get breakTime;

  /// No description provided for @pomodoroMode.
  ///
  /// In zh, this message translates to:
  /// **'番茄鐘'**
  String get pomodoroMode;

  /// No description provided for @shortBreakMode.
  ///
  /// In zh, this message translates to:
  /// **'短休息'**
  String get shortBreakMode;

  /// No description provided for @longBreakMode.
  ///
  /// In zh, this message translates to:
  /// **'長休息'**
  String get longBreakMode;

  /// No description provided for @selectTask.
  ///
  /// In zh, this message translates to:
  /// **'選擇任務'**
  String get selectTask;

  /// No description provided for @clearSelection.
  ///
  /// In zh, this message translates to:
  /// **'清除選擇'**
  String get clearSelection;

  /// No description provided for @noAvailableTasks.
  ///
  /// In zh, this message translates to:
  /// **'暫無可選擇的任務'**
  String get noAvailableTasks;

  /// No description provided for @addTasksFirst.
  ///
  /// In zh, this message translates to:
  /// **'請先在任務頁面添加一些任務'**
  String get addTasksFirst;

  /// No description provided for @noTaskSelected.
  ///
  /// In zh, this message translates to:
  /// **'尚未選擇任務'**
  String get noTaskSelected;

  /// No description provided for @tapToSelect.
  ///
  /// In zh, this message translates to:
  /// **'點擊選擇任務'**
  String get tapToSelect;

  /// No description provided for @currentTask.
  ///
  /// In zh, this message translates to:
  /// **'當前任務'**
  String get currentTask;

  /// No description provided for @switchTask.
  ///
  /// In zh, this message translates to:
  /// **'切換'**
  String get switchTask;

  /// No description provided for @completedSessions.
  ///
  /// In zh, this message translates to:
  /// **'已完成 {count} 個專注時段'**
  String completedSessions(int count);

  /// 開始專注任務的訊息
  ///
  /// In zh, this message translates to:
  /// **'開始專注：{taskTitle}'**
  String startFocus(String taskTitle);

  /// No description provided for @continueTask.
  ///
  /// In zh, this message translates to:
  /// **'繼續任務：{taskTitle}'**
  String continueTask(String taskTitle);

  /// No description provided for @addToCalendar.
  ///
  /// In zh, this message translates to:
  /// **'加入行事曆'**
  String get addToCalendar;

  /// No description provided for @addPlanToCalendar.
  ///
  /// In zh, this message translates to:
  /// **'将计划加入行事历'**
  String get addPlanToCalendar;

  /// No description provided for @calendarOpened.
  ///
  /// In zh, this message translates to:
  /// **'已打开行事历：{taskTitle}'**
  String calendarOpened(String taskTitle);

  /// No description provided for @calendarAdded.
  ///
  /// In zh, this message translates to:
  /// **'已加入行事曆：{taskTitle}'**
  String calendarAdded(String taskTitle);

  /// No description provided for @calendarAddCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消建立行事曆事件'**
  String get calendarAddCancelled;

  /// No description provided for @calendarAlreadyAdded.
  ///
  /// In zh, this message translates to:
  /// **'這個計劃已加入行事曆'**
  String get calendarAlreadyAdded;

  /// No description provided for @calendarAddFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法加入行事曆'**
  String get calendarAddFailed;

  /// No description provided for @addingToCalendar.
  ///
  /// In zh, this message translates to:
  /// **'正在加入行事曆...'**
  String get addingToCalendar;

  /// No description provided for @reviewCalendarPlanTitle.
  ///
  /// In zh, this message translates to:
  /// **'確認行事曆事件'**
  String get reviewCalendarPlanTitle;

  /// No description provided for @calendarScheduleModeLabel.
  ///
  /// In zh, this message translates to:
  /// **'排程方式'**
  String get calendarScheduleModeLabel;

  /// No description provided for @calendarScheduleSingleDay.
  ///
  /// In zh, this message translates to:
  /// **'同一天'**
  String get calendarScheduleSingleDay;

  /// No description provided for @calendarScheduleSpreadDays.
  ///
  /// In zh, this message translates to:
  /// **'分散在 {count} 天'**
  String calendarScheduleSpreadDays(int count);

  /// No description provided for @calendarStartDateLabel.
  ///
  /// In zh, this message translates to:
  /// **'開始日期'**
  String get calendarStartDateLabel;

  /// No description provided for @calendarStartTimeLabel.
  ///
  /// In zh, this message translates to:
  /// **'開始時間'**
  String get calendarStartTimeLabel;

  /// No description provided for @calendarEventsPreview.
  ///
  /// In zh, this message translates to:
  /// **'將建立 {count} 個事件'**
  String calendarEventsPreview(int count);

  /// No description provided for @addEventsToCalendar.
  ///
  /// In zh, this message translates to:
  /// **'加入 {count} 個事件'**
  String addEventsToCalendar(int count);

  /// No description provided for @taskAdded.
  ///
  /// In zh, this message translates to:
  /// **'已新增任務：{taskTitle}'**
  String taskAdded(String taskTitle);

  /// No description provided for @confirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'確定要刪除「{taskTitle}」嗎？'**
  String confirmDelete(String taskTitle);

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'刪除'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'儲存'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'確定'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'關閉'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重試'**
  String get retry;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'編輯'**
  String get edit;

  /// No description provided for @markComplete.
  ///
  /// In zh, this message translates to:
  /// **'標記完成'**
  String get markComplete;

  /// No description provided for @aiAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'AI 分析'**
  String get aiAnalysis;

  /// No description provided for @aiBreakdownCard.
  ///
  /// In zh, this message translates to:
  /// **'讓 AI 幫你拆解大任務'**
  String get aiBreakdownCard;

  /// No description provided for @view.
  ///
  /// In zh, this message translates to:
  /// **'查看'**
  String get view;

  /// No description provided for @timerRunning.
  ///
  /// In zh, this message translates to:
  /// **'計時中 {time}'**
  String timerRunning(String time);

  /// No description provided for @pomodoroCountText.
  ///
  /// In zh, this message translates to:
  /// **'{count} 個番茄鐘'**
  String pomodoroCountText(int count);

  /// No description provided for @aiTaskAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'AI 任務分析'**
  String get aiTaskAnalysis;

  /// No description provided for @taskName.
  ///
  /// In zh, this message translates to:
  /// **'任務名稱'**
  String get taskName;

  /// No description provided for @estimatedTime.
  ///
  /// In zh, this message translates to:
  /// **'預估時間'**
  String get estimatedTime;

  /// No description provided for @aiSuggestions.
  ///
  /// In zh, this message translates to:
  /// **'AI 建議'**
  String get aiSuggestions;

  /// No description provided for @breakIntoSteps.
  ///
  /// In zh, this message translates to:
  /// **'• 將任務分成小步驟以提高完成率'**
  String get breakIntoSteps;

  /// No description provided for @takeBreaks.
  ///
  /// In zh, this message translates to:
  /// **'• 每個番茄鐘後記得休息 5 分鐘'**
  String get takeBreaks;

  /// No description provided for @setClearStandards.
  ///
  /// In zh, this message translates to:
  /// **'• 設定明確的完成標準'**
  String get setClearStandards;

  /// No description provided for @highPrioritySuggestion.
  ///
  /// In zh, this message translates to:
  /// **'• 高優先級任務建議優先處理'**
  String get highPrioritySuggestion;

  /// No description provided for @longTaskSuggestion.
  ///
  /// In zh, this message translates to:
  /// **'• 長時間任務建議分階段執行'**
  String get longTaskSuggestion;

  /// No description provided for @minutesUnit.
  ///
  /// In zh, this message translates to:
  /// **'{count} 分鐘'**
  String minutesUnit(int count);

  /// No description provided for @todayStats.
  ///
  /// In zh, this message translates to:
  /// **'今日'**
  String get todayStats;

  /// No description provided for @weekStats.
  ///
  /// In zh, this message translates to:
  /// **'本週'**
  String get weekStats;

  /// No description provided for @monthStats.
  ///
  /// In zh, this message translates to:
  /// **'本月'**
  String get monthStats;

  /// No description provided for @streakDays.
  ///
  /// In zh, this message translates to:
  /// **'連續天數'**
  String get streakDays;

  /// No description provided for @days.
  ///
  /// In zh, this message translates to:
  /// **'天'**
  String get days;

  /// No description provided for @completedToday.
  ///
  /// In zh, this message translates to:
  /// **'今日完成'**
  String get completedToday;

  /// No description provided for @completedPomodoros.
  ///
  /// In zh, this message translates to:
  /// **'完成番茄鐘'**
  String get completedPomodoros;

  /// No description provided for @completedTasks.
  ///
  /// In zh, this message translates to:
  /// **'完成任務'**
  String get completedTasks;

  /// No description provided for @completionRate.
  ///
  /// In zh, this message translates to:
  /// **'完成率'**
  String get completionRate;

  /// No description provided for @dailyAverage.
  ///
  /// In zh, this message translates to:
  /// **'日均完成'**
  String get dailyAverage;

  /// No description provided for @progress.
  ///
  /// In zh, this message translates to:
  /// **'進度'**
  String get progress;

  /// No description provided for @remaining.
  ///
  /// In zh, this message translates to:
  /// **'還需'**
  String get remaining;

  /// No description provided for @completeOnePomodoroToStartStreak.
  ///
  /// In zh, this message translates to:
  /// **'完成一個番茄鐘開始連續！'**
  String get completeOnePomodoroToStartStreak;

  /// No description provided for @startNewStreakToday.
  ///
  /// In zh, this message translates to:
  /// **'今天開始新的連續記錄！'**
  String get startNewStreakToday;

  /// No description provided for @goodStart.
  ///
  /// In zh, this message translates to:
  /// **'好的開始！'**
  String get goodStart;

  /// No description provided for @keepGoing.
  ///
  /// In zh, this message translates to:
  /// **'繼續保持！'**
  String get keepGoing;

  /// No description provided for @awesome.
  ///
  /// In zh, this message translates to:
  /// **'太棒了！'**
  String get awesome;

  /// No description provided for @focusMaster.
  ///
  /// In zh, this message translates to:
  /// **'你是專注大師！'**
  String get focusMaster;

  /// No description provided for @legendaryStreak.
  ///
  /// In zh, this message translates to:
  /// **'傳奇級連續記錄！'**
  String get legendaryStreak;

  /// No description provided for @todayGoal.
  ///
  /// In zh, this message translates to:
  /// **'今日目標'**
  String get todayGoal;

  /// No description provided for @goalAchieved.
  ///
  /// In zh, this message translates to:
  /// **'達成'**
  String get goalAchieved;

  /// No description provided for @weekGoal.
  ///
  /// In zh, this message translates to:
  /// **'本週目標'**
  String get weekGoal;

  /// No description provided for @todayOverview.
  ///
  /// In zh, this message translates to:
  /// **'今日概覽'**
  String get todayOverview;

  /// No description provided for @weekOverview.
  ///
  /// In zh, this message translates to:
  /// **'本週概覽'**
  String get weekOverview;

  /// No description provided for @monthOverview.
  ///
  /// In zh, this message translates to:
  /// **'本月概覽'**
  String get monthOverview;

  /// No description provided for @todayTimeDistribution.
  ///
  /// In zh, this message translates to:
  /// **'今日時間分布'**
  String get todayTimeDistribution;

  /// No description provided for @weeklyTrend.
  ///
  /// In zh, this message translates to:
  /// **'本週趨勢'**
  String get weeklyTrend;

  /// No description provided for @incomplete.
  ///
  /// In zh, this message translates to:
  /// **'未完成'**
  String get incomplete;

  /// No description provided for @noPomodorosToday.
  ///
  /// In zh, this message translates to:
  /// **'今天還沒有完成任何番茄鐘'**
  String get noPomodorosToday;

  /// No description provided for @noPomodorosThisWeek.
  ///
  /// In zh, this message translates to:
  /// **'本週還沒有完成任何番茄鐘'**
  String get noPomodorosThisWeek;

  /// No description provided for @noPomodorosThisMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月還沒有完成任何番茄鐘'**
  String get noPomodorosThisMonth;

  /// No description provided for @pomodoros.
  ///
  /// In zh, this message translates to:
  /// **'個番茄鐘'**
  String get pomodoros;

  /// No description provided for @dailyGoal.
  ///
  /// In zh, this message translates to:
  /// **'每日目標'**
  String get dailyGoal;

  /// No description provided for @weeklyGoal.
  ///
  /// In zh, this message translates to:
  /// **'每週目標'**
  String get weeklyGoal;

  /// No description provided for @focusHours.
  ///
  /// In zh, this message translates to:
  /// **'專注時數'**
  String get focusHours;

  /// No description provided for @pomodoroSettings.
  ///
  /// In zh, this message translates to:
  /// **'番茄鐘設定'**
  String get pomodoroSettings;

  /// No description provided for @goalSettings.
  ///
  /// In zh, this message translates to:
  /// **'目標設定'**
  String get goalSettings;

  /// No description provided for @notificationSettings.
  ///
  /// In zh, this message translates to:
  /// **'通知設定'**
  String get notificationSettings;

  /// No description provided for @appearanceSettings.
  ///
  /// In zh, this message translates to:
  /// **'外觀設定'**
  String get appearanceSettings;

  /// No description provided for @aiSettings.
  ///
  /// In zh, this message translates to:
  /// **'AI 設定'**
  String get aiSettings;

  /// No description provided for @dataAndSync.
  ///
  /// In zh, this message translates to:
  /// **'數據與同步'**
  String get dataAndSync;

  /// No description provided for @dangerZone.
  ///
  /// In zh, this message translates to:
  /// **'危險區域'**
  String get dangerZone;

  /// No description provided for @focusDuration.
  ///
  /// In zh, this message translates to:
  /// **'專注時間'**
  String get focusDuration;

  /// No description provided for @focusDurationSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'每個番茄鐘的專注時長'**
  String get focusDurationSubtitle;

  /// No description provided for @shortBreakDuration.
  ///
  /// In zh, this message translates to:
  /// **'短休息'**
  String get shortBreakDuration;

  /// No description provided for @shortBreakSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'完成一個番茄鐘後的休息時間'**
  String get shortBreakSubtitle;

  /// No description provided for @longBreakDuration.
  ///
  /// In zh, this message translates to:
  /// **'長休息'**
  String get longBreakDuration;

  /// No description provided for @longBreakSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'完成4個番茄鐘後的休息時間'**
  String get longBreakSubtitle;

  /// No description provided for @longBreakFrequency.
  ///
  /// In zh, this message translates to:
  /// **'長休息頻率'**
  String get longBreakFrequency;

  /// No description provided for @longBreakFrequencySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'每幾個番茄鐘後進行長休息'**
  String get longBreakFrequencySubtitle;

  /// No description provided for @minutes.
  ///
  /// In zh, this message translates to:
  /// **'{count} 分鐘'**
  String minutes(int count);

  /// No description provided for @items.
  ///
  /// In zh, this message translates to:
  /// **'個'**
  String items(int count);

  /// No description provided for @dailyGoalTitle.
  ///
  /// In zh, this message translates to:
  /// **'每日目標'**
  String get dailyGoalTitle;

  /// No description provided for @dailyGoalSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'每天想要完成的番茄鐘數量'**
  String get dailyGoalSubtitle;

  /// No description provided for @weeklyGoalTitle.
  ///
  /// In zh, this message translates to:
  /// **'每週目標'**
  String get weeklyGoalTitle;

  /// No description provided for @weeklyGoalSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'每週想要完成的番茄鐘數量'**
  String get weeklyGoalSubtitle;

  /// No description provided for @pushNotifications.
  ///
  /// In zh, this message translates to:
  /// **'推播通知'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'時間結束時發送通知'**
  String get pushNotificationsSubtitle;

  /// No description provided for @soundEffect.
  ///
  /// In zh, this message translates to:
  /// **'提示音效'**
  String get soundEffect;

  /// No description provided for @soundEffectSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'選擇計時器結束時的音效'**
  String get soundEffectSubtitle;

  /// No description provided for @vibration.
  ///
  /// In zh, this message translates to:
  /// **'震動提醒'**
  String get vibration;

  /// No description provided for @vibrationSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'時間結束時震動提醒'**
  String get vibrationSubtitle;

  /// No description provided for @defaultTaskReminder.
  ///
  /// In zh, this message translates to:
  /// **'預設任務提醒'**
  String get defaultTaskReminder;

  /// No description provided for @defaultTaskReminderSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'自動為目前 session 任務開啟每日提醒'**
  String get defaultTaskReminderSubtitle;

  /// No description provided for @defaultTaskReminderTime.
  ///
  /// In zh, this message translates to:
  /// **'預設任務提醒時間'**
  String get defaultTaskReminderTime;

  /// No description provided for @defaultTaskReminderTimeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'完成目前任務後，會自動移到下一個未完成任務'**
  String get defaultTaskReminderTimeSubtitle;

  /// No description provided for @soundBell.
  ///
  /// In zh, this message translates to:
  /// **'鈴鐺'**
  String get soundBell;

  /// No description provided for @soundBird.
  ///
  /// In zh, this message translates to:
  /// **'鳥鳴'**
  String get soundBird;

  /// No description provided for @soundWave.
  ///
  /// In zh, this message translates to:
  /// **'海浪'**
  String get soundWave;

  /// No description provided for @soundNone.
  ///
  /// In zh, this message translates to:
  /// **'無音效'**
  String get soundNone;

  /// No description provided for @themeMode.
  ///
  /// In zh, this message translates to:
  /// **'主題模式'**
  String get themeMode;

  /// No description provided for @themeModeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'選擇應用程式的主題模式'**
  String get themeModeSubtitle;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟隨系統'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'淺色模式'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'語言'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'選擇應用程式語言'**
  String get languageSubtitle;

  /// No description provided for @legalInformation.
  ///
  /// In zh, this message translates to:
  /// **'法律資訊'**
  String get legalInformation;

  /// No description provided for @privacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隱私權政策'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看 Flow 如何蒐集與使用您的資料'**
  String get privacyPolicySubtitle;

  /// No description provided for @privacyPolicyOpenFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法開啟隱私權政策'**
  String get privacyPolicyOpenFailed;

  /// No description provided for @aiTaskBreakdown.
  ///
  /// In zh, this message translates to:
  /// **'AI 任務拆解'**
  String get aiTaskBreakdown;

  /// No description provided for @aiTaskBreakdownSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'允許 AI 幫助拆解複雜任務'**
  String get aiTaskBreakdownSubtitle;

  /// No description provided for @smartSuggestions.
  ///
  /// In zh, this message translates to:
  /// **'智慧建議'**
  String get smartSuggestions;

  /// No description provided for @smartSuggestionsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'根據使用習慣提供個人化建議'**
  String get smartSuggestionsSubtitle;

  /// No description provided for @dataAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'數據分析'**
  String get dataAnalysis;

  /// No description provided for @dataAnalysisSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'允許分析使用數據以改善服務'**
  String get dataAnalysisSubtitle;

  /// No description provided for @cloudSync.
  ///
  /// In zh, this message translates to:
  /// **'雲端同步'**
  String get cloudSync;

  /// No description provided for @cloudSyncSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'自動同步數據到雲端'**
  String get cloudSyncSubtitle;

  /// No description provided for @exportData.
  ///
  /// In zh, this message translates to:
  /// **'匯出數據'**
  String get exportData;

  /// No description provided for @exportDataSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'下載您的統計數據'**
  String get exportDataSubtitle;

  /// No description provided for @exportCSV.
  ///
  /// In zh, this message translates to:
  /// **'匯出 CSV'**
  String get exportCSV;

  /// No description provided for @clearAllData.
  ///
  /// In zh, this message translates to:
  /// **'清除所有數據'**
  String get clearAllData;

  /// No description provided for @clearAllDataSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'刪除所有統計數據和設定'**
  String get clearAllDataSubtitle;

  /// No description provided for @clearData.
  ///
  /// In zh, this message translates to:
  /// **'清除數據'**
  String get clearData;

  /// No description provided for @deleteAccount.
  ///
  /// In zh, this message translates to:
  /// **'刪除帳號'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'永久刪除您的帳號和所有資料'**
  String get deleteAccountSubtitle;

  /// No description provided for @version.
  ///
  /// In zh, this message translates to:
  /// **'Flow v1.0.0'**
  String get version;

  /// No description provided for @copyright.
  ///
  /// In zh, this message translates to:
  /// **'© 2024 Flow Team'**
  String get copyright;

  /// No description provided for @pending.
  ///
  /// In zh, this message translates to:
  /// **'待辦事項'**
  String get pending;

  /// No description provided for @activeTimer.
  ///
  /// In zh, this message translates to:
  /// **'進行中的計時'**
  String get activeTimer;

  /// No description provided for @focusingNow.
  ///
  /// In zh, this message translates to:
  /// **'正在專注'**
  String get focusingNow;

  /// No description provided for @tapToViewTimer.
  ///
  /// In zh, this message translates to:
  /// **'點擊查看計時器'**
  String get tapToViewTimer;

  /// No description provided for @emptyPendingTasks.
  ///
  /// In zh, this message translates to:
  /// **'暫無待辦任務'**
  String get emptyPendingTasks;

  /// No description provided for @aiBreakdownDescription.
  ///
  /// In zh, this message translates to:
  /// **'讓 AI 幫你拆解大任務'**
  String get aiBreakdownDescription;

  /// No description provided for @aiChatTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 助手'**
  String get aiChatTitle;

  /// No description provided for @thinking.
  ///
  /// In zh, this message translates to:
  /// **'正在思考...'**
  String get thinking;

  /// No description provided for @clearConversation.
  ///
  /// In zh, this message translates to:
  /// **'清空對話'**
  String get clearConversation;

  /// No description provided for @newChat.
  ///
  /// In zh, this message translates to:
  /// **'新對話'**
  String get newChat;

  /// No description provided for @startNewChat.
  ///
  /// In zh, this message translates to:
  /// **'開始新對話'**
  String get startNewChat;

  /// No description provided for @confirmStartNewChat.
  ///
  /// In zh, this message translates to:
  /// **'要開始新對話嗎？目前對話會被清空。'**
  String get confirmStartNewChat;

  /// No description provided for @chatHistory.
  ///
  /// In zh, this message translates to:
  /// **'對話紀錄'**
  String get chatHistory;

  /// No description provided for @noChatHistory.
  ///
  /// In zh, this message translates to:
  /// **'目前沒有對話紀錄'**
  String get noChatHistory;

  /// No description provided for @confirmClearConversation.
  ///
  /// In zh, this message translates to:
  /// **'確定要清空目前這個對話嗎？'**
  String get confirmClearConversation;

  /// No description provided for @clearConversationButton.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get clearConversationButton;

  /// No description provided for @sendMessage.
  ///
  /// In zh, this message translates to:
  /// **'發送訊息'**
  String get sendMessage;

  /// No description provided for @typeMessage.
  ///
  /// In zh, this message translates to:
  /// **'輸入訊息...'**
  String get typeMessage;

  /// No description provided for @askAiHelper.
  ///
  /// In zh, this message translates to:
  /// **'問問 AI 助手...'**
  String get askAiHelper;

  /// No description provided for @creatingTasks.
  ///
  /// In zh, this message translates to:
  /// **'正在創建...'**
  String get creatingTasks;

  /// No description provided for @createTasks.
  ///
  /// In zh, this message translates to:
  /// **'創建任務'**
  String get createTasks;

  /// No description provided for @editPlan.
  ///
  /// In zh, this message translates to:
  /// **'編輯計畫'**
  String get editPlan;

  /// No description provided for @createDirectly.
  ///
  /// In zh, this message translates to:
  /// **'直接創建'**
  String get createDirectly;

  /// No description provided for @editTaskPlan.
  ///
  /// In zh, this message translates to:
  /// **'編輯任務計畫'**
  String get editTaskPlan;

  /// No description provided for @saveAndCreate.
  ///
  /// In zh, this message translates to:
  /// **'儲存並創建'**
  String get saveAndCreate;

  /// No description provided for @creating.
  ///
  /// In zh, this message translates to:
  /// **'創建中...'**
  String get creating;

  /// No description provided for @mainGoal.
  ///
  /// In zh, this message translates to:
  /// **'主要目標'**
  String get mainGoal;

  /// No description provided for @enterMainGoal.
  ///
  /// In zh, this message translates to:
  /// **'輸入主要目標'**
  String get enterMainGoal;

  /// No description provided for @totalTasks.
  ///
  /// In zh, this message translates to:
  /// **'總共 {count} 個任務'**
  String totalTasks(int count);

  /// No description provided for @totalPomodoros.
  ///
  /// In zh, this message translates to:
  /// **'總共 {count} 個番茄鐘'**
  String totalPomodoros(int count);

  /// No description provided for @noTasksInPlan.
  ///
  /// In zh, this message translates to:
  /// **'計畫中還沒有任務'**
  String get noTasksInPlan;

  /// No description provided for @newTask.
  ///
  /// In zh, this message translates to:
  /// **'新任務'**
  String get newTask;

  /// No description provided for @mainGoalRequired.
  ///
  /// In zh, this message translates to:
  /// **'主要目標不能為空'**
  String get mainGoalRequired;

  /// No description provided for @atLeastOneTaskRequired.
  ///
  /// In zh, this message translates to:
  /// **'至少需要一個任務'**
  String get atLeastOneTaskRequired;

  /// No description provided for @enterTaskDescription.
  ///
  /// In zh, this message translates to:
  /// **'輸入任務描述'**
  String get enterTaskDescription;

  /// No description provided for @description.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get description;

  /// No description provided for @cannotExtractTasks.
  ///
  /// In zh, this message translates to:
  /// **'無法從對話中提取任務，請嘗試更明確地描述任務'**
  String get cannotExtractTasks;

  /// No description provided for @aiResponseFailed.
  ///
  /// In zh, this message translates to:
  /// **'AI 回復失敗'**
  String get aiResponseFailed;

  /// No description provided for @tasksCreatedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'成功創建 {count} 個任務！'**
  String tasksCreatedSuccess(int count);

  /// No description provided for @failedToCreateTasks.
  ///
  /// In zh, this message translates to:
  /// **'創建任務失敗'**
  String get failedToCreateTasks;

  /// No description provided for @taskCreationFailed.
  ///
  /// In zh, this message translates to:
  /// **'創建任務失敗: {error}'**
  String taskCreationFailed(String error);

  /// No description provided for @confirmAction.
  ///
  /// In zh, this message translates to:
  /// **'確認{action}'**
  String confirmAction(String action);

  /// No description provided for @confirmActionMessage.
  ///
  /// In zh, this message translates to:
  /// **'確定要執行{action}操作嗎？此操作無法復原。'**
  String confirmActionMessage(String action);

  /// No description provided for @featureComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'{action}功能將在正式版本中實現'**
  String featureComingSoon(String action);

  /// No description provided for @hourShort.
  ///
  /// In zh, this message translates to:
  /// **'時'**
  String get hourShort;

  /// No description provided for @minuteShort.
  ///
  /// In zh, this message translates to:
  /// **'分'**
  String get minuteShort;

  /// No description provided for @secondShort.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get secondShort;

  /// No description provided for @hour.
  ///
  /// In zh, this message translates to:
  /// **'小時'**
  String get hour;

  /// No description provided for @minute.
  ///
  /// In zh, this message translates to:
  /// **'分鐘'**
  String get minute;

  /// No description provided for @second.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get second;

  /// No description provided for @focusMode.
  ///
  /// In zh, this message translates to:
  /// **'專注時間'**
  String get focusMode;

  /// No description provided for @thisWeekOverview.
  ///
  /// In zh, this message translates to:
  /// **'本週概覽'**
  String get thisWeekOverview;

  /// No description provided for @thisMonthOverview.
  ///
  /// In zh, this message translates to:
  /// **'本月概覽'**
  String get thisMonthOverview;

  /// No description provided for @hours.
  ///
  /// In zh, this message translates to:
  /// **'{count} 小時'**
  String hours(String count);

  /// No description provided for @thisWeekGoal.
  ///
  /// In zh, this message translates to:
  /// **'本週目標'**
  String get thisWeekGoal;

  /// No description provided for @workDays.
  ///
  /// In zh, this message translates to:
  /// **'工作天數'**
  String get workDays;

  /// No description provided for @bestDay.
  ///
  /// In zh, this message translates to:
  /// **'最佳單日'**
  String get bestDay;

  /// No description provided for @monthlyHeatmap.
  ///
  /// In zh, this message translates to:
  /// **'月度專注熱力圖'**
  String get monthlyHeatmap;

  /// No description provided for @thisMonthTrend.
  ///
  /// In zh, this message translates to:
  /// **'本月趨勢'**
  String get thisMonthTrend;

  /// No description provided for @noPomodoros.
  ///
  /// In zh, this message translates to:
  /// **'今天還沒有完成任何番茄鐘'**
  String get noPomodoros;

  /// No description provided for @thisWeekTrend.
  ///
  /// In zh, this message translates to:
  /// **'本週趨勢'**
  String get thisWeekTrend;

  /// No description provided for @noWeekStats.
  ///
  /// In zh, this message translates to:
  /// **'本週還沒有統計資料'**
  String get noWeekStats;

  /// No description provided for @bestFocusTime.
  ///
  /// In zh, this message translates to:
  /// **'最佳專注時段（最近 30 天）'**
  String get bestFocusTime;

  /// No description provided for @noMonthStats.
  ///
  /// In zh, this message translates to:
  /// **'本月還沒有統計資料'**
  String get noMonthStats;

  /// No description provided for @count.
  ///
  /// In zh, this message translates to:
  /// **'{count} 個'**
  String count(int count);

  /// No description provided for @consecutiveFocus.
  ///
  /// In zh, this message translates to:
  /// **'連續專注'**
  String get consecutiveFocus;

  /// No description provided for @notEnoughData.
  ///
  /// In zh, this message translates to:
  /// **'還沒有足夠的資料'**
  String get notEnoughData;

  /// No description provided for @yourBestFocusTime.
  ///
  /// In zh, this message translates to:
  /// **'您的最佳專注時段'**
  String get yourBestFocusTime;

  /// No description provided for @morning.
  ///
  /// In zh, this message translates to:
  /// **'早上'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In zh, this message translates to:
  /// **'下午'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In zh, this message translates to:
  /// **'傍晚'**
  String get evening;

  /// No description provided for @night.
  ///
  /// In zh, this message translates to:
  /// **'深夜'**
  String get night;

  /// No description provided for @morningTime.
  ///
  /// In zh, this message translates to:
  /// **'6:00-12:00'**
  String get morningTime;

  /// No description provided for @afternoonTime.
  ///
  /// In zh, this message translates to:
  /// **'12:00-18:00'**
  String get afternoonTime;

  /// No description provided for @eveningTime.
  ///
  /// In zh, this message translates to:
  /// **'18:00-22:00'**
  String get eveningTime;

  /// No description provided for @nightTime.
  ///
  /// In zh, this message translates to:
  /// **'22:00-6:00'**
  String get nightTime;

  /// No description provided for @completedPomodorosCount.
  ///
  /// In zh, this message translates to:
  /// **'已完成 {count} 個番茄鐘'**
  String completedPomodorosCount(int count);

  /// No description provided for @copiedToClipboard.
  ///
  /// In zh, this message translates to:
  /// **'已複製到剪貼簿'**
  String get copiedToClipboard;

  /// No description provided for @justNow.
  ///
  /// In zh, this message translates to:
  /// **'剛剛'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 分鐘前'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 小時前'**
  String hoursAgo(int count);

  /// No description provided for @mondayShort.
  ///
  /// In zh, this message translates to:
  /// **'週一'**
  String get mondayShort;

  /// No description provided for @tuesdayShort.
  ///
  /// In zh, this message translates to:
  /// **'週二'**
  String get tuesdayShort;

  /// No description provided for @wednesdayShort.
  ///
  /// In zh, this message translates to:
  /// **'週三'**
  String get wednesdayShort;

  /// No description provided for @thursdayShort.
  ///
  /// In zh, this message translates to:
  /// **'週四'**
  String get thursdayShort;

  /// No description provided for @fridayShort.
  ///
  /// In zh, this message translates to:
  /// **'週五'**
  String get fridayShort;

  /// No description provided for @saturdayShort.
  ///
  /// In zh, this message translates to:
  /// **'週六'**
  String get saturdayShort;

  /// No description provided for @sundayShort.
  ///
  /// In zh, this message translates to:
  /// **'週日'**
  String get sundayShort;

  /// No description provided for @pomodoroCountShort.
  ///
  /// In zh, this message translates to:
  /// **'{count} 個番茄鐘'**
  String pomodoroCountShort(int count);

  /// No description provided for @less.
  ///
  /// In zh, this message translates to:
  /// **'少'**
  String get less;

  /// No description provided for @more.
  ///
  /// In zh, this message translates to:
  /// **'多'**
  String get more;

  /// No description provided for @helloAI.
  ///
  /// In zh, this message translates to:
  /// **'你好！我是 AI 助手'**
  String get helloAI;

  /// No description provided for @aiDescription.
  ///
  /// In zh, this message translates to:
  /// **'我是您的專注助手，可以幫您分析任務、提供建議'**
  String get aiDescription;

  /// No description provided for @noTasksToSelect.
  ///
  /// In zh, this message translates to:
  /// **'暫無可選擇的任務'**
  String get noTasksToSelect;

  /// No description provided for @pleaseAddTasksFirst.
  ///
  /// In zh, this message translates to:
  /// **'請先在任務頁面添加一些任務'**
  String get pleaseAddTasksFirst;

  /// No description provided for @pomodoroProgress.
  ///
  /// In zh, this message translates to:
  /// **'{completed}/{total}'**
  String pomodoroProgress(int completed, int total);

  /// No description provided for @breakdownWithAI.
  ///
  /// In zh, this message translates to:
  /// **'用 AI 拆解'**
  String get breakdownWithAI;

  /// No description provided for @aiSessionGroup.
  ///
  /// In zh, this message translates to:
  /// **'AI 同一批任務（{count} 個）'**
  String aiSessionGroup(int count);

  /// No description provided for @aiSessionToggleHint.
  ///
  /// In zh, this message translates to:
  /// **'點一下可展開或收合'**
  String get aiSessionToggleHint;

  /// No description provided for @notificationFocusCompleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'專注時間結束'**
  String get notificationFocusCompleteTitle;

  /// No description provided for @notificationFocusCompleteBody.
  ///
  /// In zh, this message translates to:
  /// **'專注時段已完成，休息一下吧'**
  String get notificationFocusCompleteBody;

  /// No description provided for @notificationFocusCompleteWithTask.
  ///
  /// In zh, this message translates to:
  /// **'「{taskTitle}」專注時段已完成，休息一下吧'**
  String notificationFocusCompleteWithTask(String taskTitle);

  /// No description provided for @notificationBreakCompleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'休息結束'**
  String get notificationBreakCompleteTitle;

  /// No description provided for @notificationLongBreakCompleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'長休息結束'**
  String get notificationLongBreakCompleteTitle;

  /// No description provided for @notificationBreakCompleteBody.
  ///
  /// In zh, this message translates to:
  /// **'準備好繼續專注了嗎'**
  String get notificationBreakCompleteBody;

  /// No description provided for @notificationChannelName.
  ///
  /// In zh, this message translates to:
  /// **'計時器通知'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In zh, this message translates to:
  /// **'番茄鐘計時器完成通知'**
  String get notificationChannelDescription;

  /// No description provided for @notificationTaskCompleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'任務完成！'**
  String get notificationTaskCompleteTitle;

  /// No description provided for @notificationTaskCompleteBody.
  ///
  /// In zh, this message translates to:
  /// **'「{taskTitle}」的所有番茄鐘已完成'**
  String notificationTaskCompleteBody(String taskTitle);

  /// No description provided for @notificationTaskReminderTitle.
  ///
  /// In zh, this message translates to:
  /// **'該開始做事了'**
  String get notificationTaskReminderTitle;

  /// No description provided for @notificationTaskReminderBody.
  ///
  /// In zh, this message translates to:
  /// **'提醒你：「{taskTitle}」仲等緊你完成'**
  String notificationTaskReminderBody(String taskTitle);

  /// No description provided for @notificationTaskReminderChannelName.
  ///
  /// In zh, this message translates to:
  /// **'任務提醒'**
  String get notificationTaskReminderChannelName;

  /// No description provided for @notificationTaskReminderChannelDescription.
  ///
  /// In zh, this message translates to:
  /// **'待辦任務的每日提醒通知'**
  String get notificationTaskReminderChannelDescription;

  /// No description provided for @notificationPomodoroFocusCompleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'第 {completed}/{total} 個番茄鐘完成'**
  String notificationPomodoroFocusCompleteTitle(int completed, int total);

  /// No description provided for @notificationPomodoroStartBreakBody.
  ///
  /// In zh, this message translates to:
  /// **'開始{breakName}'**
  String notificationPomodoroStartBreakBody(String breakName);

  /// No description provided for @notificationPomodoroBreakCompleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'{breakName}完成'**
  String notificationPomodoroBreakCompleteTitle(String breakName);

  /// No description provided for @notificationPomodoroStartFocusBody.
  ///
  /// In zh, this message translates to:
  /// **'開始第 {pomodoroIndex} 個番茄鐘'**
  String notificationPomodoroStartFocusBody(int pomodoroIndex);

  /// No description provided for @notificationPomodoroNextTaskBody.
  ///
  /// In zh, this message translates to:
  /// **'要開始「{nextTaskTitle}」嗎？'**
  String notificationPomodoroNextTaskBody(String nextTaskTitle);

  /// No description provided for @startNextTaskTitle.
  ///
  /// In zh, this message translates to:
  /// **'開始下一個任務？'**
  String get startNextTaskTitle;

  /// No description provided for @startNextTaskMessage.
  ///
  /// In zh, this message translates to:
  /// **'「{completedTaskTitle}」已完成。要而家開始「{nextTaskTitle}」嗎？'**
  String startNextTaskMessage(String completedTaskTitle, String nextTaskTitle);

  /// No description provided for @taskCelebrationMessage.
  ///
  /// In zh, this message translates to:
  /// **'「{taskTitle}」已完成，做得好！'**
  String taskCelebrationMessage(String taskTitle);

  /// No description provided for @signInToEnableSync.
  ///
  /// In zh, this message translates to:
  /// **'登入以啟用雲端同步'**
  String get signInToEnableSync;

  /// No description provided for @signInWithGoogle.
  ///
  /// In zh, this message translates to:
  /// **'使用 Google 登入'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In zh, this message translates to:
  /// **'使用 Apple 登入'**
  String get signInWithApple;

  /// No description provided for @defaultAccountName.
  ///
  /// In zh, this message translates to:
  /// **'Flow 使用者'**
  String get defaultAccountName;

  /// No description provided for @signOut.
  ///
  /// In zh, this message translates to:
  /// **'登出'**
  String get signOut;

  /// No description provided for @lastSynced.
  ///
  /// In zh, this message translates to:
  /// **'上次同步：{time}'**
  String lastSynced(String time);

  /// No description provided for @syncNow.
  ///
  /// In zh, this message translates to:
  /// **'立即同步'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In zh, this message translates to:
  /// **'同步中…'**
  String get syncing;

  /// No description provided for @syncError.
  ///
  /// In zh, this message translates to:
  /// **'同步失敗'**
  String get syncError;

  /// No description provided for @signInFailed.
  ///
  /// In zh, this message translates to:
  /// **'登入失敗，請稍後再試'**
  String get signInFailed;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'確認登出'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'登出後將停止雲端同步，本地資料不會被刪除。'**
  String get signOutConfirmMessage;

  /// No description provided for @accountSection.
  ///
  /// In zh, this message translates to:
  /// **'帳號'**
  String get accountSection;

  /// No description provided for @daysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 天前'**
  String daysAgo(int count);

  /// No description provided for @clearDataSuccess.
  ///
  /// In zh, this message translates to:
  /// **'所有資料已清除'**
  String get clearDataSuccess;

  /// No description provided for @clearDataFailed.
  ///
  /// In zh, this message translates to:
  /// **'清除資料失敗，請稍後再試'**
  String get clearDataFailed;

  /// No description provided for @manualAdd.
  ///
  /// In zh, this message translates to:
  /// **'手動新增'**
  String get manualAdd;

  /// No description provided for @describeTaskForAI.
  ///
  /// In zh, this message translates to:
  /// **'描述任務給 AI'**
  String get describeTaskForAI;

  /// No description provided for @aiGoal.
  ///
  /// In zh, this message translates to:
  /// **'目標（你想完成什麼）'**
  String get aiGoal;

  /// No description provided for @aiGoalRequired.
  ///
  /// In zh, this message translates to:
  /// **'請輸入目標'**
  String get aiGoalRequired;

  /// No description provided for @aiDeadline.
  ///
  /// In zh, this message translates to:
  /// **'時限 / 截止時間（選填）'**
  String get aiDeadline;

  /// No description provided for @aiConstraints.
  ///
  /// In zh, this message translates to:
  /// **'限制條件（選填）'**
  String get aiConstraints;

  /// No description provided for @generatePlan.
  ///
  /// In zh, this message translates to:
  /// **'產生計劃'**
  String get generatePlan;

  /// No description provided for @chatWithAI.
  ///
  /// In zh, this message translates to:
  /// **'直接和 AI 對話'**
  String get chatWithAI;

  /// No description provided for @aiPromptIntro.
  ///
  /// In zh, this message translates to:
  /// **'請幫我把以下任務拆解成可執行的步驟：'**
  String get aiPromptIntro;

  /// No description provided for @aiPromptOutputStyle.
  ///
  /// In zh, this message translates to:
  /// **'請輸出具體步驟、每步預估番茄鐘、建議優先順序。'**
  String get aiPromptOutputStyle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
