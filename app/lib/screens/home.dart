import 'package:flutter/material.dart';

import '../data.dart';
import '../logic.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import 'shell.dart' show Section;

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onGo, required this.onScan});
  final ValueChanged<Section> onGo;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final state = store.state;
    final today = store.today();
    final prog = progress(state);
    final visited = spots.where((spot) => state.scans[spot.id] == today).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            const _Hero(),
            Padding(
              // カードを写真に少し重ねる
              padding: const EdgeInsets.fromLTRB(16, 196 - 18, 16, 0),
              child: _StampCard(state: state, prog: prog),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              _QrCta(onTap: onScan),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                child: Text(
                  'QRを読み取ると、その地点のバッジと、アイテムが1つ届きます。同じ地点は1日1回です。',
                  style: ts(12, color: C.muted, height: 1.7),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Tile(
                      icon: Ic.item,
                      iconBg: const Color(0xFFFFF1D1),
                      iconColor: const Color(0xFFC98A1B),
                      label: 'アイテム',
                      count: prog.items,
                      total: prog.itemTotal,
                      onTap: () => onGo(Section.items),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Tile(
                      icon: Ic.benefit,
                      iconBg: const Color(0xFFFFE3DC),
                      iconColor: C.torii,
                      label: '特典',
                      count: prog.benefits,
                      total: prog.benefitTotal,
                      onTap: () => onGo(Section.benefits),
                    ),
                  ),
                ],
              ),
              const BlockTitle('今日の読み取り'),
              if (visited.isEmpty)
                DashedBox(
                  color: const Color(0xFFE3D6C2),
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '今日はまだ読み取っていません。\n近くのスポットでQRを探してみよう！',
                    textAlign: TextAlign.center,
                    style: ts(13, color: C.muted, height: 1.8),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final spot in visited) _Chip(spot: spot)],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  static const double height = 196;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, box) {
            // Web版の background: 62% 30% / 190% auto と同じ切り取り方
            final w = box.maxWidth;
            final iw = w * 1.9;
            final ih = iw * kMapH / kMapW;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: (w - iw) * 0.62,
                  top: (height - ih) * 0.30,
                  width: iw,
                  height: ih,
                  child: Image.asset(kMapAsset, fit: BoxFit.fill),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.3, 1],
                      colors: [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x9E283C1E)],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Pill('青森県 新郷村へ ようこそ', bg: C.sun, fg: C.brown),
                      const SizedBox(height: 6),
                      Text(
                        'スポットをめぐって\nバッジを集めよう',
                        style: ts(24, weight: FontWeight.w900, color: Colors.white, ls: 0.04, height: 1.4)
                            .copyWith(shadows: const [Shadow(color: Color(0x59000000), blurRadius: 8, offset: Offset(0, 2))]),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StampCard extends StatelessWidget {
  const _StampCard({required this.state, required this.prog});
  final ShingoState state;
  final Progress prog;

  @override
  Widget build(BuildContext context) {
    final left = prog.badgeTotal - prog.badges;
    final rows = <Widget>[];
    for (var i = 0; i < spots.length; i += 3) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var j = i; j < i + 3; j++)
            Expanded(child: j < spots.length ? _StampSlot(spot: spots[j], state: state) : const SizedBox()),
        ],
      ));
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text('スタンプ帳', style: ts(17, weight: FontWeight.w900, ls: 0.06))),
              CountText(prog.badges, prog.badgeTotal),
            ],
          ),
          const SizedBox(height: 14),
          ...rows,
          const SizedBox(height: 12),
          ProgressBar(prog.badges / prog.badgeTotal),
          const SizedBox(height: 10),
          Text.rich(
            textAlign: TextAlign.center,
            left > 0
                ? TextSpan(children: [
                    const TextSpan(text: 'あと '),
                    TextSpan(text: '$left', style: ts(18, weight: FontWeight.w900, color: C.torii)),
                    const TextSpan(text: ' か所でバッジコンプリート！'),
                  ])
                : const TextSpan(text: 'バッジコンプリート！おめでとうございます'),
            style: ts(14, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StampSlot extends StatelessWidget {
  const _StampSlot({required this.spot, required this.state});
  final Spot spot;
  final ShingoState state;

  @override
  Widget build(BuildContext context) {
    final got = state.obtainedBadges.containsKey(spot.id);
    return Semantics(
      label: got ? '${spot.name}（獲得済み）' : '未獲得',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              SpotArt(spot.id, size: 72, look: got ? ArtLook.normal : ArtLook.faded),
              const SizedBox(height: 4),
              Text(
                got ? spot.name : '？？？',
                textAlign: TextAlign.center,
                style: ts(11, weight: FontWeight.w700, color: got ? C.ink : C.lockedText, height: 1.3),
              ),
            ],
          ),
          if (got)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Transform.translate(
                  offset: const Offset(29, 0),
                  child: Transform.rotate(angle: -0.244, child: const _DoneSeal(size: 34, font: 15)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 「済」の丸いはんこ
class _DoneSeal extends StatelessWidget {
  const _DoneSeal({required this.size, required this.font});
  final double size;
  final double font;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xD9FFFFFF),
        border: Border.all(color: C.torii, width: 2.5),
      ),
      child: Text('済', style: ts(font, weight: FontWeight.w900, color: C.torii, height: 1)),
    );
  }
}

class _QrCta extends StatelessWidget {
  const _QrCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF06A43), C.torii],
          ),
          boxShadow: const [BoxShadow(color: Color(0x59E2563B), blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const AppIcon(Ic.qr, size: 30, color: C.torii),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QRを読み込む', style: ts(19, weight: FontWeight.w900, color: Colors.white, ls: 0.06, height: 1.35)),
                  Text('スポットにあるQRコードをスキャン',
                      style: ts(12, color: Colors.white.withValues(alpha: 0.92), height: 1.35)),
                ],
              ),
            ),
            const AppIcon(Ic.chevron, size: 22, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.total,
    required this.onTap,
  });

  final String icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final int count;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18), boxShadow: kShadow),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
              child: AppIcon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ts(12, weight: FontWeight.w700, color: C.muted)),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '$count', style: ts(22, weight: FontWeight.w900, height: 1.2)),
                    TextSpan(text: '/$total', style: ts(13, color: C.muted)),
                  ])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.spot});
  final Spot spot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
      decoration: BoxDecoration(color: C.leafSoft, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpotArt(spot.id, size: 32, border: 2, shadow: false),
          const SizedBox(width: 8),
          Text(spot.name, style: ts(14, weight: FontWeight.w700, color: C.leafDark)),
        ],
      ),
    );
  }
}
