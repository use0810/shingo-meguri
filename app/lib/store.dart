import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart' as logic;
import 'logic.dart' show ScanResult, ShingoState;

/// デモ用の操作（日付を進める・全コンプリートなど）を出すかどうか。
/// 開発中は表示し、リリースビルドでは隠す。審査用に出したいときは
/// `--dart-define=SHINGO_DEMO=true` を付けてビルドする。
const bool kDemo = bool.fromEnvironment('SHINGO_DEMO', defaultValue: !kReleaseMode);

/// 収集記録を持ち、変わるたびに端末へ保存する。記録は端末の中だけにあり、通信はしない。
class AppStore extends ChangeNotifier {
  AppStore(SharedPreferences prefs)
      : _prefs = prefs,
        _state = _load(prefs);

  static const _key = 'shingo-meguri-v1';

  final SharedPreferences _prefs;
  ShingoState _state;

  ShingoState get state => _state;

  String today() => logic.currentDateKey(_state);

  static ShingoState _load(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_key);
      if (raw == null) return const ShingoState();
      return ShingoState.fromJson(jsonDecode(raw));
    } catch (_) {
      return const ShingoState();
    }
  }

  void _commit(ShingoState next) {
    _state = next;
    _prefs.setString(_key, jsonEncode(next.toJson()));
    notifyListeners();
  }

  ScanResult scanSpot(String spotId) {
    final result = logic.scan(_state, spotId, today());
    if (result.ok) _commit(result.state);
    return result;
  }

  bool consumeBenefit(String id) {
    final result = logic.consume(_state, id, today());
    if (result.ok) _commit(result.state);
    return result.ok;
  }

  void advanceDay() => _commit(logic.advanceDay(_state));
  void armSato() => _commit(logic.armSato(_state));
  void clearForce() => _commit(_state.copyWith(clearForce: true));
  void grantAll() => _commit(logic.grantAll(_state, today()));
  void reset() => _commit(const ShingoState());
}

/// 画面のどこからでも記録を読めるようにする。記録が変わると、読んでいる画面が描き直される。
class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  /// 描き直しが要らない場面（ボタンを押したときなど）で使う
  static AppStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
