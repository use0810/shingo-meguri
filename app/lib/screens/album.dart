import 'package:flutter/material.dart';

import '../logic.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// バッジ一覧・アイテム一覧
class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key, required this.badges});
  final bool badges;

  @override
  Widget build(BuildContext context) {
    final state = StoreScope.of(context).state;
    final entries = badges
        ? [for (final s in spots) (s.id, s.name)]
        : [for (final i in items) (i.id, i.name)];
    final owned = badges ? state.obtainedBadges : state.obtainedItems;
    final count = entries.where((e) => owned.containsKey(e.$1)).length;
    final note = count < entries.length
        ? (badges ? 'スポットでQRを読み取るとバッジが手に入ります。' : 'QRを読み取るたびに、アイテムが1つ届きます。')
        : 'すべて集まっています。おめでとうございます！';

    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var j = i; j < i + 2; j++) ...[
              if (j > i) const SizedBox(width: 12),
              Expanded(
                child: j < entries.length
                    ? _Cell(id: entries[j].$1, name: entries[j].$2, date: owned[entries[j].$1], badge: badges)
                    : const SizedBox(),
              ),
            ],
          ],
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(badges ? 'バッジ' : 'アイテム', count: count, total: entries.length),
        const SizedBox(height: 12),
        ProgressBar(count / entries.length),
        const SizedBox(height: 8),
        Note(note),
        const SizedBox(height: 16),
        ...rows,
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.id, required this.name, required this.date, required this.badge});
  final String id;
  final String name;
  final String? date;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final got = date != null;
    final Widget pic = badge
        ? SpotArt(id, size: 92, border: 4, look: got ? ArtLook.normal : ArtLook.dark)
        : Hanko(id, locked: !got);

    return Semantics(
      label: got ? '$name、${formatDisplay(date!)} 獲得' : '未獲得',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 170),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: got && badge ? null : (got ? C.card : const Color(0xFFF6EFE3)),
          gradient: got && badge
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.55],
                  colors: [Color(0xFFEEF8E6), C.card],
                )
              : null,
          boxShadow: got ? kShadow : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 18, 10, 14),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (got)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.85, end: 1),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        builder: (context, s, child) => Transform.scale(scale: s, child: child),
                        child: pic,
                      )
                    else
                      pic,
                    const SizedBox(height: 10),
                    Text(
                      got ? name : '？？？',
                      textAlign: TextAlign.center,
                      style: ts(15,
                          weight: got ? FontWeight.w900 : FontWeight.w700,
                          color: got ? C.ink : C.lockedText,
                          height: 1.4),
                    ),
                    if (got) Text('${formatDisplay(date!)} 獲得', style: ts(11, color: C.muted)),
                  ],
                ),
              ),
            ),
            if (got && !badge && id == 'sato')
              Positioned(
                top: 12,
                right: -30,
                child: Transform.rotate(
                  angle: 0.698,
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    color: C.sun,
                    alignment: Alignment.center,
                    child: Text('特典つき', style: ts(11, weight: FontWeight.w900, color: C.brown)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
