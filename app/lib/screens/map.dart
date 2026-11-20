import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data.dart';
import '../logic.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';

/// 横向き・全画面の観光マップ。地図は画像なので電波がなくても見られる。
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  String? _place;
  String? _message;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _bob.dispose();
    super.dispose();
  }

  Future<void> _openRoute(MapPlace place) async {
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(mapsUrl(place.query)), mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      setState(() => _message = 'Googleマップを開けませんでした。電波の届く場所でお試しください。');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = StoreScope.of(context).state;
    final pad = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFCFE9F5),
      body: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          final sw = math.min(w, h * kMapW / kMapH);
          final sh = sw * kMapH / kMapW;
          final place = kMapPlaces.where((p) => p.id == _place).firstOrNull;

          return Stack(
            children: [
              // 余白はぼかした地図で埋める
              Positioned.fill(
                child: Opacity(
                  opacity: 0.8,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Transform.scale(scale: 1.1, child: Image.asset(kMapAsset, fit: BoxFit.cover)),
                  ),
                ),
              ),
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 3,
                  child: Center(
                    child: Container(
                      width: sw,
                      height: sh,
                      decoration: const BoxDecoration(
                        boxShadow: [BoxShadow(color: Color(0x2E000000), blurRadius: 40)],
                      ),
                      child: _stage(state, sw, sh),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: math.max(10, pad.top),
                right: math.max(10, pad.right),
                child: RoundIconButton(
                  icon: Ic.close,
                  label: 'マップを閉じる',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                left: math.max(10, pad.left),
                bottom: math.max(10, pad.bottom),
                child: ExcludeSemantics(child: _legend()),
              ),
              if (place == null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: math.max(10, pad.bottom),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xD13B2F25),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('スポットをタップすると、ルートを確認できます',
                          style: ts(12, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                )
              else
                Positioned(
                  right: math.max(12, pad.right),
                  bottom: math.max(12, pad.bottom),
                  width: math.min(300, w - 24),
                  child: _placeCard(state, place),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _stage(ShingoState state, double sw, double sh) {
    return Stack(
      children: [
        Positioned.fill(child: Image.asset(kMapAsset, fit: BoxFit.fill)),
        // QR のある場所の目印
        for (final spot in spots)
          if (kArt[spot.id] != null)
            Positioned(
              left: kArt[spot.id]!.$1 / kMapW * sw,
              top: (kArt[spot.id]!.$2 - 46) / kMapH * sh,
              child: IgnorePointer(
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -1),
                  child: AnimatedBuilder(
                    animation: _bob,
                    builder: (context, child) {
                      final got = state.obtainedBadges.containsKey(spot.id);
                      final t = _bob.value < 0.5 ? _bob.value * 2 : 2 - _bob.value * 2;
                      final dy = got ? 0.0 : -4 * Curves.easeInOut.transform(t);
                      return Transform.translate(offset: Offset(0, dy), child: _Pin(got: got));
                    },
                  ),
                ),
              ),
            ),
        // タップできる場所
        for (final p in kMapPlaces)
          Positioned(
            left: p.left / 100 * sw,
            top: p.top / 100 * sh,
            width: p.width / 100 * sw,
            height: p.height / 100 * sh,
            child: Semantics(
              button: true,
              label: p.label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() {
                  _place = p.id;
                  _message = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: _place == p.id ? const Color(0x59FFFFFF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _place == p.id ? C.sun : Colors.transparent, width: 3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _legend() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: const Color(0xEBFFFFFF),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: C.torii, borderRadius: BorderRadius.circular(8)),
            child: Text('QR', style: ts(10, weight: FontWeight.w900, color: Colors.white, height: 1.3)),
          ),
          const SizedBox(width: 6),
          Text('バッジがもらえる場所', style: ts(11, weight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _placeCard(ShingoState state, MapPlace place) {
    final isSpot = spots.any((s) => s.id == place.id);
    final got = state.obtainedBadges.containsKey(place.id);
    return TweenAnimationBuilder<double>(
      key: ValueKey(place.id),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.ease,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 10))],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Row(
                      children: [
                        if (isSpot)
                          SpotArt(place.id, size: 56)
                        else
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: C.sky),
                            child: const AppIcon(Ic.map, size: 26, color: Color(0xFF3D7FA0)),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isSpot)
                                Pill(
                                  got ? 'バッジ獲得済み' : 'QRスポット',
                                  bg: got ? C.leafSoft : const Color(0xFFFFE3DC),
                                  fg: got ? C.leafDark : C.torii,
                                  size: 10,
                                  weight: FontWeight.w900,
                                  ls: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                ),
                              const SizedBox(height: 2),
                              Text(place.label, style: ts(16, weight: FontWeight.w900, height: 1.35)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_message != null) ...[const SizedBox(height: 10), AlertBox(_message!)],
                  const SizedBox(height: 12),
                  Pressable(
                    onTap: () => _openRoute(place),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 46),
                      decoration: BoxDecoration(color: C.leaf, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppIcon(Ic.route, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Googleマップでルートを見る',
                              style: ts(14, weight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Pressable(
                onTap: () => setState(() {
                  _place = null;
                  _message = null;
                }),
                semanticLabel: '閉じる',
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: C.paper),
                  child: const AppIcon(Ic.close, size: 16, color: C.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.got});
  final bool got;

  @override
  Widget build(BuildContext context) {
    final color = got ? C.leaf : C.torii;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 26),
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Text(got ? '✓' : 'QR', style: ts(10, weight: FontWeight.w900, color: Colors.white, height: 1)),
        ),
        CustomPaint(size: const Size(10, 5), painter: _TailPainter(color)),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.color != color;
}
