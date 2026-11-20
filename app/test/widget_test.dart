// 画面が組み上がり、ガチャ演出が最後まで流れることを確かめる。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shingo_meguri/logic.dart';
import 'package:shingo_meguri/main.dart';
import 'package:shingo_meguri/screens/gacha.dart';
import 'package:shingo_meguri/store.dart';
import 'package:shingo_meguri/theme.dart';

Future<AppStore> makeStore() async {
  SharedPreferences.setMockInitialValues({});
  return AppStore(await SharedPreferences.getInstance());
}

void main() {
  testWidgets('home shows the stamp book and tabs switch pages', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ShingoApp(store: await makeStore()));
    await tester.pump();
    expect(find.text('スタンプ帳'), findsOneWidget);
    expect(find.text('QRを読み込む'), findsOneWidget);

    await tester.tap(find.text('特典').last); // タブバーの方
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('条件を達成すると、クーポンが届きます。'), findsOneWidget);

    await tester.tap(find.text('バッジ').last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('スポットでQRを読み取るとバッジが手に入ります。'), findsOneWidget);
  });

  testWidgets('a scan is saved and the gacha plays to the end', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final store = await makeStore();
    store.armSato();
    final result = store.scanSpot('christ');
    expect(result.ok, isTrue);
    expect(store.state.obtainedItems.containsKey('sato'), isTrue);

    await tester.pumpWidget(StoreScope(
      store: store,
      child: MaterialApp(theme: buildTheme(), home: GachaScreen(result: result)),
    ));
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('閉じる'), findsOneWidget);
    expect(find.text('さとのきみ一本クーポン'), findsOneWidget);
    expect(find.text('レア！'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('a second scan of the same place on the same day is refused', () async {
    final store = await makeStore();
    expect(store.scanSpot('green').ok, isTrue);
    final again = store.scanSpot('green');
    expect(again.ok, isFalse);
    expect(again.reason, 'already-scanned');
    store.advanceDay();
    expect(store.scanSpot('green').ok, isTrue);
    expect(isUnlocked(store.state, 'complete'), isFalse);
  });
}
