import 'package:flutter/material.dart';

/// Web版 css/app.css の :root と同じ色
abstract final class C {
  static const bg = Color(0xFFFBF6EC);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF3B2F25);
  static const muted = Color(0xFF8A7B6A);
  static const line = Color(0xFFEFE4D2);
  static const leaf = Color(0xFF5AA83C);
  static const leafDark = Color(0xFF2F7A2A);
  static const leafSoft = Color(0xFFE7F4DC);
  static const sky = Color(0xFFDFF0F7);
  static const wood = Color(0xFFA0673A);
  static const torii = Color(0xFFE2563B);
  static const sun = Color(0xFFF6B73C);
  static const paper = Color(0xFFF4EDE1);
  static const dash = Color(0xFFD8C9B2);
  static const lockedText = Color(0xFFC4B6A2);
  static const brown = Color(0xFF5A3A10);
}

const String kAppName = '新郷観光アプリ（仮）';
const String kFont = 'ZenMaruGothic';

/// 文字の見た目。[ls] は文字間隔（em）。
TextStyle ts(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = C.ink,
  double ls = 0,
  double? height,
}) {
  return TextStyle(
    fontFamily: kFont,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: size * ls,
    height: height,
  );
}

const List<BoxShadow> kShadow = [
  BoxShadow(color: Color(0x1A5C4628), blurRadius: 16, offset: Offset(0, 6)),
];

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: kFont,
    scaffoldBackgroundColor: C.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: C.leaf, surface: C.bg),
    splashFactory: NoSplash.splashFactory,
    textTheme: const TextTheme().apply(bodyColor: C.ink, displayColor: C.ink, fontFamily: kFont),
  );
}

/// CSS の grayscale / brightness / contrast と同じ計算をする色行列
ColorFilter cssFilter({double gray = 0, double brightness = 1, double contrast = 1}) {
  final s = 1 - gray;
  final rows = [
    [0.2126 + 0.7874 * s, 0.7152 - 0.7152 * s, 0.0722 - 0.0722 * s],
    [0.2126 - 0.2126 * s, 0.7152 + 0.2848 * s, 0.0722 - 0.0722 * s],
    [0.2126 - 0.2126 * s, 0.7152 - 0.7152 * s, 0.0722 + 0.9278 * s],
  ];
  final k = brightness * contrast;
  final offset = 0.5 * (1 - contrast) * 255;
  return ColorFilter.matrix(<double>[
    for (final row in rows) ...[row[0] * k, row[1] * k, row[2] * k, 0.0, offset],
    0.0, 0.0, 0.0, 1.0, 0.0,
  ]);
}
