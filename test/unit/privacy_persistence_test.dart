import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/services/prefs_service.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/domain/models/skin_tone.dart';
import 'package:shared_preferences/shared_preferences.dart';

const marker = 'erase_in_progress';

/// Wraps the mock store ("disk") and fails or stalls chosen writes. Like the
/// legacy plugin, a failed write still changes the cache view; only
/// [reload] brings the cache back in line with disk.
class FlakyPrefs implements SharedPreferences {
  FlakyPrefs(this.disk);

  final SharedPreferences disk;
  final failRemove = <String>{};
  bool failPauseWrite = false;
  bool failMarkerWrite = false;
  bool failReload = false;
  String? rejectString;
  String? throwString;
  String? delayedString;
  Completer<void>? stringStarted;
  Completer<void>? stringGate;
  Completer<void>? pauseGate;
  Completer<void>? dailyGate;
  bool failDaily = false;
  bool throwDaily = false;
  final pauseWrites = <bool>[];
  final _cacheGone = <String>{};
  final _cacheBools = <String, bool>{}; // failed setBool still cached

  @override
  bool containsKey(String key) =>
      _cacheBools.containsKey(key) ||
      (!_cacheGone.contains(key) && disk.containsKey(key));
  @override
  Set<String> getKeys() => {
    ...disk.getKeys().difference(_cacheGone),
    ..._cacheBools.keys,
  };
  @override
  String? getString(String key) =>
      _cacheGone.contains(key) ? null : disk.getString(key);
  @override
  bool? getBool(String key) =>
      _cacheBools[key] ?? (_cacheGone.contains(key) ? null : disk.getBool(key));

  @override
  Future<void> reload() async {
    if (failReload) throw StateError('reload failed');
    _cacheGone.clear();
    _cacheBools.clear();
    await disk.reload();
  }

  @override
  List<String>? getStringList(String key) =>
      _cacheGone.contains(key) ? null : disk.getStringList(key);
  @override
  Future<bool> setString(String key, String value) async {
    if (key == delayedString) {
      stringStarted!.complete();
      await stringGate!.future;
    }
    if (key == rejectString) return false;
    if (key == throwString) throw StateError('profile write failed');
    _cacheGone.remove(key);
    return disk.setString(key, value);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    if (key == 'daily_needs_v2') {
      final gate = dailyGate;
      if (gate != null) await gate.future;
      if (throwDaily) throw StateError('daily save failed');
      if (failDaily) return false;
    }
    _cacheGone.remove(key);
    return disk.setStringList(key, value);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    if (key == 'is_paused') {
      final gate = pauseGate;
      if (gate != null) await gate.future;
      if (failPauseWrite) throw StateError('write failed');
      pauseWrites.add(value);
    }
    if (key == marker && failMarkerWrite) {
      _cacheBools[key] = value; // cache says written; disk is not
      throw StateError('marker write failed');
    }
    _cacheGone.remove(key);
    _cacheBools.remove(key);
    return disk.setBool(key, value);
  }

  @override
  Future<bool> remove(String key) async {
    _cacheGone.add(key);
    _cacheBools.remove(key);
    if (failRemove.contains(key)) throw StateError('remove failed');
    return disk.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences disk;
  late FlakyPrefs flaky;
  late AppState state;

  AppState coldBoot() => AppState.withPrefs(PrefsService.wrap(disk));

  Future<void> start(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    disk = await SharedPreferences.getInstance();
    flaky = FlakyPrefs(disk);
    state = AppState.withPrefs(
      PrefsService.wrap(flaky),
      now: () => DateTime(2026, 11, 23),
    );
  }

  const active = <String, Object>{
    'due_date_iso': '2027-05-10',
    'baby_nickname': 'Cub',
  };

  final initialDate = DateTime(2027, 4, 12);

  Future<bool> enter() => state.finishSetup(
    date: initialDate,
    halloween: false,
    tone: SkinTone.deep,
    nickname: ' Clover ',
  );

  test(
    'setup enters only when the profile and original date are saved',
    () async {
      await start({});
      flaky.throwString = 'baby_nickname';
      expect(await enter(), isFalse);
      expect(state.isFirstRun, isTrue);
      expect(disk.getString('due_date_iso'), isNull);
      flaky.throwString = null;
      flaky.rejectString = 'due_date_iso';
      expect(await enter(), isFalse);
      expect(state.isFirstRun, isTrue);
      expect(state.currentWeek, isNull);
      flaky.rejectString = null;
      expect(await enter(), isTrue);
      final restored = coldBoot();
      expect(restored.dueDate, initialDate);
      expect(restored.skinTone, SkinTone.deep);
      expect(restored.nickname, 'Clover');
      expect(restored.isHalloween, isFalse);
    },
  );

  test(
    'a rejected correction keeps both the week and its original anchor',
    () async {
      await start(active);
      final oldWeek = state.currentWeek;
      final oldCount = state.daysTogetherCount;
      flaky.rejectString = 'corrected_due_date_iso';
      expect(await state.saveDueDate(initialDate), isFalse);
      expect(state.currentWeek, oldWeek);
      expect(state.daysTogetherCount, oldCount);
      expect(coldBoot().dueDate, DateTime(2027, 5, 10));
      flaky.rejectString = null;
      expect(await state.saveDueDate(initialDate), isTrue);
      expect(state.currentWeek, isNot(oldWeek));
      expect(state.daysTogetherCount, oldCount);
    },
  );

  test(
    'rejected nickname stays editable and the saved name survives',
    () async {
      await start(active);
      flaky.rejectString = 'baby_nickname';
      expect(await state.saveNickname('Maple'), isFalse);
      expect(state.nickname, 'Cub');
      expect(coldBoot().nickname, 'Cub');
      flaky.rejectString = null;
      expect(await state.saveNickname('Maple'), isTrue);
      expect(coldBoot().nickname, 'Maple');
    },
  );

  for (final erase in [false, true]) {
    test(
      'interrupted setup stops before nickname and date (erase=$erase)',
      () async {
        await start({});
        flaky.delayedString = 'skin_tone';
        flaky.stringStarted = Completer<void>();
        flaky.stringGate = Completer<void>();
        final setup = enter();
        await flaky.stringStarted!.future;
        final privacy = erase ? state.eraseAll() : state.pause();
        flaky.stringGate!.complete();
        expect(await setup, isFalse);
        await privacy;
        expect(disk.getString('due_date_iso'), isNull);
        expect(disk.getString('baby_nickname'), isNull);
        expect(state.isFirstRun, isTrue);
        if (erase) {
          expect(disk.getKeys(), isEmpty);
        } else {
          expect(coldBoot().isPaused, isTrue);
        }
      },
    );
  }

  test(
    'rapid taps retain all choices across a failed save and retry',
    () async {
      await start(active);
      flaky.dailyGate = Completer<void>();
      flaky.failDaily = true;
      final writes = [
        for (final need in state.dailyCheckIns) state.toggleCheckIn(need.name),
      ];
      expect(state.allChecked, isTrue);
      expect(state.checkInStatus, CheckInSaveStatus.saving);
      flaky.dailyGate!.complete();
      await Future.wait(writes);
      expect(state.checkInStatus, CheckInSaveStatus.failed);
      expect(state.allChecked, isTrue);
      expect(disk.getStringList('daily_needs_v2'), isNull);
      flaky.failDaily = false;
      flaky.throwDaily = true;
      await state.retryCheckIns();
      expect(state.checkInStatus, CheckInSaveStatus.failed);
      flaky.throwDaily = false;
      await state.retryCheckIns();
      expect(state.checkInStatus, CheckInSaveStatus.saved);
      expect(disk.getStringList('daily_needs_v2'), [
        '2026-11-23',
        ...state.dailyCheckIns.map((need) => need.name),
      ]);
    },
  );

  testWidgets('Today shows saved only after a retry succeeds', (tester) async {
    await start(active);
    await tester.pumpWidget(LittleBumpyApp(state: state));
    await tester.pumpAndSettle();
    flaky.dailyGate = Completer<void>();
    flaky.failDaily = true;
    final writes = [
      for (final need in state.dailyCheckIns) state.toggleCheckIn(need.name),
    ];
    await tester.pump();
    expect(find.text('Saving check-ins…'), findsOneWidget);
    expect(find.text('Today’s check-ins are saved'), findsNothing);
    flaky.dailyGate!.complete();
    await Future.wait(writes);
    await tester.pumpAndSettle();
    final retry = find.text('Retry save');
    expect(retry, findsOneWidget);
    expect(find.text('Today’s check-ins are saved'), findsNothing);
    flaky.failDaily = false;
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('Today’s check-ins are saved'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('Start Fresh follows a delayed check-in on disk', () async {
    await start(active);
    flaky.dailyGate = Completer<void>();
    final checkIn = state.toggleCheckIn('water');
    final fresh = state.clearTodayCheckIns();
    flaky.dailyGate!.complete();
    await Future.wait([checkIn, fresh]);
    expect(state.completedCheckIns, isEmpty);
    expect(disk.getStringList('daily_needs_v2'), ['2026-11-23']);
  });

  test('yesterday’s failed write cannot mark today as unsaved', () async {
    await start(active);
    var now = DateTime(2026, 11, 23, 23, 59);
    state = AppState.withPrefs(PrefsService.wrap(flaky), now: () => now);
    flaky.dailyGate = Completer<void>();
    flaky.failDaily = true;
    final yesterday = state.toggleCheckIn('water');
    now = DateTime(2026, 11, 24);
    state.refreshDay();
    flaky.dailyGate!.complete();
    await yesterday;
    expect(state.completedCheckIns, isEmpty);
    expect(state.checkInStatus, CheckInSaveStatus.saved);
    flaky.failDaily = false;
    await state.toggleCheckIn('water');
    expect(disk.getStringList('daily_needs_v2'), ['2026-11-24', 'water']);
  });

  test('Erase finishes after in-flight check-in and visit writes', () async {
    await start(active);
    flaky.dailyGate = Completer<void>();
    final checkIn = state.toggleCheckIn('water');
    final visit = state.saveVisitTopics({state.todayNeed});
    final erase = state.eraseAll();
    flaky.dailyGate!.complete();
    await Future.wait([checkIn, visit]);
    expect(await erase, isTrue);
    expect(disk.getKeys(), isEmpty);
    expect(state.completedCheckIns, isEmpty);
    expect(state.visitTopics, isEmpty);
  });

  group('Pause persistence under failure', () {
    test('Pause hides at once and a failed write never un-hides', () async {
      await start(active);
      flaky
        ..pauseGate = Completer<void>()
        ..failPauseWrite = true;
      var notified = false;
      state.addListener(() => notified = true);

      final pending = state.pause();
      expect(state.isPaused, isTrue);
      expect(notified, isTrue);

      flaky.pauseGate!.complete();
      await pending; // the failure must not escape to the button
      expect(state.isPaused, isTrue);
      expect(state.pauseSavePending, isTrue);
      expect(coldBoot().isPaused, isFalse);

      flaky
        ..pauseGate = null
        ..failPauseWrite = false;
      await state.savePendingPause();
      expect(state.pauseSavePending, isFalse);
      expect(coldBoot().isPaused, isTrue);
    });

    test('a double tap on Pause cannot unpause', () async {
      await start(active);
      await Future.wait([state.pause(), state.pause()]);
      expect(state.isPaused, isTrue);
      expect(coldBoot().isPaused, isTrue);
    });

    test(
      'rapid Pause, Resume, Pause with a slow first write ends paused',
      () async {
        await start(active);
        flaky.pauseGate = Completer<void>();
        final writes = [state.pause(), state.resume(), state.pause()];
        expect(state.isPaused, isTrue);
        flaky.pauseGate!.complete();
        await Future.wait(writes);
        expect(flaky.pauseWrites, [true, false, true]);
        expect(coldBoot().isPaused, isTrue);
      },
    );

    test('Pause tapped during Start Fresh wins on disk', () async {
      await start({...active, 'is_paused': true});
      flaky.pauseGate = Completer<void>();
      final fresh = state.clearTodayCheckIns();
      final paused = state.pause();
      flaky.pauseGate!.complete();
      await Future.wait([fresh, paused]);
      expect(state.isPaused, isTrue);
      expect(coldBoot().isPaused, isTrue);
    });
  });

  group('Erase under failure', () {
    const everything = <String, Object>{
      ...active,
      'corrected_due_date_iso': '2027-05-17',
      'skin_tone': 'deep',
      'is_halloween': false,
      'daily_needs_v2': <String>['2026-11-23', 'water'],
      'checkin_ids': 'water',
      'checkin_date': '2026-11-23',
      'other_app_setting': 'preserved',
    };

    test('partial removal keeps the marker, restart fails closed, '
        'Resume is refused and retry finishes', () async {
      await start(everything);
      flaky.failRemove.add('baby_nickname');

      expect(await state.eraseAll(), isFalse);
      expect(state.isFirstRun, isFalse);
      expect(state.isPaused, isTrue);
      expect(state.eraseFailed, isTrue);
      expect(state.erasePending, isTrue);
      // Half erased on disk: due date gone, nickname left, marker still set.
      expect(disk.getString('due_date_iso'), isNull);
      expect(disk.getString('baby_nickname'), 'Cub');
      expect(disk.getBool(marker), isTrue);
      expect(disk.getString('other_app_setting'), 'preserved');

      // Restart: no due date on disk, yet no fresh setup over leftovers.
      final rebooted = coldBoot();
      expect(rebooted.isFirstRun, isFalse);
      expect(rebooted.isPaused, isTrue);
      expect(rebooted.erasePending, isTrue);
      expect(rebooted.eraseFailed, isTrue);

      // Failed resume: neither Resume nor Start Fresh can leave Pause.
      await state.resume();
      await state.clearTodayCheckIns();
      expect(state.isPaused, isTrue);
      expect(state.erasePending, isTrue);
      await rebooted.resume();
      expect(rebooted.isPaused, isTrue);

      // Retry. The cache claimed the key gone before; reload proved otherwise.
      flaky.failRemove.clear();
      expect(await state.eraseAll(), isTrue);
      expect(state.isFirstRun, isTrue);
      expect(state.isPaused, isFalse);
      expect(state.eraseFailed, isFalse);
      expect(state.erasePending, isFalse);
      expect(disk.getKeys(), {'other_app_setting'});
      expect(coldBoot().isFirstRun, isTrue);
    });

    test('a crash mid-Erase (marker plus leftovers) fails closed and the '
        'restarted app can retry', () async {
      await start({
        marker: true,
        'baby_nickname': 'Cub', // due date already removed before the crash
        'other_app_setting': 'preserved',
      });
      expect(state.isFirstRun, isFalse);
      expect(state.isPaused, isTrue);
      expect(state.erasePending, isTrue);
      await state.resume();
      expect(state.isPaused, isTrue);

      expect(await state.eraseAll(), isTrue);
      expect(state.isFirstRun, isTrue);
      expect(disk.getKeys(), {'other_app_setting'});
    });

    test('failed marker removal keeps the app closed until retry', () async {
      await start(everything);
      flaky.failRemove.add(marker);

      expect(await state.eraseAll(), isFalse);
      expect(state.erasePending, isTrue);
      expect(disk.getBool(marker), isTrue);
      expect(coldBoot().isFirstRun, isFalse);
      expect(coldBoot().isPaused, isTrue);

      flaky.failRemove.clear();
      expect(await state.eraseAll(), isTrue);
      expect(disk.getKeys(), {'other_app_setting'});
      expect(coldBoot().isFirstRun, isTrue);
    });

    test(
      'failed marker write deletes nothing; reload shows Resume is safe',
      () async {
        await start(everything);
        flaky.failMarkerWrite = true;

        expect(await state.eraseAll(), isFalse);
        expect(state.eraseFailed, isTrue);
        expect(state.erasePending, isFalse); // cache said set; disk said no
        expect(disk.getString('due_date_iso'), '2027-05-10');
        expect(disk.getString('baby_nickname'), 'Cub');
        expect(coldBoot().isPaused, isTrue);

        await state.resume();
        expect(state.isPaused, isFalse);
        expect(state.eraseFailed, isFalse);
      },
    );

    test('an unreadable disk after Erase fails closed', () async {
      await start(everything);
      flaky.failReload = true;

      expect(await state.eraseAll(), isFalse);
      expect(state.erasePending, isTrue);
      await state.resume();
      expect(state.isPaused, isTrue);
      expect(coldBoot().isFirstRun, isFalse);

      flaky.failReload = false;
      expect(await state.eraseAll(), isTrue);
      expect(state.isFirstRun, isTrue);
      expect(disk.getKeys(), {'other_app_setting'});
    });

    test('stale or rapid taps during Erase cannot undo it', () async {
      await start(everything);
      flaky.pauseGate = Completer<void>();
      final pausing = state.pause(); // write stalls
      final erase = state.eraseAll(); // queued behind it
      expect(identical(state.eraseAll(), erase), isTrue);

      await state.resume(); // ignored while erasing
      expect(state.isPaused, isTrue);
      final latePause = state.pause(); // ignored while erasing
      await state.clearTodayCheckIns(); // ignored while erasing
      expect(state.isPaused, isTrue);

      flaky.pauseGate!.complete();
      await pausing;
      await latePause;
      expect(await erase, isTrue);
      expect(flaky.pauseWrites, [true]);
      expect(disk.getKeys(), {'other_app_setting'});
      expect(state.isFirstRun, isTrue);
    });
  });
}
