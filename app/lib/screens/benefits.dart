import 'package:flutter/material.dart';

import '../logic.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';

class BenefitsPage extends StatelessWidget {
  const BenefitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = StoreScope.of(context).state;
    final prog = progress(state);
    final note = prog.benefits < prog.benefitTotal
        ? '条件を達成すると、クーポンが届きます。'
        : '受け取ったクーポンです。使うときは、担当者が消費済みにします。';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead('特典', count: prog.benefits, total: prog.benefitTotal),
        const SizedBox(height: 8),
        Note(note),
        const SizedBox(height: 16),
        for (final benefit in benefits) ...[
          if (benefit != benefits.first) const SizedBox(height: 14),
          isUnlocked(state, benefit.id)
              ? _Coupon(benefit: benefit, usedOn: state.consumed[benefit.id])
              : _LockedCoupon(benefit: benefit, hint: _lockHint(state, benefit.id)),
        ],
      ],
    );
  }

  static String _lockHint(ShingoState state, String id) {
    if (id == 'sato') return 'アイテム「郷のきみ」を手に入れると届きます';
    final prog = progress(state);
    final b = prog.badgeTotal - prog.badges;
    final i = prog.itemTotal - prog.items;
    final parts = [if (b > 0) 'バッジあと$bつ', if (i > 0) 'アイテムあと$i個'];
    return '全部集めると届きます（${parts.join('・')}）';
  }
}

class _Coupon extends StatelessWidget {
  const _Coupon({required this.benefit, required this.usedOn});
  final Benefit benefit;
  final String? usedOn;

  Future<void> _consume(BuildContext context) async {
    final ok = await confirmSheet(
      context,
      title: '消費済みにしますか',
      lines: [benefit.title, '担当者が操作してください。消費済みにすると、このクーポンは使えなくなります。'],
      confirm: '消費済みにする',
    );
    if (ok && context.mounted) StoreScope.read(context).consumeBenefit(benefit.id);
  }

  @override
  Widget build(BuildContext context) {
    final complete = benefit.id == 'complete';
    final used = usedOn != null;
    final fg = complete ? Colors.white : const Color(0xFF4A2D0C);

    Widget card = Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, used ? 20 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: complete
              ? const [Color(0xFFF37A55), Color(0xFFD9433A)]
              : const [Color(0xFFFFCF5C), Color(0xFFF6A23C)],
        ),
        boxShadow: [
          BoxShadow(
            color: complete ? const Color(0x4DD9433A) : const Color(0x4DF6A23C),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pill(benefit.kicker, bg: const Color(0xB3FFFFFF), fg: const Color(0xFF6B4212)),
          const SizedBox(height: 8),
          Text(benefit.title, style: ts(complete ? 28 : 23, weight: FontWeight.w900, color: fg, height: 1.35)),
          const SizedBox(height: 14),
          const DashedLine(color: Color(0xB3FFFFFF)),
          const SizedBox(height: 12),
          Text(benefit.term, style: ts(13, color: fg, height: 1.7)),
          if (used)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('${formatDisplay(usedOn!)}に消費済み', style: ts(13, weight: FontWeight.w700, color: fg)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Pressable(
                onTap: () => _consume(context),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 46),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xE6FFFFFF), borderRadius: BorderRadius.circular(14)),
                  child: Text(
                    '担当者が消費済みにする',
                    style: ts(15,
                        weight: FontWeight.w700,
                        ls: 0.04,
                        color: complete ? const Color(0xFFB63A30) : const Color(0xFF6B4212)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (used) {
      card = Opacity(
        opacity: 0.85,
        child: ColorFiltered(colorFilter: cssFilter(gray: 0.75), child: card),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        // チケットの切り欠き
        const Positioned(left: -11, top: 75, child: _Notch()),
        const Positioned(right: -11, top: 75, child: _Notch()),
        if (used)
          Positioned(
            right: 18,
            top: 18,
            child: Transform.rotate(
              angle: -0.175,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xD9FFFFFF),
                  border: Border.all(color: C.torii, width: 3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('消費済み', style: ts(16, weight: FontWeight.w900, color: C.torii, ls: 0.12)),
              ),
            ),
          ),
      ],
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch();

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: C.bg),
      );
}

class _LockedCoupon extends StatelessWidget {
  const _LockedCoupon({required this.benefit, required this.hint});
  final Benefit benefit;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return DashedBox(
      radius: 20,
      fill: C.paper,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: const AppIcon(Ic.lock, size: 24, color: Color(0xFFB4A48D)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pill(benefit.kicker, bg: Colors.white, fg: C.muted),
                const SizedBox(height: 8),
                Text('？？？ クーポン', style: ts(19, weight: FontWeight.w900, color: const Color(0xFFB4A48D), height: 1.35)),
                const SizedBox(height: 14),
                const DashedLine(color: Color(0xFFE3D6C2)),
                const SizedBox(height: 12),
                Text(hint, style: ts(13, color: C.muted, height: 1.7)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
