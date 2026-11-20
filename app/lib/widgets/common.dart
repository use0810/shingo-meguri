import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import 'icons.dart';

/// 押すと少し縮むボタン。Web版の :active { transform: scale(...) } に合わせている。
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 点線の枠
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.color,
    required this.radius,
    this.width = 2,
    this.dash = 6,
    this.gap = 4,
  });

  final Color color;
  final double radius;
  final double width;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final r = math.min(radius, rect.shortestSide / 2);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + dash, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color || old.radius != radius || old.width != width;
}

class DashedBox extends StatelessWidget {
  const DashedBox({
    super.key,
    required this.child,
    this.radius = 18,
    this.color = C.dash,
    this.fill,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final Color color;
  final Color? fill;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: DashedBorderPainter(color: color, radius: radius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(radius)),
        child: child,
      ),
    );
  }
}

/// 横の点線
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, required this.color, this.width = 2});
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, width),
      painter: _DashedLinePainter(color, width),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color, this.width);
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, width / 2), Offset(math.min(x + 6, size.width), width / 2), paint);
      x += 10;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

enum ArtLook { normal, dark, faded }

/// 地図画像からスポットのイラストを丸く切り出したもの
class SpotArt extends StatelessWidget {
  const SpotArt(
    this.spotId, {
    super.key,
    this.size = 64,
    this.look = ArtLook.normal,
    this.border = 3,
    this.shadow = true,
  });

  final String spotId;
  final double size;
  final ArtLook look;
  final double border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final pos = kArt[spotId];
    if (pos == null) return SizedBox.square(dimension: size);

    const span = 150.0;
    final faded = look == ArtLook.faded;
    final ring = faded ? 2.0 : border;
    final inner = size - ring * 2;
    final w = inner * kMapW / span;
    final h = w * kMapH / kMapW;

    Widget art = Container(
      width: size,
      height: size,
      // 白い枠は border が内側の余白を兼ねる。点線のときだけ余白を足す。
      padding: faded ? EdgeInsets.all(ring) : null,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFDFF0D4),
        border: faded ? null : Border.all(color: Colors.white, width: ring),
        boxShadow: shadow && look == ArtLook.normal
            ? const [BoxShadow(color: Color(0x403C5A28), blurRadius: 8, offset: Offset(0, 2))]
            : null,
      ),
      child: ClipOval(
        child: Stack(
          children: [
            Positioned(
              left: inner * (0.5 - pos.$1 / span),
              top: inner * (0.5 - pos.$2 / span),
              width: w,
              height: h,
              child: Image.asset(kMapAsset, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
            ),
          ],
        ),
      ),
    );

    switch (look) {
      case ArtLook.normal:
        return art;
      case ArtLook.dark:
        return Opacity(
          opacity: 0.55,
          child: ColorFiltered(colorFilter: cssFilter(gray: 1, brightness: 0.2), child: art),
        );
      case ArtLook.faded:
        art = CustomPaint(
          foregroundPainter: DashedBorderPainter(color: C.dash, radius: size, width: 2),
          child: art,
        );
        return Opacity(
          opacity: 0.4,
          child: ColorFiltered(
            colorFilter: cssFilter(gray: 1, brightness: 1.15, contrast: 0.6),
            child: art,
          ),
        );
    }
  }
}

/// アイテムのはんこ
class Hanko extends StatelessWidget {
  const Hanko(this.itemId, {super.key, this.size = 72, this.locked = false, this.glow = false});

  final String itemId;
  final double size;
  final bool locked;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return CustomPaint(
        foregroundPainter: DashedBorderPainter(color: C.dash, radius: size),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: C.paper),
          child: Text('？', style: ts(size * 34 / 72, weight: FontWeight.w900, color: const Color(0xFFC9BBA6))),
        ),
      );
    }
    final look = kItemLook[itemId] ?? const ItemLook('？', Color(0xFF999999));
    final r = size * 0.172;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: look.color,
        boxShadow: [
          const BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 3)),
          if (glow) const BoxShadow(color: Color(0x8CFFD650), spreadRadius: 6),
          if (glow) const BoxShadow(color: Color(0xB3FFC832), blurRadius: 28, spreadRadius: 10),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: size * 0.35 - r,
            top: size * 0.30 - r,
            width: r * 2,
            height: r * 2,
            child: const DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0x88FFFFFF)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x55FFFFFF), width: size * 4 / 72),
              ),
            ),
          ),
          Text(
            look.glyph,
            style: ts(size * 34 / 72, weight: FontWeight.w900, color: Colors.white, height: 1).copyWith(
              shadows: const [Shadow(color: Color(0x2E000000), blurRadius: 2, offset: Offset(0, 1))],
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar(this.value, {super.key});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: BoxDecoration(color: const Color(0xFFF1E9DB), borderRadius: BorderRadius.circular(99)),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
        builder: (context, v, _) => FractionallySizedBox(
          widthFactor: v,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: const LinearGradient(colors: [Color(0xFF8FD16A), C.leaf]),
            ),
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(22), boxShadow: kShadow),
      child: child,
    );
  }
}

/// 「3 / 6」の表示
class CountText extends StatelessWidget {
  const CountText(this.count, this.total, {super.key, this.size = 26});
  final int count;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: '$count', style: ts(size, weight: FontWeight.w900, color: C.leafDark)),
        TextSpan(text: ' / $total', style: ts(15, weight: FontWeight.w700, color: C.muted)),
      ]),
    );
  }
}

class PageHead extends StatelessWidget {
  const PageHead(this.title, {super.key, this.count, this.total});
  final String title;
  final int? count;
  final int? total;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: ts(28, weight: FontWeight.w900, ls: 0.04, height: 1.3))),
        if (count != null && total != null) CountText(count!, total!),
      ],
    );
  }
}

class BlockTitle extends StatelessWidget {
  const BlockTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 18,
            decoration: BoxDecoration(color: C.leaf, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 8),
          Text(text, style: ts(16, weight: FontWeight.w900, ls: 0.06)),
        ],
      ),
    );
  }
}

/// 説明文（Web版の .lead / .note）
class Note extends StatelessWidget {
  const Note(this.text, {super.key, this.align = TextAlign.start});
  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) =>
      Text(text, textAlign: align, style: ts(14, color: const Color(0xFF6B5D4E), height: 1.8));
}

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    required this.bg,
    required this.fg,
    this.size = 11,
    this.weight = FontWeight.w700,
    this.ls = 0.08,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
  });

  final String text;
  final Color bg;
  final Color fg;
  final double size;
  final FontWeight weight;
  final double ls;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: ts(size, weight: weight, color: fg, ls: ls, height: 1.5)),
    );
  }
}

class AlertBox extends StatelessWidget {
  const AlertBox(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFFFE8E2), borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: ts(13, weight: FontWeight.w700, color: const Color(0xFFA1301F), height: 1.6)),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, {super.key, required this.onTap, this.color = C.leaf});
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: const Border(bottom: BorderSide(color: Color(0x26000000), width: 3)),
        ),
        child: Text(label, style: ts(17, weight: FontWeight.w900, color: Colors.white, ls: 0.1)),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        child: Text(label, style: ts(15, ls: 0.08)),
      ),
    );
  }
}

/// 確認用の小さなダイアログ。「はい」で true を返す。
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  required List<String> lines,
  required String confirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x8C1E2819),
    builder: (context) => Dialog(
      backgroundColor: C.card,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: ts(22, weight: FontWeight.w900)),
              const SizedBox(height: 8),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(line, style: ts(15, height: 1.7)),
                ),
              const SizedBox(height: 4),
              PrimaryButton(confirm, color: C.torii, onTap: () => Navigator.of(context).pop(true)),
              const SizedBox(height: 4),
              GhostButton('やめる', onTap: () => Navigator.of(context).pop(false)),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

/// 丸い白ボタン（閉じる など）
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 46,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: AppIcon(icon, size: size * 0.48),
      ),
    );
  }
}
