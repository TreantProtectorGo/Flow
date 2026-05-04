import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'locale_provider.dart';
import '../l10n/app_localizations_en.dart';
import '../l10n/app_localizations_zh.dart';
import '../l10n/app_localizations.dart';

/// Provider for notification strings based on current locale
/// This allows us to get localized strings without BuildContext
final notificationStringsProvider = Provider<NotificationStrings>((ref) {
  final locale = ref.watch(localeProvider);

  // Get the appropriate AppLocalizations instance based on locale
  AppLocalizations l10n;
  if (locale.languageCode == 'zh') {
    if (locale.countryCode == 'TW') {
      l10n = AppLocalizationsZhTw();
    } else {
      l10n = AppLocalizationsZh();
    }
  } else {
    l10n = AppLocalizationsEn();
  }

  return NotificationStrings(l10n);
});

/// Holds all notification-related localized strings
class NotificationStrings {
  final AppLocalizations _l10n;

  NotificationStrings(this._l10n);

  String get focusCompleteTitle => _l10n.notificationFocusCompleteTitle;
  String get focusCompleteBody => _l10n.notificationFocusCompleteBody;
  String focusCompleteWithTask(String taskTitle) =>
      _l10n.notificationFocusCompleteWithTask(taskTitle);
  String get breakCompleteTitle => _l10n.notificationBreakCompleteTitle;
  String get longBreakCompleteTitle => _l10n.notificationLongBreakCompleteTitle;
  String get breakCompleteBody => _l10n.notificationBreakCompleteBody;
  String get channelName => _l10n.notificationChannelName;
  String get channelDescription => _l10n.notificationChannelDescription;
  String get taskCompleteTitle => _l10n.notificationTaskCompleteTitle;
  String taskCompleteBody(String taskTitle) =>
      _l10n.notificationTaskCompleteBody(taskTitle);
  String get taskReminderTitle => _l10n.notificationTaskReminderTitle;
  String taskReminderBody(String taskTitle) =>
      _l10n.notificationTaskReminderBody(taskTitle);
  String get taskReminderChannelName =>
      _l10n.notificationTaskReminderChannelName;
  String get taskReminderChannelDescription =>
      _l10n.notificationTaskReminderChannelDescription;
  String get shortBreak => _l10n.shortBreak;
  String get longBreak => _l10n.longBreak;
  String get pomodoroMode => _l10n.pomodoroMode;
  String pomodoroFocusCompleteTitle(int completed, int total) =>
      _l10n.notificationPomodoroFocusCompleteTitle(completed, total);
  String pomodoroStartBreakBody(String breakName) =>
      _l10n.notificationPomodoroStartBreakBody(breakName);
  String pomodoroBreakCompleteTitle(String breakName) =>
      _l10n.notificationPomodoroBreakCompleteTitle(breakName);
  String pomodoroStartFocusBody(int pomodoroIndex) =>
      _l10n.notificationPomodoroStartFocusBody(pomodoroIndex);
  String pomodoroNextTaskBody(String nextTaskTitle) =>
      _l10n.notificationPomodoroNextTaskBody(nextTaskTitle);
}
