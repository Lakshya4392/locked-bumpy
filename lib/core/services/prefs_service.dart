import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../domain/models/need.dart';
import '../../domain/models/skin_tone.dart';
import '../../domain/models/need_rotation.dart';

/// Thin wrapper around [SharedPreferences].
/// All data stays on-device — zero network calls, zero serialisation to any
/// remote destination.
class PrefsService {
  PrefsService._(this._prefs);

  /// Lets tests wrap a store that fails or stalls on purpose.
  @visibleForTesting
  PrefsService.wrap(SharedPreferences prefs) : this._(prefs);

  final SharedPreferences _prefs;

  static Future<PrefsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsService._(prefs);
  }

  // ── Privacy writes ───────────────────────────────────────────────────────
  //
  // Pause, daily choices, visit topics and Erase run in the order they were asked
  // for, so an older write can never land after a newer one. Each reports
  // success instead of throwing: a failed platform write still updates the
  // in-memory cache, so callers must trust the returned bool, not a read-back.

  Future<void> _writeTail = Future<void>.value();

  Future<bool> _orderedWrite(Future<bool> Function() op) {
    final result = _writeTail.then((_) => _attempt(op));
    _writeTail = result;
    return result;
  }

  static Future<bool> _attempt(Future<bool> Function() op) async {
    try {
      return await op();
    } catch (_) {
      return false;
    }
  }

  // ── Due date ─────────────────────────────────────────────────────────────

  DateTime? get originalDueDate => _readDate(AppConstants.prefsDueDateKey);

  DateTime? get dueDate =>
      _readDate(AppConstants.prefsCorrectedDueDateKey) ?? originalDueDate;

  DateTime? _readDate(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<bool> _writeDate(DateTime date, {required bool original}) async {
    final saved = await _attempt(
      () => _prefs.setString(
        original
            ? AppConstants.prefsDueDateKey
            : AppConstants.prefsCorrectedDueDateKey,
        _isoDate(date),
      ),
    );
    // The plugin updates its cache even on failure. A later load must see disk.
    if (!saved) await _reloadFromDisk();
    return saved;
  }

  Future<bool> saveDueDate(DateTime date) =>
      _orderedWrite(() => _writeDate(date, original: originalDueDate == null));

  /// The original due date commits setup. Before it exists, relaunch opens
  /// the welcome screen. All writes finish ahead of any subsequently queued Erase.
  Future<bool> saveSetup({
    required DateTime date,
    required bool halloween,
    required SkinTone tone,
    required String nickname,
    required bool Function() active,
  }) => _orderedWrite(() async {
    if (!active() ||
        !await _prefs.setBool(AppConstants.prefsIsHalloweenKey, halloween)) {
      return false;
    }
    if (!active() ||
        !await _prefs.setString(AppConstants.prefsSkinToneKey, tone.name)) {
      return false;
    }
    if (!active() ||
        !await _prefs.setString(AppConstants.prefsNicknameKey, nickname)) {
      return false;
    }
    return active() && await _writeDate(date, original: true);
  });

  // ── Mode & pause ─────────────────────────────────────────────────────────

  SkinTone get skinTone =>
      SkinTone.fromPreference(_prefs.getString(AppConstants.prefsSkinToneKey));

  Future<bool> saveSkinTone(SkinTone tone) => _orderedWrite(
    () => _prefs.setString(AppConstants.prefsSkinToneKey, tone.name),
  );

  bool get isHalloween =>
      _prefs.getBool(AppConstants.prefsIsHalloweenKey) ?? true;

  Future<bool> saveIsHalloween(bool value) => _orderedWrite(
    () => _prefs.setBool(AppConstants.prefsIsHalloweenKey, value),
  );

  bool get isPaused => _prefs.getBool(AppConstants.prefsIsPausedKey) ?? false;

  /// Queued behind earlier Pause/Erase writes. True only if storage confirmed.
  Future<bool> saveIsPaused(bool value) =>
      _orderedWrite(() => _prefs.setBool(AppConstants.prefsIsPausedKey, value));

  Set<MaternalNeed> get visitTopics {
    final saved = _prefs.getStringList(AppConstants.prefsVisitTopicsKey) ?? [];
    return MaternalNeed.values
        .where((need) => saved.contains(need.name))
        .toSet();
  }

  Future<void> saveVisitTopics(Set<MaternalNeed> topics) async {
    final values = <String>[
      for (final need in MaternalNeed.values)
        if (topics.contains(need)) need.name,
    ];
    final saved = await _orderedWrite(
      () => _prefs.setStringList(AppConstants.prefsVisitTopicsKey, values),
    );
    if (!saved) throw StateError('Could not save visit topics');
  }

  // ── Nickname ─────────────────────────────────────────────────────────────

  /// Empty string means the mother hasn't set a nickname.
  String get nickname => _prefs.getString(AppConstants.prefsNicknameKey) ?? '';

  Future<bool> saveNickname(String value) => _orderedWrite(() async {
    final saved = await _attempt(
      () => _prefs.setString(AppConstants.prefsNicknameKey, value.trim()),
    );
    if (!saved) await _reloadFromDisk();
    return saved;
  });

  // ── Daily check-ins ──────────────────────────────────────────────────────

  /// Returns the saved check-in IDs for today; clears them if the saved date
  /// is before today (a new day started).
  Set<String> loadTodayCheckIns(DateTime date) {
    final today = _isoDate(date);
    final current = _prefs.getStringList(AppConstants.prefsDailyNeedsKey);
    if (current != null) {
      return current.isNotEmpty && current.first == today
          ? current.skip(1).toSet()
          : {};
    }
    // Earlier builds saved tile positions. Decode what those tiles actually
    // said: on Water and Rest days two old tiles could mean the same thing.
    final savedDate = _prefs.getString(AppConstants.prefsCheckInDateKey);
    if (savedDate != today) return {};
    final slots = (_prefs.getString(AppConstants.prefsCheckInIdsKey) ?? '')
        .split(',');
    final need = NeedRotation.forDate(date);
    return {
      if (slots.contains(AppConstants.checkInNeed)) need.name,
      if (slots.contains(AppConstants.checkInWater)) MaternalNeed.water.name,
      if (slots.contains(AppConstants.checkInVitamin))
        NeedRotation.thirdCheckIn(need) == MaternalNeed.rest
            ? MaternalNeed.rest.name
            : MaternalNeed.vitamin.name,
    };
  }

  Future<bool> saveTodayCheckIns(DateTime date, Set<String> ids) {
    final values = [_isoDate(date), ...ids];
    return _orderedWrite(
      () => _prefs.setStringList(AppConstants.prefsDailyNeedsKey, values),
    );
  }

  // ── Nuclear erase ────────────────────────────────────────────────────────

  static const _ownedKeys = [
    AppConstants.prefsVisitTopicsKey,
    AppConstants.prefsDueDateKey,
    AppConstants.prefsCorrectedDueDateKey,
    AppConstants.prefsSkinToneKey,
    AppConstants.prefsIsHalloweenKey,
    AppConstants.prefsIsPausedKey,
    AppConstants.prefsNicknameKey,
    AppConstants.prefsDailyNeedsKey,
    AppConstants.prefsCheckInDateKey,
    AppConstants.prefsCheckInIdsKey,
  ];

  /// Set when a reload failed, so the cache can't be trusted to show whether
  /// the erase marker is on disk. Fails closed: treated as marker present.
  bool _diskUnknown = false;

  /// True when an Erase started and has not been confirmed finished on disk
  /// (or disk state is unknown). The app must stay hidden and offer retry.
  bool get eraseInProgress =>
      _diskUnknown ||
      (_prefs.getBool(AppConstants.prefsEraseInProgressKey) ?? false);

  /// Replaces the cache with what is actually stored. The legacy plugin
  /// mutates its cache before the platform write succeeds, so only a reload
  /// tells us what is on disk.
  Future<bool> _reloadFromDisk() async {
    try {
      await _prefs.reload();
      _diskUnknown = false;
      return true;
    } catch (_) {
      _diskUnknown = true;
      return false;
    }
  }

  bool _anyOwnedKeyStored() => _ownedKeys.any(_prefs.containsKey);

  /// Clears Little Bumpy's current and legacy keys on this device, leaving any
  /// other keys alone. Returns true only if storage, re-read after the
  /// removals, holds no owned key and no erase marker.
  ///
  /// 1. Persist the erase marker. If that fails, nothing is deleted.
  /// 2. Remove every owned key unconditionally (a failed removal already
  ///    looks gone in the cache, so a `containsKey` filter would skip it).
  /// 3. Reload from disk and verify every owned key is gone.
  /// 4. Only then remove the marker, and reload to confirm it is gone.
  /// A crash or failure anywhere leaves the marker, so the next start fails
  /// closed instead of showing a fresh setup over leftover data.
  Future<bool> clearAll() => _orderedWrite(() async {
    final marked = await _attempt(
      () => _prefs.setBool(AppConstants.prefsEraseInProgressKey, true),
    );
    if (!marked) {
      await _reloadFromDisk(); // learn whether the marker landed anyway
      return false;
    }
    await Future.wait([
      for (final key in _ownedKeys) _attempt(() => _prefs.remove(key)),
    ]);
    if (!await _reloadFromDisk() || _anyOwnedKeyStored()) return false;

    await _attempt(() => _prefs.remove(AppConstants.prefsEraseInProgressKey));
    if (!await _reloadFromDisk()) return false;
    return !_prefs.containsKey(AppConstants.prefsEraseInProgressKey) &&
        !_anyOwnedKeyStored();
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
