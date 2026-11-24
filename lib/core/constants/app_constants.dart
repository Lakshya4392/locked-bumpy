/// App-wide compile-time constants.
/// No magic strings outside this file.
class AppConstants {
  AppConstants._();

  static const String appVersion = 'v1.0.0';
  static const String privacyStatement =
      'No data ever leaves your phone. No accounts. No tracking. No ads.';

  // ── SharedPreferences keys ──────────────────────────────────────────────
  // The original estimate anchors Days Together, including on older installs.
  static const String prefsCorrectedDueDateKey = 'corrected_due_date_iso';
  static const String prefsDueDateKey = 'due_date_iso';
  static const String prefsVisitTopicsKey = 'visit_topics';
  static const String prefsSkinToneKey = 'skin_tone';
  static const String prefsIsHalloweenKey = 'is_halloween';
  static const String prefsIsPausedKey = 'is_paused';

  /// Optional nickname the mother gives the baby. Empty string = not set.
  static const String prefsNicknameKey = 'baby_nickname';

  /// ISO date string (yyyy-MM-dd) of the last day check-ins were saved.
  static const String prefsCheckInDateKey = 'checkin_date';

  /// Comma-separated completed check-in IDs for today.
  static const String prefsCheckInIdsKey = 'checkin_ids';
  static const String prefsDailyNeedsKey = 'daily_needs_v2';

  /// Written before Erase deletes anything; removed only after every owned
  /// key is confirmed gone on disk. Present at startup = interrupted Erase.
  static const String prefsEraseInProgressKey = 'erase_in_progress';

  // ── Gestational bounds ──────────────────────────────────────────────────
  static const int minWeek = 4;
  static const int maxWeek = 42;
  static const int fullTermDays = 280; // LMP + 280 days = due date

  // ── Medical disclaimer ──────────────────────────────────────────────────
  static const String disclaimer =
      'This app is not medical advice. '
      'If you are worried about anything, call your doctor.';

  // ── Check-in IDs ────────────────────────────────────────────────────────
  static const String checkInNeed = 'need_of_the_day';
  static const String checkInWater = 'water';
  static const String checkInVitamin = 'vitamin';

  // ── Need rotation epoch ─────────────────────────────────────────────────
  /// Monday 2026-11-23 is day 0 of the rotation (IRON).
  static final DateTime rotationEpoch = DateTime(2026, 11, 23);
}
