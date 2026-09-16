import 'hive_boxes.dart';

/// Persists the "has the user seen onboarding" flag in the shared Hive
/// prefs box (avoids pulling in shared_preferences just for one flag).
class OnboardingPrefs {
  static const _key = 'seen_onboarding';

  static bool get seen => HiveBoxes.prefsBox.get(_key, defaultValue: false);

  static Future<void> markSeen() => HiveBoxes.prefsBox.put(_key, true);
}
