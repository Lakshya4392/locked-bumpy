/// App-wide compile-time constants.
/// No magic strings outside this file.
class AppConstants {
  AppConstants._();

  // ── SharedPreferences keys ──────────────────────────────────────────────
  static const String prefsDueDateKey = 'due_date_iso';
  static const String prefsIsHalloweenKey = 'is_halloween';
  static const String prefsIsPausedKey = 'is_paused';

  /// Optional nickname the mother gives the baby. Empty string = not set.
  static const String prefsNicknameKey = 'baby_nickname';

  /// ISO date string (yyyy-MM-dd) of the last day check-ins were saved.
  static const String prefsCheckInDateKey = 'checkin_date';

  /// Comma-separated completed check-in IDs for today.
  static const String prefsCheckInIdsKey = 'checkin_ids';

  // ── Gestational bounds ──────────────────────────────────────────────────
  static const int minWeek = 4;
  static const int maxWeek = 42;
  static const int fullTermDays = 280; // LMP + 280 days = due date

  // ── App metadata & privacy ──────────────────────────────────────────────
  static const String appVersion = '1.0.0';
  static const String privacyStatement =
      'Everything stays on your device. No accounts, no servers, '
      'no analytics, and zero network calls.';

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
