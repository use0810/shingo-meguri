// Web版 js/logic.test.js と同じ内容を Dart で確かめる。
import 'package:flutter_test/flutter_test.dart';
import 'package:shingo_meguri/logic.dart';

String addDays(String key, int amount) {
  final p = key.split('-').map(int.parse).toList();
  return dateKey(DateTime(p[0], p[1], p[2] + amount));
}

void main() {
  test('catalog matches the prototype list', () {
    expect(spots.map((s) => s.name), ['キリストの墓', 'グリーンパーク', '新郷村役場', '新郷温泉館', '戸来三嶽神社', '西越三嶽神社']);
    expect(items.map((i) => i.name), [
      '郷のきみ',
      '飲むヨーグルト',
      '銀のカモ',
      '生キャラ煎餅',
      'キリスト',
      'イスキリ',
      'ドラキュラアイス',
      'さかさとち',
      '大石神ピラミッド',
      'みずばしょう',
    ]);
    expect(benefits[0].title, 'さとのきみ一本クーポン');
    expect(benefits[1].title, '20%オフクーポン');
    expect(benefits[1].kicker, '全コンプリート');
    expect(kTerm, '〇月から〇月までグリーンパークで使用可');
    expect(benefits[0].term, kTerm);
    expect(benefits[1].term, kTerm);
  });

  test("a scan gives that place's badge and one unduplicated item", () {
    const before = ShingoState();
    final result = scan(before, 'christ', '2026-11-08', rng: () => 0);
    expect(result.ok, isTrue);
    expect(result.spot!.name, 'キリストの墓');
    expect(result.badgeNew, isTrue);
    expect(result.item!.name, '郷のきみ');
    expect(result.state.obtainedBadges['christ'], '2026-11-08');
    expect(result.state.scans['christ'], '2026-11-08');
    expect(before.toJson(), const ShingoState().toJson());
  });

  test('the same place cannot be scanned again on the same day', () {
    final once = scan(const ShingoState(), 'onsen', '2026-11-08', rng: () => 0.2);
    final before = once.state.toJson();
    final twice = scan(once.state, 'onsen', '2026-11-08', rng: () => 0.2);
    expect(twice.ok, isFalse);
    expect(twice.reason, 'already-scanned');
    expect(identical(twice.state, once.state), isTrue);
    expect(once.state.toJson(), before);
  });

  test('another place can be scanned the same day', () {
    final first = scan(const ShingoState(), 'christ', '2026-11-08', rng: () => 0);
    final second = scan(first.state, 'green', '2026-11-08', rng: () => 0);
    expect(second.ok, isTrue);
    expect(second.badgeNew, isTrue);
    expect(second.item!.id, isNot(first.item!.id));
  });

  test('the next day gives an item even when the badge is already owned', () {
    final first = scan(const ShingoState(), 'herai', '2026-11-08', rng: () => 0);
    final second = scan(first.state, 'herai', '2026-11-09', rng: () => 0);
    expect(second.ok, isTrue);
    expect(second.badgeNew, isFalse);
    expect(second.state.obtainedBadges['herai'], '2026-11-08');
    expect(second.item, isNotNull);
    expect(second.item!.id, isNot(first.item!.id));
  });

  test('items never duplicate and stop after the tenth', () {
    var state = const ShingoState();
    var day = '2026-11-01';
    final seen = <String>[];
    for (var n = 0; n < 12; n++) {
      final spotId = spots[n % spots.length].id;
      if (state.scans[spotId] == day) day = addDays(day, 1);
      final result = scan(state, spotId, day, rng: () => 0.99);
      expect(result.ok, isTrue);
      if (result.item != null) seen.add(result.item!.id);
      state = result.state;
    }
    expect(seen.toSet().length, 10);
    expect(seen.length, 10);
    expect(progress(state).items, 10);
    expect(progress(state).badges, 6);
  });

  test('random draws stay inside the remaining items', () {
    for (var seed = 0; seed < 20; seed++) {
      var state = const ShingoState();
      var day = '2026-11-01';
      final seen = <String>[];
      double rng() => ((seed * 13 + seen.length * 7) % 100) / 100;
      for (var n = 0; n < 10; n++) {
        final spotId = spots[n % spots.length].id;
        if (state.scans[spotId] == day) day = addDays(day, 1);
        final result = scan(state, spotId, day, rng: rng);
        expect(result.ok, isTrue);
        expect(result.item, isNotNull);
        seen.add(result.item!.id);
        state = result.state;
      }
      expect(seen.toSet().length, 10);
    }
  });

  test('郷のきみ unlocks only the single-item coupon', () {
    final state = armSato(const ShingoState());
    final result = scan(state, 'green', '2026-11-08', rng: () => 0.99);
    expect(result.item!.id, 'sato');
    expect(result.unlocked.map((b) => b.id), ['sato']);
    expect(result.state.demoForceItemId, isNull);
    expect(isUnlocked(result.state, 'complete'), isFalse);
  });

  test('a failed rescan keeps the forced item armed', () {
    final scanned = scan(const ShingoState(), 'christ', '2026-11-08', rng: () => 0.4);
    final armed = scanned.state.copyWith(demoForceItemId: 'sato');
    final denied = scan(armed, 'christ', '2026-11-08', rng: () => 0);
    expect(denied.ok, isFalse);
    expect(identical(denied.state, armed), isTrue);
  });

  test('full completion requires every badge and every item', () {
    var state = const ShingoState();
    var day = '2026-11-01';
    for (var n = 0; n < 10; n++) {
      final spotId = spots[n % 5].id;
      if (state.scans[spotId] == day) day = addDays(day, 1);
      state = scan(state, spotId, day, rng: () => 0).state;
    }
    expect(progress(state).badges, 5);
    expect(progress(state).items, 10);
    expect(isUnlocked(state, 'sato'), isTrue);
    expect(isUnlocked(state, 'complete'), isFalse);
  });

  test('the scan that finishes both collections unlocks the 20% coupon', () {
    const today = '2026-11-08';
    final state = ShingoState(
      obtainedBadges: {for (final s in spots) s.id: today},
      obtainedItems: {for (final i in items) if (i.id != 'sato') i.id: today},
    );
    final before = state.toJson();
    final result = scan(state, 'nishikoshi', today, rng: () => 0.5);
    expect(result.item!.id, 'sato');
    expect(result.unlocked.map((b) => b.id).toList()..sort(), ['complete', 'sato']);
    expect(state.toJson(), before);
  });

  test('staff can mark an unlocked coupon consumed once', () {
    final granted = grantAll(const ShingoState(), '2026-11-08');
    expect(granted.scans, isEmpty);
    final locked = consume(const ShingoState(), 'sato', '2026-11-08');
    expect(locked.ok, isFalse);
    final used = consume(granted, 'complete', '2026-11-08');
    expect(used.ok, isTrue);
    expect(used.state.consumed['complete'], '2026-11-08');
    final again = consume(used.state, 'complete', '2026-11-09');
    expect(again.ok, isFalse);
    expect(again.reason, 'consumed');
  });

  test('the demo date moves forward on the local calendar', () {
    final now = DateTime(2026, 11, 8, 23, 30);
    final state = advanceDay(const ShingoState());
    expect(currentDateKey(state, now: now), '2026-11-09');
    expect(formatDisplay('2026-11-09'), '11月9日');
  });

  test('month and year boundaries roll over', () {
    expect(addDays('2026-12-31', 1), '2027-01-01');
    expect(addDays('2027-02-28', 1), '2027-03-01');
  });

  test('saved data survives a round trip and ignores broken fields', () {
    final state = scan(armSato(const ShingoState()), 'christ', '2026-11-08').state;
    final restored = ShingoState.fromJson(state.toJson());
    expect(restored.toJson(), state.toJson());

    final broken = ShingoState.fromJson({
      'obtainedBadges': {'christ': 3, 'green': '2026-11-08'},
      'obtainedItems': 'oops',
      'demoDayOffset': 'x',
      'demoForceItemId': 'yogurt',
    });
    expect(broken.obtainedBadges, {'green': '2026-11-08'});
    expect(broken.obtainedItems, isEmpty);
    expect(broken.demoDayOffset, 0);
    expect(broken.demoForceItemId, isNull);
    expect(ShingoState.fromJson(null).toJson(), const ShingoState().toJson());
  });

  group('QR codes', () {
    test('the printed format is read', () {
      expect(spotIdFromQr('shingo-meguri:spot:christ'), 'christ');
      expect(spotIdFromQr('  SHINGO-MEGURI:SPOT:Onsen \n'), 'onsen');
    });

    test('web links are read too', () {
      expect(spotIdFromQr('https://example.jp/spot/nishikoshi'), 'nishikoshi');
      expect(spotIdFromQr('https://example.jp/?spot=green'), 'green');
    });

    test('other codes are rejected', () {
      expect(spotIdFromQr('shingo-meguri:spot:tokyo'), isNull);
      expect(spotIdFromQr('https://example.com'), isNull);
      expect(spotIdFromQr(''), isNull);
    });
  });
}
