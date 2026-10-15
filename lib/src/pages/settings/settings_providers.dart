import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

enum ThemeSetting { light, dark, system }

ThemeSetting themeSettingFrom(String? value) => switch (value) {
  'dark' => ThemeSetting.dark,
  'system' => ThemeSetting.system,
  _ => ThemeSetting.light,
};

ThemeMode themeModeFor(ThemeSetting setting) => switch (setting) {
  ThemeSetting.light => ThemeMode.light,
  ThemeSetting.dark => ThemeMode.dark,
  ThemeSetting.system => ThemeMode.system,
};

enum DefaultView { today, upcoming }

extension DefaultViewX on DefaultView {
  static DefaultView from(String? value) =>
      value == 'upcoming' ? DefaultView.upcoming : DefaultView.today;

  /// Matches the AppShell tab order.
  int get tabIndex => switch (this) {
    DefaultView.today => 0,
    DefaultView.upcoming => 1,
  };
}

enum WeekStart { monday, sunday }

extension WeekStartX on WeekStart {
  static WeekStart from(String? value) =>
      value == 'sunday' ? WeekStart.sunday : WeekStart.monday;

  int get weekday =>
      this == WeekStart.monday ? DateTime.monday : DateTime.sunday;

  String get value => this == WeekStart.monday ? 'monday' : 'sunday';
}

/// Whole settings snapshot. Synchronous by design: writes apply to state
/// first (instant UI, zero reload flash) and persist to SQLite after.
@immutable
class AppSettings {
  final ThemeSetting theme;
  final DefaultView defaultView;
  final WeekStart weekStart;
  final String profileName;
  final bool briefing;
  final bool streakReminder;
  final bool reminders;

  /// First-run swipe legend dismissed.
  final bool guideSeen;

  /// First-run onboarding coach completed.
  final bool onboardingSeen;

  const AppSettings({
    this.theme = ThemeSetting.light,
    this.defaultView = DefaultView.today,
    this.weekStart = WeekStart.monday,
    this.profileName = 'USER',
    this.briefing = true,
    this.streakReminder = false,
    this.reminders = true,
    this.guideSeen = false,
    this.onboardingSeen = false,
  });

  factory AppSettings.fromMap(Map<String, String> map) {
    final name = (map['profile_name'] ?? '').trim();
    return AppSettings(
      theme: themeSettingFrom(map['theme']),
      defaultView: DefaultViewX.from(map['default_view']),
      weekStart: WeekStartX.from(map['week_start']),
      profileName: name.isEmpty ? 'USER' : name,
      briefing: (map['briefing'] ?? 'on') == 'on',
      streakReminder: (map['streak_reminder'] ?? 'off') == 'on',
      reminders: (map['reminders'] ?? 'on') == 'on',
      guideSeen: (map['guide_seen'] ?? 'off') == 'on',
      onboardingSeen: (map['onboarding_seen'] ?? 'off') == 'on',
    );
  }

  AppSettings copyWith({
    ThemeSetting? theme,
    DefaultView? defaultView,
    WeekStart? weekStart,
    String? profileName,
    bool? briefing,
    bool? streakReminder,
    bool? reminders,
    bool? guideSeen,
    bool? onboardingSeen,
  }) => AppSettings(
    theme: theme ?? this.theme,
    defaultView: defaultView ?? this.defaultView,
    weekStart: weekStart ?? this.weekStart,
    profileName: profileName ?? this.profileName,
    briefing: briefing ?? this.briefing,
    streakReminder: streakReminder ?? this.streakReminder,
    reminders: reminders ?? this.reminders,
    guideSeen: guideSeen ?? this.guideSeen,
    onboardingSeen: onboardingSeen ?? this.onboardingSeen,
  );
}

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  /// One-shot load from SQLite (called in `main` before first frame).
  Future<void> refresh() async {
    final map = await ref.read(appDatabaseProvider).getAllSettings();
    if (ref.mounted) state = AppSettings.fromMap(map);
  }

  Future<void> _save(String key, String value, AppSettings next) async {
    state = next;
    try {
      await ref.read(appDatabaseProvider).setSetting(key, value);
    } catch (_) {
      // Optimistic state stands; next refresh reconciles.
    }
  }

  Future<void> setTheme(ThemeSetting value) =>
      _save('theme', value.name, state.copyWith(theme: value));

  Future<void> setDefaultView(DefaultView value) =>
      _save('default_view', value.name, state.copyWith(defaultView: value));

  Future<void> setWeekStart(WeekStart value) =>
      _save('week_start', value.value, state.copyWith(weekStart: value));

  Future<void> setProfileName(String value) =>
      _save('profile_name', value, state.copyWith(profileName: value));

  Future<void> setBriefing(bool value) =>
      _save('briefing', value ? 'on' : 'off', state.copyWith(briefing: value));

  Future<void> setStreakReminder(bool value) => _save(
    'streak_reminder',
    value ? 'on' : 'off',
    state.copyWith(streakReminder: value),
  );

  Future<void> setReminders(bool value) => _save(
    'reminders',
    value ? 'on' : 'off',
    state.copyWith(reminders: value),
  );

  Future<void> setGuideSeen(bool value) => _save(
    'guide_seen',
    value ? 'on' : 'off',
    state.copyWith(guideSeen: value),
  );

  Future<void> setOnboardingSeen(bool value) => _save(
    'onboarding_seen',
    value ? 'on' : 'off',
    state.copyWith(onboardingSeen: value),
  );
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

final themeSettingProvider = Provider<ThemeSetting>(
  (ref) => ref.watch(settingsControllerProvider).theme,
);

final defaultViewProvider = Provider<DefaultView>(
  (ref) => ref.watch(settingsControllerProvider).defaultView,
);

final weekStartProvider = Provider<WeekStart>(
  (ref) => ref.watch(settingsControllerProvider).weekStart,
);

final profileNameProvider = Provider<String>(
  (ref) => ref.watch(settingsControllerProvider).profileName,
);

final briefingProvider = Provider<bool>(
  (ref) => ref.watch(settingsControllerProvider).briefing,
);

final streakReminderProvider = Provider<bool>(
  (ref) => ref.watch(settingsControllerProvider).streakReminder,
);

final remindersEnabledProvider = Provider<bool>(
  (ref) => ref.watch(settingsControllerProvider).reminders,
);

final guideSeenProvider = Provider<bool>(
  (ref) => ref.watch(settingsControllerProvider).guideSeen,
);

final onboardingSeenProvider = Provider<bool>(
  (ref) => ref.watch(settingsControllerProvider).onboardingSeen,
);
