# Console iOS

나만의 인생 기록을 위한 프라이빗 대시보드인 Console의 Hotwire Native iOS 앱입니다.

Rails 웹앱은 `../console`, iOS 앱은 이 저장소에서 관리합니다.

## 환경

- Debug: `http://192.168.0.15:3000`
- Release: `https://console.joungsik.com`

실기기에서 Debug 서버에 연결할 때 Rails를 LAN에 바인딩합니다.

```bash
bin/rails server -b 0.0.0.0
```

## Signing

개발자별 signing 설정은 Git에 포함하지 않는 `Signing.xcconfig`에서 관리합니다.

```bash
cp Console/Configuration/Signing.example.xcconfig Console/Configuration/Signing.xcconfig
```

`Signing.xcconfig`의 `DEVELOPMENT_TEAM`을 자신의 Apple Developer Team ID로 변경합니다.
기본 Bundle Identifier를 사용할 수 없는 Team이라면 `PRODUCT_BUNDLE_IDENTIFIER`도 고유한 값으로 변경합니다.
이 설정은 Debug와 Release에 동일하게 적용됩니다.
Xcode의 `Signing & Capabilities`에서 Team을 직접 선택하면 `project.pbxproj`가 변경되므로 Team 변경은 `Signing.xcconfig`에서만 수행합니다.

## 웹 자산 동기화

테마 색상과 아이콘은 웹 프로젝트를 원본으로 사용합니다.

```bash
scripts/sync_web_assets
```

## 내비게이션

전역 이동은 `홈`, `저널`, `할 일`, `설정` 하단 탭으로 제공합니다.
계정 설정은 네이티브 설정 화면에서 Rails 웹 화면으로 이동하며, 앱 자체 설정은 네이티브 화면에서 제공합니다. 폼 제출과 화면별 액션은 웹 본문 UI를 사용합니다.

## 푸시 알림

Firebase Console에서 Bundle Identifier가 `com.joungsik.console`인 Apple 앱을 등록한 뒤 내려받은 `GoogleService-Info.plist`를 `Console/`에 추가하고 Console target의 `Copy Bundle Resources`에 포함합니다. Bundle Identifier를 signing 설정에서 변경했다면 Firebase Apple 앱도 같은 값으로 등록해야 합니다.

Firebase Console의 Cloud Messaging 설정에는 Apple Developer에서 발급한 APNs 인증 키를 업로드합니다. 실제 수신은 Push Notifications capability가 활성화된 App ID와 실기기에서 확인합니다.

웹의 `/mypage/push_notifications` 화면에서 구독하면 앱이 알림 권한을 요청하고 APNs 및 FCM 등록을 완료한 뒤 Firebase Installation ID를 현재 로그인 세션에 저장합니다. 알림의 `data.url`은 현재 Console 서버 내부 경로일 때 Hotwire Native 화면으로 열립니다.

## 빌드

시뮬레이터 런타임 없이 generic iOS device 대상으로 컴파일할 수 있습니다.

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Console.xcodeproj \
  -scheme Console \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```
