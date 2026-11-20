import 'package:flutter/painting.dart';

const String kMapAsset = 'assets/images/shingo-map.jpg';
const double kMapW = 1024;
const double kMapH = 616;

/// 地図画像の中で、各スポットのイラストが描かれている位置（px）
const Map<String, (double, double)> kArt = {
  'office': (728.0, 152.0),
  'herai': (636.0, 146.0),
  'christ': (470.0, 174.0),
  'green': (298.0, 380.0),
  'onsen': (432.0, 466.0),
  'nishikoshi': (748.0, 352.0),
};

class ItemLook {
  const ItemLook(this.glyph, this.color);
  final String glyph;
  final Color color;
}

const Map<String, ItemLook> kItemLook = {
  'sato': ItemLook('郷', Color(0xFFF2B632)),
  'yogurt': ItemLook('乳', Color(0xFF6FB1D6)),
  'duck': ItemLook('鴨', Color(0xFF8F9CA6)),
  'senbei': ItemLook('煎', Color(0xFFC98A4B)),
  'christ-item': ItemLook('キ', Color(0xFFB07CC6)),
  'isukiri': ItemLook('イ', Color(0xFFE0789A)),
  'dracula': ItemLook('ド', Color(0xFF8A4B5C)),
  'sakasa': ItemLook('栃', Color(0xFF5C9A4A)),
  'pyramid': ItemLook('石', Color(0xFF7C7F86)),
  'mizubasho': ItemLook('芭', Color(0xFF4FB39A)),
};

/// マップ上のタップできる場所（位置と大きさは地図に対する %）
class MapPlace {
  const MapPlace({
    required this.id,
    required this.label,
    required this.query,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  final String id;
  final String label;
  final String query;
  final double left;
  final double top;
  final double width;
  final double height;
}

const List<MapPlace> kMapPlaces = [
  MapPlace(id: 'office', label: '新郷村役場', query: '新郷村役場 青森県三戸郡新郷村大字戸来字風呂前10', left: 68, top: 16, width: 14, height: 14),
  MapPlace(id: 'herai', label: '戸来三嶽神社', query: '戸来三嶽神社 青森県三戸郡新郷村大字戸来字三嶽下15', left: 56.5, top: 18, width: 11, height: 13),
  MapPlace(id: 'christ', label: 'キリストの墓', query: 'キリストの墓 青森県三戸郡新郷村大字戸来字野月33-1', left: 39, top: 21, width: 11, height: 16),
  MapPlace(id: 'densho', label: '伝承館', query: 'キリストの里伝承館 青森県三戸郡新郷村大字戸来字野月33-1', left: 50, top: 29, width: 7, height: 10),
  MapPlace(id: 'pyramid', label: '大石神ピラミッド', query: '大石神ピラミッド 青森県三戸郡新郷村大字戸来字雨池11-41', left: 18, top: 39, width: 15, height: 11),
  MapPlace(id: 'nishikoshi', label: '西越三嶽神社', query: '西越三嶽神社 青森県三戸郡新郷村大字西越字林ノ前62-2', left: 66, top: 52, width: 14, height: 13),
  MapPlace(id: 'green', label: '道の駅しんごう・間木ノ平グリーンパーク', query: '道の駅しんごう 青森県三戸郡新郷村大字戸来字雨池11-2', left: 20, top: 57, width: 18, height: 15),
  MapPlace(id: 'mizu', label: '水芭蕉群生地', query: '水芭蕉群生地 菅場 新郷村', left: 7, top: 71, width: 13, height: 12),
  MapPlace(id: 'onsen', label: '新郷温泉館（伝説の湯の里）', query: '新郷温泉館 青森県三戸郡新郷村大字西越字温泉沢5-4', left: 36, top: 69, width: 15, height: 15),
];

String mapsUrl(String query) =>
    'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(query)}&travelmode=driving';
