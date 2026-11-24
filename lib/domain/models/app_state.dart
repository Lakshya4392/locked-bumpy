import 'package:flutter/foundation.dart';
import '../../core/services/prefs_service.dart';
import '../pregnancy.dart';
import 'need.dart';
import 'need_rotation.dart';
import 'skin_tone.dart';

enum CheckInSaveStatus { saved, saving, failed }

/// Central app state. Loaded from [PrefsService] at startup.
/// Preferences and check-ins are saved on-device. Dress-up lasts for the day
/// or until the app closes.
class AppState extends ChangeNotifier {
  AppState._(this._prefs, this._now)
    : _dueDate = _prefs.dueDate,
      _originalDueDate = _prefs.originalDueDate,
      _isHalloween = _prefs.isHalloween,
      _skinTone = _prefs.skinTone,
      _visitTopics = _prefs.visitTopics,
      _isPaused = _prefs.isPaused,
      _nickname = _prefs.nickname {
    _day = _now();
    _completedCheckIns = _prefs.loadTodayCheckIns(_day);
    _savedPaused = _isPaused;
    // Interrupted Erase: some data may already be gone. Fail closed — stay
    // hidden, never show First Run over leftovers, and offer a retry.
    if (_prefs.eraseInProgress) {
      _erasePending = true;
      _eraseFailed = true;
      _isPaused = true;
    }
  }

  final PrefsService _prefs;
  final DateTime Function() _now;

  // ── Onboarding ───────────────────────────────────────────────────────────

  DateTime? _dueDate;
  DateTime? _originalDueDate;
  DateTime? get dueDate => _dueDate;

  /// Never true while an Erase is unfinished on disk: leftover data must not
  /// sit behind a fresh setup.
  bool get isFirstRun => _dueDate == null && !_erasePending;

  int _setupRevision = 0;

  Future<bool> finishSetup({
    required DateTime date,
    required bool halloween,
    required SkinTone tone,
    required String nickname,
  }) async {
    if (!isFirstRun || isPaused) return false;
    final revision = ++_setupRevision;
    final name = nickname.trim();
    final saved = await _prefs.saveSetup(
      date: date,
      halloween: halloween,
      tone: tone,
      nickname: name,
      active: () => revision == _setupRevision && isFirstRun && !isPaused,
    );
    if (!saved) return false;
    _isHalloween = halloween;
    _skinTone = tone;
    _nickname = name;
    _acceptDueDate(date);
    return true;
  }

  Future<bool> saveDueDate(DateTime date) async {
    if (isPaused) return false;
    final saved = await _prefs.saveDueDate(date);
    if (!saved) return false;
    _acceptDueDate(date);
    return true;
  }

  void _acceptDueDate(DateTime date) {
    refreshDay();
    _originalDueDate ??= date;
    _dueDate = date;
    notifyListeners();
  }

  // ── Nickname ─────────────────────────────────────────────────────────────

  String _nickname;

  /// The name the mother chose for the baby. Empty string = no nickname set.
  String get nickname => _nickname;

  /// Display name: nickname if set, otherwise 'Little Bumpy'.
  String get babyDisplayName => _nickname.isEmpty ? 'Little Bumpy' : _nickname;

  Future<bool> saveNickname(String value) async {
    if (isPaused) return false;
    final name = value.trim();
    if (!await _prefs.saveNickname(name)) return false;
    _nickname = name;
    notifyListeners();
    return true;
  }

  Set<MaternalNeed> _visitTopics;
  int _visitRevision = 0;
  Set<MaternalNeed> get visitTopics => Set.unmodifiable(_visitTopics);

  Future<void> saveVisitTopics(Set<MaternalNeed> topics) async {
    if (isPaused || isFirstRun || setEquals(topics, _visitTopics)) return;
    final selection = Set<MaternalNeed>.of(topics);
    final revision = ++_visitRevision;
    await _prefs.saveVisitTopics(selection);
    if (revision != _visitRevision || isFirstRun) return;
    _visitTopics = selection;
    notifyListeners();
  }

  // ── Mode ─────────────────────────────────────────────────────────────────

  SkinTone _skinTone;
  SkinTone get skinTone => _skinTone;

  Future<void> saveSkinTone(SkinTone tone) async {
    if (isPaused || tone == _skinTone) return;
    _skinTone = tone;
    final saved = _prefs.saveSkinTone(tone);
    notifyListeners();
    await saved;
  }

  bool _isHalloween;
  bool get isHalloween => _isHalloween;

  MaternalNeed? _costumeOverride;
  MaternalNeed? get costumeOverride => _costumeOverride;

  void setCostumeOverride(MaternalNeed? need) {
    if (refreshDay() || isFirstRun || isPaused || !isHalloween) return;
    final next = need == todayNeed ? null : need;
    if (next == _costumeOverride) return;
    _costumeOverride = next;
    notifyListeners();
  }

  Future<void> toggleMode() async {
    if (isPaused) return;
    _isHalloween = !_isHalloween;
    final saved = _prefs.saveIsHalloween(_isHalloween);
    notifyListeners();
    await saved;
  }

  // ── Pause ────────────────────────────────────────────────────────────────
  //
  // The screen hides first; storage follows. Writes are queued in order by
  // PrefsService, so a stale write cannot land after a newer one. A failed
  // write never un-hides anything: the app stays paused in memory and the
  // write is retried by [savePendingPause] (app lifecycle) or the next action.

  bool _isPaused;
  bool get isPaused => _isPaused;

  /// What storage last confirmed for the pause flag; null when unknown.
  bool? _savedPaused;

  /// True while the on-device pause flag may not match the screen.
  bool get pauseSavePending => _savedPaused != _isPaused;

  /// Idempotent: a double tap cannot flip Pause back off.
  Future<void> pause() async {
    // Erase already shows Pause and owns the pause key until it settles.
    if (_erasing != null) return;
    if (!_isPaused) {
      _setupRevision++;
      _isPaused = true;
      notifyListeners();
    }
    await _savePause();
  }

  /// Idempotent, and ignored while an Erase is running or unfinished on disk
  /// (data may be half removed; the only way out is to finish Erase).
  Future<void> resume() async {
    if (!_isPaused || _erasing != null || _erasePending) return;
    _isPaused = false;
    _eraseFailed = false;
    refreshDay();
    notifyListeners();
    await _savePause();
  }

  /// Kept for tests and older callers; UI uses [pause] and [resume].
  Future<void> togglePause() => _isPaused ? resume() : pause();

  /// Retries a pause write that failed earlier. Safe to call any time.
  Future<void> savePendingPause() async {
    if (_erasing == null && pauseSavePending) await _savePause();
  }

  Future<void> _savePause() async {
    final target = _isPaused;
    final ok = await _prefs.saveIsPaused(target);
    // Writes complete in request order, so this is the latest confirmed one.
    _savedPaused = ok ? target : null;
  }

  // ── Tab ──────────────────────────────────────────────────────────────────

  int _currentTab = 0;
  int get currentTab => _currentTab;

  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  // ── Daily check-ins ──────────────────────────────────────────────────────

  late DateTime _day;
  DateTime get today => _day;

  int? get currentWeek => _dueDate == null
      ? null
      : PregnancyCalculator.weekFromDueDate(
          dueDate: _dueDate!,
          currentDate: today,
        );

  int get daysTogetherCount {
    final original = _originalDueDate;
    if (original == null) return 0;
    final days = PregnancyCalculator.daysFromDueDate(
      dueDate: original,
      currentDate: today,
    );
    return days < 0 ? 0 : days;
  }

  int _checkInRevision = 0;
  CheckInSaveStatus _checkInStatus = CheckInSaveStatus.saved;
  CheckInSaveStatus get checkInStatus => _checkInStatus;

  late Set<String> _completedCheckIns;
  Set<String> get completedCheckIns => Set.unmodifiable(_completedCheckIns);

  bool isChecked(String id) => _completedCheckIns.contains(id);

  MaternalNeed get todayNeed => NeedRotation.forDate(_day);

  List<MaternalNeed> get dailyCheckIns => NeedRotation.checkIns(todayNeed);

  /// True when all 3 check-ins are ticked.
  bool get allChecked => dailyCheckIns.every((need) => isChecked(need.name));

  bool refreshDay() {
    final now = _now();
    if (now.year == _day.year &&
        now.month == _day.month &&
        now.day == _day.day) {
      return false;
    }
    _day = now;
    _checkInRevision++;
    _checkInStatus = CheckInSaveStatus.saved;
    _costumeOverride = null;
    _completedCheckIns = _prefs.loadTodayCheckIns(now);
    notifyListeners();
    return true;
  }

  Duration get timeToMidnight {
    final now = _now();
    return DateTime(now.year, now.month, now.day + 1).difference(now);
  }

  Future<void> toggleCheckIn(String id) async {
    if (refreshDay() ||
        isPaused ||
        !dailyCheckIns.any((need) => need.name == id)) {
      return;
    }
    final next = Set<String>.from(_completedCheckIns);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    _completedCheckIns = next;
    await _saveCheckIns();
  }

  Future<void> retryCheckIns() async {
    if (refreshDay() ||
        isPaused ||
        _checkInStatus != CheckInSaveStatus.failed) {
      return;
    }
    await _saveCheckIns();
  }

  Future<void> _saveCheckIns() async {
    final revision = ++_checkInRevision;
    _checkInStatus = CheckInSaveStatus.saving;
    final pending = _prefs.saveTodayCheckIns(_day, _completedCheckIns);
    notifyListeners();
    final saved = await pending;
    if (revision != _checkInRevision) return;
    _checkInStatus = saved ? CheckInSaveStatus.saved : CheckInSaveStatus.failed;
    notifyListeners();
  }

  /// Clears today's check-ins and unpauses. Used by Start Fresh.
  Future<void> clearTodayCheckIns() async {
    if (_erasing != null || _erasePending) return;
    _day = _now();
    _completedCheckIns = {};
    _costumeOverride = null;
    _isPaused = false;
    _eraseFailed = false;
    _currentTab = 0;
    // Queue the pause write now, not after the check-in write: a Pause tapped
    // in between must be queued after this one, so it wins on disk.
    final pauseSaved = _savePause();
    await _saveCheckIns();
    await pauseSaved;
  }

  // ── Erase ────────────────────────────────────────────────────────────────

  Future<bool>? _erasing;
  bool _eraseFailed = false;
  bool _erasePending = false;

  /// True when the last Erase could not confirm every removal. The app stays
  /// paused and Erase can be tried again.
  bool get eraseFailed => _eraseFailed;

  /// True when an Erase began on disk (marker persisted) and is not confirmed
  /// finished. Resume and Start Fresh are refused; only Erase retry proceeds.
  bool get erasePending => _erasePending;

  /// Wipes Little Bumpy's data and returns to First Run. Used by Erase.
  ///
  /// The screen is hidden at once (paused). First Run is shown only after
  /// storage confirms every removal; otherwise this returns false, the app
  /// stays paused with data intact in memory, and Erase can be retried.
  /// A second call while one is running joins it.
  Future<bool> eraseAll() => _erasing ??= _erase().whenComplete(() {
    _erasing = null;
  });

  Future<bool> _erase() async {
    _setupRevision++;
    _eraseFailed = false;
    _isPaused = true;
    _costumeOverride = null;
    notifyListeners();
    // Queued after any earlier pause writes, so none of them can land later.
    final ok = await _prefs.clearAll();
    if (!ok) {
      _eraseFailed = true;
      // Reflects disk after reload: false only if the marker never landed,
      // which also means nothing was deleted and Resume is safe.
      _erasePending = _prefs.eraseInProgress;
      // Storage state is unknown now; record pause so a restart stays hidden.
      _savedPaused = null;
      notifyListeners();
      await _savePause();
      return false;
    }
    _erasePending = false;
    _dueDate = null;
    _originalDueDate = null;
    _visitRevision++;
    _checkInRevision++;
    _checkInStatus = CheckInSaveStatus.saved;
    _visitTopics = {};
    _nickname = '';
    _isHalloween = true;
    _skinTone = SkinTone.peach;
    _isPaused = false;
    _savedPaused = false; // no key stored means not paused
    _currentTab = 0;
    _completedCheckIns = {};
    notifyListeners();
    return true;
  }

  // ── Factory ───────────────────────────────────────────────────────────────

  static Future<AppState> load({DateTime Function() now = DateTime.now}) async {
    final prefs = await PrefsService.create();
    return AppState._(prefs, now);
  }

  @visibleForTesting
  static AppState withPrefs(
    PrefsService prefs, {
    DateTime Function() now = DateTime.now,
  }) => AppState._(prefs, now);
}
