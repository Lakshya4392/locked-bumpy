import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Thin wrapper around [SharedPreferences].
/// All data stays on-device — zero network calls, zero serialisation to any
/// remote destination.
class PrefsService {
  PrefsService._(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsService._(prefs);
  }

  // ── Due date ─────────────────────────────────────────────────────────────

  DateTime? get dueDate {
    final raw = _prefs.getString(AppConstants.prefsDueDateKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveDueDate(DateTime date) =>
      _prefs.setString(AppConstants.prefsDueDateKey, _isoDate(date));

  // ── Mode & pause ─────────────────────────────────────────────────────────

  bool get isHalloween =>
      _prefs.getBool(AppConstants.prefsIsHalloweenKey) ?? true;

  Future<void> saveIsHalloween(bool value) =>
      _prefs.setBool(AppConstants.prefsIsHalloweenKey, value);

  bool get isPaused => _prefs.getBool(AppConstants.prefsIsPausedKey) ?? false;

  Future<void> saveIsPaused(bool value) =>
      _prefs.setBool(AppConstants.prefsIsPausedKey, value);

  // ── Nickname ─────────────────────────────────────────────────────────────

  /// Empty string means the mother hasn't set a nickname.
  String get nickname => _prefs.getString(AppConstants.prefsNicknameKey) ?? '';

  Future<void> saveNickname(String value) =>
      _prefs.setString(AppConstants.prefsNicknameKey, value.trim());

  String get babyTone =>
      _prefs.getString(AppConstants.prefsBabyToneKey) ??
      AppConstants.defaultBabyTone;

  Future<void> saveBabyTone(String value) =>
      _prefs.setString(AppConstants.prefsBabyToneKey, value);

  // ── Daily check-ins ──────────────────────────────────────────────────────

  /// Returns the saved check-in IDs for today; clears them if the saved date
  /// is before today (a new day started).
  Set<String> loadTodayCheckIns() {
    final savedDate = _prefs.getString(AppConstants.prefsCheckInDateKey);
    final today = _isoDate(DateTime.now());
    if (savedDate != today) return {};
    final raw = _prefs.getString(AppConstants.prefsCheckInIdsKey) ?? '';
    if (raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  Future<void> saveTodayCheckIns(Set<String> ids) async {
    final today = _isoDate(DateTime.now());
    await _prefs.setString(AppConstants.prefsCheckInDateKey, today);
    await _prefs.setString(AppConstants.prefsCheckInIdsKey, ids.join(','));
  }

  // ── Nuclear erase ────────────────────────────────────────────────────────

  /// Wipes every key — used by Erase all data only.
  Future<void> clearAll() => _prefs.clear();

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
