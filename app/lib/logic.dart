// 集める・届く・使う のルール。画面には依存しない（Web版 js/logic.js と同じ内容）。

import 'dart:math';

const String kTerm = '〇月から〇月までグリーンパークで使用可';

class Spot {
  const Spot(this.id, this.name);
  final String id;
  final String name;
}

class Item {
  const Item(this.id, this.name);
  final String id;
  final String name;
}

class Benefit {
  const Benefit({
    required this.id,
    required this.title,
    required this.kicker,
    required this.term,
  });
  final String id;
  final String title;
  final String kicker;
  final String term;
}

const List<Spot> spots = [
  Spot('christ', 'キリストの墓'),
  Spot('green', 'グリーンパーク'),
  Spot('office', '新郷村役場'),
  Spot('onsen', '新郷温泉館'),
  Spot('herai', '戸来三嶽神社'),
  Spot('nishikoshi', '西越三嶽神社'),
];

const List<Item> items = [
  Item('sato', '郷のきみ'),
  Item('yogurt', '飲むヨーグルト'),
  Item('duck', '銀のカモ'),
  Item('senbei', '生キャラ煎餅'),
  Item('christ-item', 'キリスト'),
  Item('isukiri', 'イスキリ'),
  Item('dracula', 'ドラキュラアイス'),
  Item('sakasa', 'さかさとち'),
  Item('pyramid', '大石神ピラミッド'),
  Item('mizubasho', 'みずばしょう'),
];

const List<Benefit> benefits = [
  Benefit(id: 'sato', title: 'さとのきみ一本クーポン', kicker: '郷のきみを獲得', term: kTerm),
  Benefit(id: 'complete', title: '20%オフクーポン', kicker: '全コンプリート', term: kTerm),
];

/// 端末に保存する収集記録。値は「獲得した日（yyyy-mm-dd）」。
class ShingoState {
  const ShingoState({
    this.obtainedBadges = const {},
    this.obtainedItems = const {},
    this.scans = const {},
    this.consumed = const {},
    this.demoDayOffset = 0,
    this.demoForceItemId,
  });

  final Map<String, String> obtainedBadges;
  final Map<String, String> obtainedItems;

  /// 地点ごとの「最後に読み取った日」
  final Map<String, String> scans;
  final Map<String, String> consumed;
  final int demoDayOffset;
  final String? demoForceItemId;

  ShingoState copyWith({
    Map<String, String>? obtainedBadges,
    Map<String, String>? obtainedItems,
    Map<String, String>? scans,
    Map<String, String>? consumed,
    int? demoDayOffset,
    String? demoForceItemId,
    bool clearForce = false,
  }) {
    return ShingoState(
      obtainedBadges: obtainedBadges ?? this.obtainedBadges,
      obtainedItems: obtainedItems ?? this.obtainedItems,
      scans: scans ?? this.scans,
      consumed: consumed ?? this.consumed,
      demoDayOffset: demoDayOffset ?? this.demoDayOffset,
      demoForceItemId: clearForce ? null : (demoForceItemId ?? this.demoForceItemId),
    );
  }

  Map<String, Object?> toJson() => {
        'obtainedBadges': obtainedBadges,
        'obtainedItems': obtainedItems,
        'scans': scans,
        'consumed': consumed,
        'demoDayOffset': demoDayOffset,
        'demoForceItemId': demoForceItemId,
      };

  /// 壊れた保存データでも落ちないよう、形の合う値だけを拾う。
  factory ShingoState.fromJson(Object? raw) {
    if (raw is! Map) return const ShingoState();
    Map<String, String> dates(Object? value) {
      if (value is! Map) return const {};
      final out = <String, String>{};
      value.forEach((key, date) {
        if (key is String && date is String) out[key] = date;
      });
      return Map.unmodifiable(out);
    }

    final offset = raw['demoDayOffset'];
    return ShingoState(
      obtainedBadges: dates(raw['obtainedBadges']),
      obtainedItems: dates(raw['obtainedItems']),
      scans: dates(raw['scans']),
      consumed: dates(raw['consumed']),
      demoDayOffset: offset is int ? offset : 0,
      demoForceItemId: raw['demoForceItemId'] == 'sato' ? 'sato' : null,
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

String dateKey(DateTime date) => '${date.year}-${_two(date.month)}-${_two(date.day)}';

/// 端末の現地時刻で「今日」を決める（デモ用に日付を進められる）。
String currentDateKey(ShingoState state, {DateTime? now}) {
  final n = now ?? DateTime.now();
  return dateKey(DateTime(n.year, n.month, n.day + state.demoDayOffset));
}

String formatDisplay(String key) {
  final parts = key.split('-');
  if (parts.length < 3) return key;
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (m == null || d == null) return key;
  return '$m月$d日';
}

ShingoState advanceDay(ShingoState state) =>
    state.copyWith(demoDayOffset: state.demoDayOffset + 1);

ShingoState armSato(ShingoState state) {
  if (state.obtainedItems.containsKey('sato')) return state;
  return state.copyWith(demoForceItemId: 'sato');
}

bool isUnlocked(ShingoState state, String id) {
  if (id == 'sato') return state.obtainedItems.containsKey('sato');
  if (id == 'complete') {
    final badgesDone = spots.every((spot) => state.obtainedBadges.containsKey(spot.id));
    final itemsDone = items.every((item) => state.obtainedItems.containsKey(item.id));
    return badgesDone && itemsDone;
  }
  return false;
}

class Progress {
  const Progress({
    required this.badges,
    required this.badgeTotal,
    required this.items,
    required this.itemTotal,
    required this.benefits,
    required this.benefitTotal,
  });
  final int badges;
  final int badgeTotal;
  final int items;
  final int itemTotal;
  final int benefits;
  final int benefitTotal;
}

Progress progress(ShingoState state) => Progress(
      badges: spots.where((spot) => state.obtainedBadges.containsKey(spot.id)).length,
      badgeTotal: spots.length,
      items: items.where((item) => state.obtainedItems.containsKey(item.id)).length,
      itemTotal: items.length,
      benefits: benefits.where((benefit) => isUnlocked(state, benefit.id)).length,
      benefitTotal: benefits.length,
    );

List<Benefit> newlyUnlocked(ShingoState before, ShingoState after) => benefits
    .where((benefit) => isUnlocked(after, benefit.id) && !isUnlocked(before, benefit.id))
    .toList();

class ScanResult {
  const ScanResult.fail(this.reason, this.state)
      : ok = false,
        spot = null,
        badgeNew = false,
        item = null,
        unlocked = const [];

  const ScanResult.success({
    required Spot this.spot,
    required this.badgeNew,
    required this.item,
    required this.unlocked,
    required this.state,
  })  : ok = true,
        reason = null;

  final bool ok;

  /// 'unknown-spot' または 'already-scanned'
  final String? reason;
  final Spot? spot;
  final bool badgeNew;

  /// すべて揃っているときは null
  final Item? item;
  final List<Benefit> unlocked;
  final ShingoState state;
}

final Random _random = Random();

/// QR を読み取ったときの処理。バッジと、まだ持っていないアイテムを1つ渡す。
ScanResult scan(ShingoState state, String spotId, String today, {double Function()? rng}) {
  final match = spots.where((entry) => entry.id == spotId);
  if (match.isEmpty) return ScanResult.fail('unknown-spot', state);
  final spot = match.first;
  if (state.scans[spotId] == today) return ScanResult.fail('already-scanned', state);

  final random = rng ?? _random.nextDouble;
  final remaining = items.where((item) => !state.obtainedItems.containsKey(item.id)).toList();
  Item? item;
  if (remaining.isNotEmpty) {
    final forced = remaining.where((entry) => entry.id == state.demoForceItemId);
    if (forced.isNotEmpty) {
      item = forced.first;
    } else {
      var index = (random() * remaining.length).floor();
      if (index < 0 || index >= remaining.length) index = 0;
      item = remaining[index];
    }
  }

  final badges = {...state.obtainedBadges};
  final owned = {...state.obtainedItems};
  final badgeNew = !badges.containsKey(spotId);
  if (badgeNew) badges[spotId] = today;
  if (item != null) owned[item.id] = today;

  final next = ShingoState(
    obtainedBadges: Map.unmodifiable(badges),
    obtainedItems: Map.unmodifiable(owned),
    scans: Map.unmodifiable({...state.scans, spotId: today}),
    consumed: state.consumed,
    demoDayOffset: state.demoDayOffset,
  );

  return ScanResult.success(
    spot: spot,
    badgeNew: badgeNew,
    item: item,
    unlocked: newlyUnlocked(state, next),
    state: next,
  );
}

class ConsumeResult {
  const ConsumeResult(this.ok, this.reason, this.state);
  final bool ok;
  final String? reason;
  final ShingoState state;
}

/// 担当者がクーポンを消費済みにする。
ConsumeResult consume(ShingoState state, String id, String today) {
  if (!benefits.any((benefit) => benefit.id == id)) return ConsumeResult(false, 'unknown', state);
  if (!isUnlocked(state, id)) return ConsumeResult(false, 'locked', state);
  if (state.consumed.containsKey(id)) return ConsumeResult(false, 'consumed', state);
  if (today.isEmpty) return ConsumeResult(false, 'no-date', state);
  return ConsumeResult(
    true,
    null,
    state.copyWith(consumed: Map.unmodifiable({...state.consumed, id: today})),
  );
}

ShingoState grantAll(ShingoState state, String today) {
  final badges = {...state.obtainedBadges};
  final owned = {...state.obtainedItems};
  for (final spot in spots) {
    badges.putIfAbsent(spot.id, () => today);
  }
  for (final item in items) {
    owned.putIfAbsent(item.id, () => today);
  }
  return state.copyWith(
    obtainedBadges: Map.unmodifiable(badges),
    obtainedItems: Map.unmodifiable(owned),
    clearForce: true,
  );
}

/// QR の中身から地点IDを取り出す。
///
/// 看板に印刷する QR は `shingo-meguri:spot:christ` の形にする。
/// 将来 Web ページに飛ばす場合に備えて `https://…/spot/christ` や `?spot=christ` も受け付ける。
String? spotIdFromQr(String raw) {
  final match = RegExp(r'spot[:/=]([a-z0-9-]+)', caseSensitive: false).firstMatch(raw.trim());
  if (match == null) return null;
  final id = match.group(1)!.toLowerCase();
  return spots.any((spot) => spot.id == id) ? id : null;
}
