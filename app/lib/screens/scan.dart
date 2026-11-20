import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../logic.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import 'gacha.dart';

/// カメラで地点の QR を読み取る画面
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _camera = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  late final AnimationController _line =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  String? _message;
  bool _done = false;

  @override
  void dispose() {
    _camera.dispose();
    _line.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final spotId = spotIdFromQr(raw);
      if (spotId == null) {
        setState(() => _message = '新郷めぐりのQRコードではないようです。スポットの看板にあるQRコードを読み取ってください。');
        return;
      }
      _choose(spotId);
      return;
    }
  }

  void _choose(String spotId) {
    if (_done) return;
    final result = StoreScope.read(context).scanSpot(spotId);
    if (!result.ok) {
      HapticFeedback.lightImpact();
      setState(() {
        _message = result.reason == 'already-scanned'
            ? 'この地点は今日すでに読み取っています。'
            : '地点を読み取れませんでした。';
      });
      return;
    }
    _done = true;
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => GachaScreen(result: result),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final state = StoreScope.of(context).state;
    final today = StoreScope.read(context).today();
    const dark = Color(0xFF24402C);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: C.bg,
        body: Column(
          children: [
            Container(
              color: dark,
              padding: EdgeInsets.fromLTRB(10, pad.top + 6, 10, 6),
              constraints: BoxConstraints(minHeight: 60 + pad.top),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Pressable(
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppIcon(Ic.close, size: 18, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('閉じる', style: ts(15, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text('読み取り',
                        textAlign: TextAlign.center,
                        style: ts(16, weight: FontWeight.w900, color: Colors.white, ls: 0.14)),
                  ),
                  const SizedBox(width: 96),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 28 + pad.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        Container(height: 150, color: dark),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Center(child: _viewfinder()),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_message != null) ...[AlertBox(_message!), const SizedBox(height: 12)],
                          Text('QRコードを写してください',
                              textAlign: TextAlign.center, style: ts(22, weight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          const Note('スポットの看板にあるQRコードを、枠の中に写すと読み取ります。', align: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(
                            'カメラが映らないときは、スマホの設定でこのアプリのカメラを許可してください。',
                            textAlign: TextAlign.center,
                            style: ts(12, color: C.muted, height: 1.7),
                          ),
                          if (kDemo) ...[
                            const BlockTitle('テスト用：読み取った地点を選ぶ'),
                            for (final spot in spots) ...[
                              _SpotButton(
                                spot: spot,
                                status: state.scans[spot.id] == today
                                    ? '本日読取済み'
                                    : state.obtainedBadges.containsKey(spot.id)
                                        ? 'バッジ所持済み'
                                        : 'はじめて',
                                enabled: state.scans[spot.id] != today,
                                onTap: () => _choose(spot.id),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewfinder() {
    const size = 260.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _camera, onDetect: _onDetect),
          const CustomPaint(painter: _CornersPainter()),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _line,
              builder: (context, _) {
                final t = _line.value < 0.5 ? _line.value * 2 : 2 - _line.value * 2;
                return Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 30 + Curves.easeInOut.transform(t) * (size - 60)),
                    child: Container(
                      width: size - 56,
                      height: 3,
                      decoration: BoxDecoration(
                        color: C.torii,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: const [BoxShadow(color: C.torii, blurRadius: 10)],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 枠の四隅のかぎ
class _CornersPainter extends CustomPainter {
  const _CornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 14.0;
    const len = 34.0;
    const r = 10.0;
    final paint = Paint()
      ..color = C.sun
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    for (final (sx, sy) in const [(1.0, 1.0), (-1.0, 1.0), (1.0, -1.0), (-1.0, -1.0)]) {
      final x = sx > 0 ? inset : w - inset;
      final y = sy > 0 ? inset : h - inset;
      final path = Path()
        ..moveTo(x, y + sy * len)
        ..lineTo(x, y + sy * r)
        ..quadraticBezierTo(x, y, x + sx * r, y)
        ..lineTo(x + sx * len, y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CornersPainter oldDelegate) => false;
}

class _SpotButton extends StatelessWidget {
  const _SpotButton({required this.spot, required this.status, required this.enabled, required this.onTap});
  final Spot spot;
  final String status;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isNew = status == 'はじめて';
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Pressable(
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: enabled ? kShadow : null,
          ),
          child: Row(
            children: [
              SpotArt(spot.id, size: 50),
              const SizedBox(width: 12),
              Expanded(child: Text(spot.name, style: ts(16, weight: FontWeight.w700, height: 1.4))),
              Pill(
                status,
                bg: isNew ? const Color(0xFFFFE3DC) : const Color(0xFFF1E9DB),
                fg: isNew ? C.torii : C.muted,
                ls: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
