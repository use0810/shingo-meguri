import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../logic.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';

/// 読み取り後の演出：スタンプが「ポン」→ UFO がアイテムを届ける。
/// 時間割は Web版 css/app.css のアニメーションと同じ（秒）。
class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key, required this.result});
  final ScanResult result;

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> with TickerProviderStateMixin {
  static const double _total = 6;

  late final AnimationController _main =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 6000));

  /// 雲・UFO の揺れ・ライトの点滅など、繰り返す動き用（1260秒はどの周期でも割り切れる）
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 1260));

  bool _started = false;
  bool _reduced = false;
  bool _stampFelt = false;
  bool _dropFelt = false;

  bool get _rare => widget.result.item?.id == 'sato';
  double get _sec => _main.value * _total;
  double get _loopSec => _loop.value * 1260;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // 「視差効果を減らす」設定のときは、動かさずに結果だけ見せる
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _main.value = 1;
      return;
    }
    _main.addListener(_haptics);
    _main.forward();
    _loop.repeat();
  }

  void _haptics() {
    if (!_stampFelt && _sec >= 0.56) {
      _stampFelt = true;
      HapticFeedback.mediumImpact();
    }
    if (!_dropFelt && widget.result.item != null && _sec >= 1.95) {
      _dropFelt = true;
      _rare ? HapticFeedback.heavyImpact() : HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _main.dispose();
    _loop.dispose();
    super.dispose();
  }

  /// start 秒から dur 秒かけて 0→1
  double _p(double start, double dur, [Curve curve = Curves.linear]) =>
      curve.transform(((_sec - start) / dur).clamp(0.0, 1.0));

  bool _between(double start, double end) => _sec >= start && _sec < end;

  /// CSS の @keyframes と同じく、区間ごとに補間する
  static double _kf(double p, List<double> stops, List<double> values, [Curve curve = Curves.linear]) {
    if (p <= stops.first) return values.first;
    for (var i = 0; i < stops.length - 1; i++) {
      if (p <= stops[i + 1]) {
        final local = (p - stops[i]) / (stops[i + 1] - stops[i]);
        return lerpDouble(values[i], values[i + 1], curve.transform(local))!;
      }
    }
    return values.last;
  }

  /// 少し下から浮かび上がる
  Widget _rise(double start, double dur, Widget child) {
    final t = _p(start, dur, Curves.ease);
    return Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child),
    );
  }

  String get _srText {
    final r = widget.result;
    final badge = r.badgeNew ? 'はじめて' : '所持済み';
    final item = r.item != null ? 'アイテム「${r.item!.name}」が届きました。' : 'アイテムはすでにすべて揃っています。';
    final awards = r.unlocked.map((b) => '特典「${b.title}」が届きました。').join();
    return 'バッジ「${r.spot!.name}」（$badge）。$item$awards';
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.48, 0.78, 1],
              colors: [Color(0xFFA9DCF2), Color(0xFFD7F0FA), Color(0xFFE9F6DC), Color(0xFFD6ECBD)],
            ),
          ),
          child: AnimatedBuilder(
            animation: Listenable.merge([_main, _loop]),
            builder: (context, _) => Stack(
              children: [
                Positioned.fill(child: IgnorePointer(child: _clouds(size.width))),
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, pad.top + 22, 16, 110 + pad.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(liveRegion: true, label: _srText, child: const SizedBox.shrink()),
                        const Center(
                          child: Pill('届きました！',
                              bg: C.sun,
                              fg: C.brown,
                              size: 13,
                              weight: FontWeight.w900,
                              ls: 0.1,
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 2)),
                        ),
                        const SizedBox(height: 8),
                        Text(widget.result.spot!.name,
                            textAlign: TextAlign.center, style: ts(26, weight: FontWeight.w900, height: 1.4)),
                        const SizedBox(height: 16),
                        ExcludeSemantics(child: _rise(0, 0.3, _stampbook())),
                        const SizedBox(height: 14),
                        ExcludeSemantics(child: _sky(size.width)),
                        _rise(3.0, 0.4, _awards()),
                      ],
                    ),
                  ),
                ),
                if (!_reduced) Positioned.fill(child: IgnorePointer(child: _confetti(size.height))),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, pad.bottom + 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, 0.2, 1],
                        colors: [Color(0x00D6ECBD), Color(0xFFD6ECBD), Color(0xFFD6ECBD)],
                      ),
                    ),
                    child: PrimaryButton('閉じる', onTap: () => Navigator.of(context).pop()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- 雲 ----------

  Widget _clouds(double width) {
    double drift(double period, {bool reverse = false}) {
      var phase = (_loopSec % period) / period;
      if (reverse) phase = 1 - phase;
      final t = phase < 0.5 ? phase * 2 : 2 - phase * 2;
      return 24 * Curves.easeInOut.transform(t);
    }

    return Stack(
      children: [
        Positioned(top: 70, left: -20 + drift(14), child: const _Cloud(width: 90)),
        Positioned(top: 380, right: -10 - drift(18, reverse: true), child: const _Cloud(width: 110)),
        Positioned(top: 30, right: 30 - drift(20), child: const _Cloud(width: 60, opacity: 0.6)),
      ],
    );
  }

  // ---------- スタンプ帳 ----------

  Widget _stampbook() {
    final r = widget.result;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF0),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x295C4628), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: CustomPaint(
        painter: const _PaperPainter(),
        child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 16, 16, 16),
        child: Row(
          children: [
            _stampSlot(r.spot!.id),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Pill('バッジ', bg: C.leafSoft, fg: C.leafDark, ls: 0),
                  const SizedBox(height: 4),
                  Text(r.spot!.name, style: ts(18, weight: FontWeight.w900, height: 1.35)),
                  const SizedBox(height: 4),
                  Text(
                    r.badgeNew ? 'はじめて' : '所持済み',
                    style: ts(12, weight: FontWeight.w700, color: r.badgeNew ? C.torii : C.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _stampSlot(String spotId) {
    const slot = 104.0;
    // 押された跡
    final imprint = _p(0.62, 0.35, Curves.easeOut);
    // 光の筋
    final burst = _p(0.62, 0.5, Curves.easeOut);
    // 「ポン！」
    final pon = _p(0.62, 0.5);
    // 木のスタンプ（0.2秒から0.95秒）
    final drop = _p(0.2, 0.95);
    const stamperCurve = Cubic(0.3, 0.1, 0.3, 1);
    final stamperY = _kf(drop, [0, .38, .46, .60, .72, 1], [-170, 0, 2, 0, -20, -190], stamperCurve);
    final stamperSx = _kf(drop, [0, .38, .46, .60, 1], [1, 1, 1.06, 1, 1], stamperCurve);
    final stamperSy = _kf(drop, [0, .38, .46, .60, 1], [1, 1, 0.9, 1, 1], stamperCurve);
    final stamperOp = _kf(drop, [0, .72, 1], [1, 1, 0]);

    return CustomPaint(
      foregroundPainter: DashedBorderPainter(color: C.dash, radius: slot),
      child: SizedBox(
        width: slot,
        height: slot,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: imprint,
              child: Transform.scale(
                scale: lerpDouble(1.25, 1, imprint)!,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SpotArt(spotId, size: 92),
                    Positioned(
                      right: -10,
                      bottom: -6,
                      child: Transform.rotate(
                        angle: -0.244,
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xE6FFFFFF),
                            border: Border.all(color: C.torii, width: 3),
                          ),
                          child: Text('済', style: ts(17, weight: FontWeight.w900, color: C.torii, height: 1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!_reduced && _between(0.62, 1.12))
              for (var i = 0; i < 8; i++)
                Opacity(
                  opacity: 1 - burst,
                  child: Transform.rotate(
                    angle: i * math.pi / 4,
                    child: Transform.translate(
                      offset: Offset(0, -50 - 26 * burst),
                      child: Transform.scale(
                        scaleX: 1,
                        scaleY: 0.4 + 0.6 * burst,
                        child: Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(color: C.sun, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                    ),
                  ),
                ),
            if (!_reduced && _sec < 1.15)
              Positioned(
                left: (slot - 96) / 2,
                bottom: 6,
                width: 96,
                child: Opacity(
                  opacity: stamperOp,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.translationValues(0, stamperY, 0)
                      ..multiply(Matrix4.diagonal3Values(stamperSx, stamperSy, 1)),
                    child: const _Stamper(),
                  ),
                ),
              ),
            Positioned(
              top: -10,
              right: -34,
              child: Opacity(
                opacity: pon < 0.55 ? pon / 0.55 : 1,
                child: Transform.rotate(
                  angle: 0.175,
                  child: Transform.scale(
                    scale: _kf(pon, [0, .55, 1], [0.4, 1.25, 1], Curves.easeOut),
                    child: const Pill('ポン！',
                        bg: C.torii,
                        fg: Colors.white,
                        size: 15,
                        weight: FontWeight.w900,
                        ls: 0,
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 空と UFO ----------

  Widget _sky(double screenWidth) {
    final item = widget.result.item;
    return SizedBox(
      height: 250,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 草の影
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 140,
                height: 18,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(colors: [Color(0x735AA83C), Color(0x005AA83C)], stops: [0, 0.7]),
                  borderRadius: BorderRadius.all(Radius.elliptical(70, 9)),
                ),
              ),
            ),
          ),
          if (item != null && !_reduced) _beam(),
          if (item != null) _drop(item),
          if (item != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _rise(
                2.45,
                0.35,
                Column(
                  children: [
                    Text('アイテム', style: ts(11, weight: FontWeight.w700, color: C.leafDark)),
                    Text(item.name, style: ts(18, weight: FontWeight.w900, height: 1.35)),
                    Text('はじめて', style: ts(12, weight: FontWeight.w700, color: C.torii)),
                  ],
                ),
              ),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              top: 110,
              child: _rise(
                1.8,
                0.35,
                Column(
                  children: [
                    Text('アイテム', style: ts(11, weight: FontWeight.w700, color: C.leafDark)),
                    Text('すべて揃っています', style: ts(18, weight: FontWeight.w900, height: 1.35)),
                  ],
                ),
              ),
            ),
          if (!_reduced && _sec < 3.1) _ufo(screenWidth),
        ],
      ),
    );
  }

  Widget _beam() {
    final t = _p(1.65, 1.1, Curves.ease);
    final opacity = _kf(t, [0, .2, .8, 1], [0, 1, 1, 0]);
    final scaleY = _kf(t, [0, .2, 1], [0, 1, 1]);
    return Positioned(
      top: 58,
      left: 0,
      right: 0,
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.diagonal3Values(1, scaleY, 1),
            child: ClipPath(
              clipper: const _BeamClipper(),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _rare
                        ? const [Color(0xFFFFD23C), Color(0x33FFBE28)]
                        : const [Color(0xF2FFF6AA), Color(0x26FFF6AA)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _drop(Item item) {
    final t = _p(1.85, 0.8, const Cubic(0.3, 1.4, 0.5, 1));
    // レアは光りながら明るさが脈打つ
    var shine = 1.0;
    if (_rare && _sec >= 2.6 && !_reduced) {
      final phase = (_loopSec % 1.2) / 1.2;
      shine = 1 + 0.18 * (0.5 - 0.5 * math.cos(phase * 2 * math.pi));
    }
    Widget hanko = Hanko(item.id, glow: _rare);
    if (shine != 1) hanko = ColorFiltered(colorFilter: cssFilter(brightness: shine), child: hanko);

    return Positioned(
      top: 112,
      left: 0,
      right: 0,
      child: Center(
        child: Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -60 * (1 - t)),
            child: Transform.scale(
              scale: 0.4 + 0.6 * t,
              child: SizedBox(
                width: 80,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    hanko,
                    if (_rare)
                      Positioned(
                        top: -12,
                        right: -26,
                        child: Transform.rotate(
                          angle: 0.21,
                          child: const Pill('レア！',
                              bg: C.torii,
                              fg: Colors.white,
                              size: 12,
                              weight: FontWeight.w900,
                              ls: 0,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ufo(double screenWidth) {
    const curve = Cubic(0.4, 0, 0.3, 1);
    final t = _p(1.1, 2.0);
    const stops = [0.0, .25, .32, .80, 1.0];
    final x = _kf(t, stops, [-1.2 * screenWidth, 0, 0, 0, 1.2 * screenWidth], curve);
    final y = _kf(t, stops, [0, 0, 0, 0, -60], curve);
    final deg = _kf(t, stops, [-12, 4, 0, 0, 10], curve);
    final bobPhase = (_loopSec % 0.9) / 0.9;
    final bob = -5 * Curves.easeInOut.transform(bobPhase < 0.5 ? bobPhase * 2 : 2 - bobPhase * 2);
    final blinkOn = (_loopSec % 0.5) < 0.25;

    const w = 132.0;
    const scale = w / 120;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Center(
        child: Transform.translate(
          offset: Offset(x, y + bob),
          child: Transform.rotate(
            angle: deg * math.pi / 180,
            child: SizedBox(
              width: w,
              height: 64 * scale,
              child: Stack(
                children: [
                  SvgPicture.string(kUfoSvg, width: w),
                  for (var i = 0; i < kUfoLights.length; i++)
                    Positioned(
                      left: (kUfoLights[i].$1 - 3.6) * scale,
                      top: (kUfoLights[i].$2 - 3.6) * scale,
                      child: Container(
                        width: 7.2 * scale,
                        height: 7.2 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (blinkOn ^ i.isOdd) ? const Color(0xFFFFE066) : const Color(0xFFFFF6C8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- 特典 ----------

  Widget _awards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final benefit in widget.result.unlocked)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFCF5C), Color(0xFFF6A23C)],
              ),
              boxShadow: const [BoxShadow(color: Color(0x4DF6A23C), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎉 特典が届きました',
                    style: ts(12, weight: FontWeight.w700, color: const Color(0xFF6B4212), ls: 0.1)),
                const SizedBox(height: 2),
                Text(benefit.title, style: ts(20, weight: FontWeight.w900, color: const Color(0xFF4A2D0C))),
                const SizedBox(height: 6),
                Text(benefit.term, style: ts(13, color: const Color(0xFF4A2D0C), height: 1.7)),
              ],
            ),
          ),
      ],
    );
  }

  // ---------- 紙吹雪 ----------

  static const _confettiLeft = [6, 14, 22, 30, 38, 46, 54, 62, 70, 78, 86, 94, 50, 18];
  static const _confettiDelay = [2.5, 2.8, 2.6, 3.0, 2.55, 2.9, 2.65, 3.1, 2.7, 2.85, 2.6, 2.95, 3.2, 3.3];
  static const _confettiColor = [C.sun, C.torii, Color(0xFF8FD16A), Color(0xFF7CC6EA)];

  Widget _confetti(double height) {
    return LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          for (var i = 0; i < _confettiLeft.length; i++)
            if (_between(_confettiDelay[i], _confettiDelay[i] + 2.6))
              Positioned(
                left: box.maxWidth * _confettiLeft[i] / 100,
                top: -20 + _p(_confettiDelay[i], 2.6, Curves.easeIn) * height * 1.05,
                child: Transform.rotate(
                  angle: _p(_confettiDelay[i], 2.6, Curves.easeIn) * 3 * math.pi,
                  child: Container(
                    width: 9,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _confettiColor[i % 4],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  const _Cloud({required this.width, this.opacity = 0.85});
  final double width;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: width,
        height: 26,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            Positioned(
              left: width * 0.22,
              top: -14,
              width: width * 0.44,
              height: 32,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 木のスタンプ
class _Stamper extends StatelessWidget {
  const _Stamper();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 34,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.circular(17)),
            gradient: RadialGradient(
              center: Alignment(-0.3, -0.4),
              colors: [Color(0xFFE0A873), C.wood],
              stops: [0, 0.7],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -4),
          child: Container(
            width: 22,
            height: 30,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF8A5530), Color(0xFFC1844F), Color(0xFF8A5530)]),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -4),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(4)),
            child: SizedBox(
              width: 96,
              height: 22,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFC1844F), Color(0xFF8A5530)],
                        ),
                      ),
                    ),
                  ),
                  Container(height: 5, color: C.torii),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 光の筋（上がすぼまった台形）
class _BeamClipper extends CustomClipper<Path> {
  const _BeamClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * 0.38, 0)
    ..lineTo(size.width * 0.62, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_BeamClipper oldClipper) => false;
}

/// スタンプ帳の紙（点の地紋とリング綴じ）
class _PaperPainter extends CustomPainter {
  const _PaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFFFFAF0));
    canvas.save();
    canvas.clipRRect(rrect);
    final dot = Paint()..color = const Color(0xFFE9DCC6);
    for (var y = 7.0; y < size.height; y += 14) {
      for (var x = 7.0; x < size.width; x += 14) {
        canvas.drawCircle(Offset(x, y), 1, dot);
      }
    }
    canvas.restore();
    final ring = Paint()..color = const Color(0xFFB9A88F);
    for (var y = 14.0 + 9; y < size.height - 14; y += 18) {
      canvas.drawCircle(Offset(15, y), 3, ring);
    }
  }

  @override
  bool shouldRepaint(_PaperPainter oldDelegate) => false;
}
