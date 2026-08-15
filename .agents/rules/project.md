# Project Rules

- 이 프로젝트는 `../console` Rails 웹앱을 표시하는 Hotwire Native iOS 앱이다.
- 테마 색상과 아이콘의 원본은 `../console/app/views/pwa/manifest.json.erb`와 `../console/public/icon.png`이다.
- 웹 자산을 변경한 뒤 `scripts/sync_web_assets`를 실행하고 생성된 결과물을 저장소에 포함한다.
- Debug는 `http://192.168.0.15:3000`, Release는 `https://console.joungsik.com`을 사용한다.
- Mac의 로컬 IP가 변경되면 `Console/Configuration/Debug.xcconfig`를 갱신한다.
- URL은 Build Configuration에서 주입하고 앱 코드에 환경별 URL 문자열을 직접 작성하지 않는다.
- 개발자별 signing 값은 Git에서 제외한 `Console/Configuration/Signing.xcconfig`에 작성하고, 저장소에는 실제 Team ID를 추가하지 않는다.
- Xcode의 `Signing & Capabilities`에서 Team을 직접 선택해 `project.pbxproj`에 `DEVELOPMENT_TEAM`을 기록하지 않는다.
- 코드 작업을 완료할 때마다 아래 명령으로 generic iOS device 대상 빌드를 실행해 컴파일을 검증한다. 빌드하지 못했거나 실패하면 완료 보고에 원인을 명시한다.

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Console.xcodeproj \
  -scheme Console \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```
