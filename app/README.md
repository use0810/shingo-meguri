# 新郷観光アプリ（Flutter版）

iOS / Android 向けのアプリ版です。リポジトリ直下の Web版（`index.html`）は、人に見せるデモとしてそのまま残しています。

## 最初の準備（Mac）

1. Flutter をインストールし、`flutter doctor` で Xcode と Android Studio が ✓ になることを確認する
2. このフォルダでセットアップを実行する（引数は会社のドメインを逆にしたもの）

   ```sh
   cd app
   sh setup.sh jp.co.yourcompany
   ```

   `ios/` と `android/` のフォルダが作られ、アプリ名・カメラの利用目的・画面の向きが設定されます。
   バンドルID は iOS が `jp.co.yourcompany.shingoMeguri`、Android が `jp.co.yourcompany.shingo_meguri` になります。**ストアに登録すると変えられない**ので、決めてから実行してください。

3. 動かす

   ```sh
   flutter test     # ロジックと画面のテスト
   flutter run      # シミュレーターまたは USB でつないだ実機で起動
   ```

## 中身

| ファイル | 内容 |
|---|---|
| `lib/logic.dart` | 集める・届く・使うのルール（Web版 `js/logic.js` と同じ） |
| `lib/store.dart` | 記録の保存（端末の中だけ。通信しない） |
| `lib/screens/` | 画面（ホーム、読み取り、ガチャ演出、マップ、一覧、特典） |
| `lib/data.dart` | スポットの位置、マップのタップ範囲、アイテムの色 |
| `assets/` | 地図画像とフォント（Zen Maru Gothic、OFL ライセンス） |

すべて端末の中で完結するので、電波がなくても動きます。通信するのは、マップの「Googleマップでルートを見る」を押したときだけです。

## 看板に印刷する QR コード

QR の中身は次の形にします。

| スポット | QR の中身 |
|---|---|
| キリストの墓 | `shingo-meguri:spot:christ` |
| グリーンパーク | `shingo-meguri:spot:green` |
| 新郷村役場 | `shingo-meguri:spot:office` |
| 新郷温泉館 | `shingo-meguri:spot:onsen` |
| 戸来三嶽神社 | `shingo-meguri:spot:herai` |
| 西越三嶽神社 | `shingo-meguri:spot:nishikoshi` |

`https://…/spot/christ` のような URL 形式でも読み取れます（将来、QR から Web ページに案内したくなった場合用）。

## デモ用の操作

開発中のビルド（`flutter run`）では、マイページに「デモ用」の欄、読み取り画面に「テスト用：読み取った地点を選ぶ」が出ます。
シミュレーターはカメラが使えないので、こちらで確認してください。

リリースビルドでは自動で隠れます。審査用に出したいときは、次のようにビルドします。

```sh
flutter build ipa --dart-define=SHINGO_DEMO=true
```

App Store の審査メモには、上の表の QR コードの画像を添付して「画面に表示した QR を読み取ると動作を確認できます」と書くのがおすすめです。

## Web版との違い

- QR はカメラで実際に読み取る（Web版はボタンで代用）
- マップは端末の向きを横に固定して表示し、ピンチで拡大できる
- スタンプが押されたときと、アイテムが届いたときに端末が振動する
- 「視差効果を減らす」設定の端末では、演出を省いて結果だけ表示する

## まだ入っていないもの

- アプリアイコンと起動画面（`flutter_launcher_icons` / `flutter_native_splash` で作る予定）
- お知らせ機能とプッシュ通知（サーバーが必要）
- プライバシーポリシーへのリンク
