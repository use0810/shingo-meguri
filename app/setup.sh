#!/bin/sh
# Mac で最初に1回だけ実行する。iOS / Android のプロジェクトを作り、必要な設定を入れる。
#   使い方:  cd app && sh setup.sh jp.co.yourcompany
#   引数は会社のドメインを逆にしたもの（バンドルIDの先頭になる。ストア登録後は変えられない）
set -eu

ORG="${1:-}"
if [ -z "$ORG" ]; then
  echo "会社のドメインを逆にしたものを指定してください（例: sh setup.sh jp.co.yourcompany）"
  exit 1
fi

APP_LABEL="新郷観光アプリ"
CAMERA_TEXT="スポットに設置されたQRコードを読み取るためにカメラを使用します。"

cd "$(dirname "$0")"

# 既にあるファイル（lib/ や pubspec.yaml）は上書きされず、足りないものだけ作られる
flutter create . --org "$ORG" --project-name shingo_meguri --platforms ios,android

# ---- iOS ----
PLIST=ios/Runner/Info.plist
pb() { /usr/libexec/PlistBuddy -c "$1" "$PLIST" >/dev/null 2>&1; }
set_plist() { # key type value
  pb "Set :$1 $3" || pb "Add :$1 $2 $3"
}
set_plist CFBundleDisplayName string "$APP_LABEL"
set_plist NSCameraUsageDescription string "$CAMERA_TEXT"
# iPad でもマップの横向き固定が効くようにする
set_plist UIRequiresFullScreen bool true
# 横向きを許可しておく（アプリ側で、マップ以外は縦に固定している）
pb "Delete :UISupportedInterfaceOrientations" || true
pb "Add :UISupportedInterfaceOrientations array"
pb "Add :UISupportedInterfaceOrientations:0 string UIInterfaceOrientationPortrait"
pb "Add :UISupportedInterfaceOrientations:1 string UIInterfaceOrientationLandscapeLeft"
pb "Add :UISupportedInterfaceOrientations:2 string UIInterfaceOrientationLandscapeRight"
# 暗号化は HTTPS 以外使っていないので、輸出規制の質問を省略する
set_plist ITSAppUsesNonExemptEncryption bool false

# mobile_scanner が求める iOS の最低バージョン
if [ -f ios/Podfile ]; then
  sed -i '' "s/^# platform :ios, .*/platform :ios, '15.5'/" ios/Podfile
fi

# ---- Android ----
MANIFEST=android/app/src/main/AndroidManifest.xml
sed -i '' "s/android:label=\"[^\"]*\"/android:label=\"$APP_LABEL\"/" "$MANIFEST"
if ! grep -q "android.permission.CAMERA" "$MANIFEST"; then
  sed -i '' "s#<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">#<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">\\
    <uses-permission android:name=\"android.permission.CAMERA\" />#" "$MANIFEST"
fi

flutter pub get

echo ""
echo "準備ができました。次の手順:"
echo "  flutter test          # テスト"
echo "  open -a Simulator && flutter run   # シミュレーターで起動（カメラは使えないので、デモ用の地点選択で確認）"
echo "  flutter run           # USB でつないだ iPhone / Android で起動"
