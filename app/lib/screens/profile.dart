import 'package:flutter/material.dart';

import '../logic.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shell.dart' show Section;

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onGo});
  final ValueChanged<Section> onGo;

  @override
  Widget build(BuildContext context) {
    final state = StoreScope.of(context).state;
    final prog = progress(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead('マイページ'),
        const SizedBox(height: 10),
        const Note('記録はこのスマホの中に保存しています。電波の届かない場所でも、このまま使えます。'),
        const SizedBox(height: 18),
        Row(
          children: [
            _Stat(label: 'バッジ', count: prog.badges, total: prog.badgeTotal),
            const SizedBox(width: 8),
            _Stat(label: 'アイテム', count: prog.items, total: prog.itemTotal),
            const SizedBox(width: 8),
            _Stat(label: '特典', count: prog.benefits, total: prog.benefitTotal),
          ],
        ),
        const SizedBox(height: 18),
        const _Rules(),
        if (kDemo) ...[
          const SizedBox(height: 22),
          _DemoPanel(onGo: onGo),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.count, required this.total});
  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18), boxShadow: kShadow),
        child: Column(
          children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: '$count', style: ts(30, weight: FontWeight.w900, color: C.leafDark, height: 1)),
              TextSpan(text: '/$total', style: ts(12, color: C.muted)),
            ])),
            const SizedBox(height: 6),
            Text(label, style: ts(12, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules();

  @override
  Widget build(BuildContext context) {
    final sato = benefits[0];
    final complete = benefits[1];
    final lines = [
      '郷のきみを獲得すると、「${sato.title}」',
      'バッジ${spots.length}つとアイテム${items.length}個をすべて集めると、「${complete.title}」',
      'どちらも、$kTerm',
      '使うときは、担当者が消費済みにします',
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('特典の内容', style: ts(17, weight: FontWeight.w900, ls: 0.06)),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('・', style: ts(14, weight: FontWeight.w900, color: C.leaf, height: 1.7)),
                  Expanded(child: Text(line, style: ts(14, height: 1.7))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 動作確認用の操作。リリースビルドでは表示しない（store.dart の kDemo）。
class _DemoPanel extends StatelessWidget {
  const _DemoPanel({required this.onGo});
  final ValueChanged<Section> onGo;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final state = store.state;
    final today = store.today();
    final offset = state.demoDayOffset;
    final satoOwned = state.obtainedItems.containsKey('sato');
    final armed = state.demoForceItemId == 'sato';
    final complete = isUnlocked(state, 'complete');
    final forceLabel = satoOwned
        ? '郷のきみは所持済み'
        : armed
            ? '次は郷のきみを出します'
            : '次の1回は郷のきみを出す';
    final muted = ts(13, color: C.muted, height: 1.7);

    return DashedBox(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('デモ用', style: ts(14, weight: FontWeight.w900, color: C.muted, ls: 0.1)),
          const SizedBox(height: 8),
          Text('動作確認用の操作です。リリース版には出しません。', style: muted),
          Text(
            offset == 0
                ? '基準日は${formatDisplay(today)}です。'
                : '基準日は${formatDisplay(today)}です。日付を$offset日進めています。',
            style: muted,
          ),
          if (armed)
            Text('次の読み取りでは、郷のきみを出します。',
                style: ts(13, weight: FontWeight.w700, color: C.leafDark, height: 1.7)),
          _DemoButton(forceLabel, onTap: satoOwned || armed ? null : store.armSato),
          if (armed) _DemoButton('指定をやめる', onTap: store.clearForce),
          _DemoButton(
            complete ? 'すでに全コンプリート' : '全コンプリートにする',
            onTap: complete
                ? null
                : () {
                    store.grantAll();
                    onGo(Section.benefits);
                  },
          ),
          _DemoButton('日付を1日進める', onTap: store.advanceDay),
          _DemoButton('記録をリセット', onTap: () async {
            final ok = await confirmSheet(
              context,
              title: '記録を消しますか',
              lines: const ['このスマホの中の収集記録を消します。デモのための操作です。'],
              confirm: '記録を消す',
            );
            if (ok) {
              store.reset();
              onGo(Section.home);
            }
          }),
        ],
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton(this.label, {required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Pressable(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0D3BF)),
            ),
            child: Text(label, style: ts(15)),
          ),
        ),
      ),
    );
  }
}
