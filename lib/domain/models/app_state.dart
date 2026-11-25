import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/prefs_service.dart';
import 'need.dart';
import 'need_rotation.dart';

/// Central app state. Loaded from [PrefsService] at startup.
/// All mutations persist immediately — 100% on-device.
class AppState extends ChangeNotifier {
  AppState._(this._prefs)
    : _dueDate = _prefs.dueDate,
      _isHalloween = _prefs.isHalloween,
      _isPaused = _prefs.isPaused,
      _nickname = _prefs.nickname,
      _babyTone = _prefs.babyTone,
      _completedCheckIns = _prefs.loadTodayCheckIns();

  final PrefsService _prefs;

  // ── Onboarding ───────────────────────────────────────────────────────────

  DateTime? _dueDate;
  DateTime? get dueDate => _dueDate;
  bool get isFirstRun => _dueDate == null;

  Future<void> saveDueDate(DateTime date) async {
    _dueDate = date;
    notifyListeners();
    await _prefs.saveDueDate(date);
  }

  // ── Nickname ─────────────────────────────────────────────────────────────

  String _nickname;

  /// The name the mother chose for the baby. Empty string = no nickname set.
  String get nickname => _nickname;

  /// Display name: nickname if set, otherwise 'Bumpy'.
  String get babyDisplayName => _nickname.isEmpty ? 'Bumpy' : _nickname;

  Future<void> saveNickname(String value) async {
    _nickname = value.trim();
    notifyListeners();
    await _prefs.saveNickname(_nickname);
  }

  // ── Baby Tone ────────────────────────────────────────────────────────────

  String _babyTone;
  String get babyTone => _babyTone;

  Future<void> saveBabyTone(String value) async {
    _babyTone = value;
    notifyListeners();
    await _prefs.saveBabyTone(value);
  }

  // ── Mode ─────────────────────────────────────────────────────────────────

  bool _isHalloween;
  bool get isHalloween => _isHalloween;

  MaternalNeed? _costumeOverride;

  /// Optional Halloween costume try-on from ClosetSheet.
  /// Null means wear today's need costume. Does not affect check-ins.
  MaternalNeed? get costumeOverride => _costumeOverride;

  void setCostumeOverride(MaternalNeed? need) {
    _costumeOverride = need;
    notifyListeners();
  }

  Future<void> toggleMode() async {
    _isHalloween = !_isHalloween;
    notifyListeners();
    await _prefs.saveIsHalloween(_isHalloween);
  }

  // ── Pause ────────────────────────────────────────────────────────────────

  bool _isPaused;
  bool get isPaused => _isPaused;

  Future<void> togglePause() async {
    _isPaused = !_isPaused;
    notifyListeners();
    await _prefs.saveIsPaused(_isPaused);
  }

  // ── Tab ──────────────────────────────────────────────────────────────────

  int _currentTab = 0;
  int get currentTab => _currentTab;

  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  // ── Daily check-ins ──────────────────────────────────────────────────────

  Set<String> _completedCheckIns;
  Set<String> get completedCheckIns => Set.unmodifiable(_completedCheckIns);

  bool isChecked(String id) => _completedCheckIns.contains(id);

  /// Today's need-of-the-day, resolved at call time.
  MaternalNeed get todayNeed => NeedRotation.forDate(DateTime.now());

  /// The third check-in slot (REST when need is water/vitamin, else the need).
  MaternalNeed get thirdCheckIn => NeedRotation.thirdCheckIn(todayNeed);

  /// True when all 3 check-ins are ticked.
  bool get allChecked {
    return isChecked(AppConstants.checkInWater) &&
        isChecked(AppConstants.checkInVitamin) &&
        isChecked(AppConstants.checkInNeed);
  }

  Future<void> toggleCheckIn(String id) async {
    final next = Set<String>.from(_completedCheckIns);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    _completedCheckIns = next;
    notifyListeners(); // immediate — UI rebuilds before persistence completes
    await _prefs.saveTodayCheckIns(_completedCheckIns);
  }

  /// Clears today's check-ins and unpauses. Used by Start Fresh.
  Future<void> clearTodayCheckIns() async {
    _completedCheckIns = {};
    _isPaused = false;
    _currentTab = 0;
    notifyListeners();
    await _prefs.saveTodayCheckIns({});
    await _prefs.saveIsPaused(false);
  }

  /// Wipes all data and returns the app to First Run. Used by Erase.
  Future<void> eraseAll() async {
    _dueDate = null;
    _nickname = '';
    _babyTone = AppConstants.defaultBabyTone;
    _isHalloween = true;
    _isPaused = false;
    _costumeOverride = null;
    _currentTab = 0;
    _completedCheckIns = {};
    notifyListeners();
    await _prefs.clearAll();
  }

  // ── Factory ───────────────────────────────────────────────────────────────

  static Future<AppState> load() async {
    final prefs = await PrefsService.create();
    return AppState._(prefs);
  }
}
