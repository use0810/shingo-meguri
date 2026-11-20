import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

/// Web版と同じ線のアイコン（24×24 の SVG の中身）
abstract final class Ic {
  static const profile = '<circle cx="12" cy="9" r="3.4"/><path d="M5.8 19.4c1.3-2.7 3.4-4 6.2-4s4.9 1.3 6.2 4"/>';
  static const badge = '<circle cx="12" cy="9.5" r="5"/><path d="M8.6 13.6 7.4 20.5l4.6-2 4.6 2-1.2-6.9"/><path d="m10 9.6 1.4 1.4 2.8-2.8"/>';
  static const item = '<path d="M4.5 8.5h15v11a1 1 0 0 1-1 1h-13a1 1 0 0 1-1-1z"/><path d="M3.5 5h17v3.5h-17zM12 5v15.5"/><path d="M12 5c-1.5-2.6-5-2.6-4.4-.4.3 1 2.4.4 4.4.4zm0 0c1.5-2.6 5-2.6 4.4-.4-.3 1-2.4.4-4.4.4z"/>';
  static const benefit = '<path d="M3.5 7.5a1 1 0 0 1 1-1h15a1 1 0 0 1 1 1v2.3a2.2 2.2 0 0 0 0 4.4v2.3a1 1 0 0 1-1 1h-15a1 1 0 0 1-1-1v-2.3a2.2 2.2 0 0 0 0-4.4z"/><path d="M14.5 7v10" stroke-dasharray="1.6 2.2"/>';
  static const map = '<path d="M9 4.5 3.5 6.6v13l5.5-2.1 6 2.1 5.5-2.1v-13L15 6.6z"/><path d="M9 4.5v13M15 6.6v13"/>';
  static const qr = '<rect x="3.5" y="3.5" width="6.5" height="6.5" rx="1.2"/><rect x="14" y="3.5" width="6.5" height="6.5" rx="1.2"/><rect x="3.5" y="14" width="6.5" height="6.5" rx="1.2"/><path d="M14 14h2.5v2.5H14zM18 18h2.5v2.5H18zM18 14h2.5M14 18v2.5"/>';
  static const close = '<path d="M6 6l12 12M18 6 6 18"/>';
  static const route = '<circle cx="6" cy="18" r="2"/><circle cx="18" cy="6" r="2"/><path d="M8 18h7.5a3 3 0 0 0 0-6h-7a3 3 0 0 1 0-6H16"/>';
  static const lock = '<rect x="5" y="10.5" width="14" height="10" rx="2"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/>';
  static const chevron = '<path d="m9 6 6 6-6 6"/>';
}

class AppIcon extends StatelessWidget {
  const AppIcon(this.body, {super.key, this.size = 24, this.color = C.ink});

  final String body;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" '
      'stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">$body</svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

const String kBrandMarkSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40"><circle cx="28" cy="12" r="5" fill="#f6b73c"/>'
    '<path d="M2 32 14 15l7 9 5-6 12 14z" fill="#5aa83c"/><path d="M14 15l4 5.2-3 1.6-3-2.2z" fill="#fff" opacity=".85"/>'
    '<path d="M2 32h36v3H2z" fill="#a0673a"/></svg>';

/// UFO の本体（ライトは点滅させるので別に描く）。viewBox は 120×64。
const String kUfoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 64">
  <defs>
    <linearGradient id="d" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e8fbff"/><stop offset="1" stop-color="#8fd3ea"/></linearGradient>
    <linearGradient id="b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f4f6f8"/><stop offset=".55" stop-color="#b9c2cb"/><stop offset="1" stop-color="#7d8893"/></linearGradient>
  </defs>
  <path d="M38 30c0-12 10-21 22-21s22 9 22 21z" fill="url(#d)" stroke="#5b8fa3" stroke-width="2"/>
  <path d="M46 22q4-5 9-3" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" opacity=".85"/>
  <ellipse cx="60" cy="36" rx="56" ry="14" fill="url(#b)" stroke="#66717c" stroke-width="2"/>
  <ellipse cx="60" cy="31" rx="40" ry="5" fill="#fff" opacity=".45"/>
  <path d="M46 49h28l-4 7H50z" fill="#66717c"/>
</svg>''';

const List<(double, double)> kUfoLights = [
  (22.0, 38.0),
  (41.0, 42.0),
  (60.0, 43.5),
  (79.0, 42.0),
  (98.0, 38.0),
];
