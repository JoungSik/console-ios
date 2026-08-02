# Design Rules

- 웹과 네이티브 화면의 색상 기준은 `../console`의 Tailwind 팔레트이며, 네이티브 UI가 웹 디자인을 따른다.
- 네이티브 색상은 `Assets.xcassets`의 semantic color asset과 `AppTheme`을 통해 사용한다. View Controller에 라이트·다크 색상값을 직접 작성하지 않는다.
- 시스템 appearance 변경에 자동으로 대응하는 dynamic color를 사용한다. Rails 사용자 테마가 `light` 또는 `dark`이면 `overrideUserInterfaceStyle`로 명시적 설정을 적용하고, `system`이면 `.unspecified`로 시스템 appearance를 따른다.
- 앱 시작 시 사용하는 마지막 테마 값은 Rails에서 마지막으로 확인한 값의 mirror/cache일 뿐이며, 별도 원본으로 취급하지 않고 다음 서버 동기화에서 항상 덮어쓴다.
- navigation bar와 tab bar는 콘텐츠와 겹쳐 색이 달라지지 않도록 opaque appearance를 사용한다.
- navigation bar는 웹뷰의 앱 배경과 같은 색상을 사용하고 하단 경계선을 표시하지 않아 콘텐츠가 자연스럽게 이어지도록 한다.
- 웹뷰와 네이티브 설정 목록은 navigation bar 아래의 상단 간격이 비슷하게 보이도록 조정한다.
- 네이티브 설정은 iOS 관례에 맞게 `insetGrouped` 목록을 사용하고, 관련 항목을 한 section에 묶어 한 줄 제목·SF Symbol·disclosure indicator로 표현한다.
- 웹 설정의 용어와 정보 구조는 따르되 웹 card UI를 네이티브 화면에 그대로 복제하지 않는다.
- 계정 데이터, 비밀번호 폼, 서버에 저장되는 테마처럼 Rails가 소유한 설정은 네이티브에 중복 구현하지 않고 해당 웹 설정 화면으로 연결한다.
- 앱 설명은 설정 화면에 노출하지 않고, 버전은 목록 하단의 간결한 정보로 표시한다.
- 서버 주소와 빌드 환경은 `DEBUG` 빌드의 별도 개발 정보 section에서만 표시하고 배포 빌드에는 포함하지 않는다.

## Color Palette

| 역할 | Light | Dark | Tailwind 기준 |
| --- | --- | --- | --- |
| 앱 배경, navigation | `#f3f4f6` | `#111827` | `gray-100` / `gray-900` |
| tab, card surface | `#ffffff` | `#1f2937` | `white` / `gray-800` |
| border, separator | `#e5e7eb` | `#374151` | `gray-200` / `gray-700` |
| primary text | `#111827` | `#ffffff` | `gray-900` / `white` |
| secondary text | `#4b5563` | `#9ca3af` | `gray-600` / `gray-400` |
| accent, selected state | `#2563eb` | `#60a5fa` | `blue-600` / `blue-400` |

## Verification

- 네이티브 화면을 추가하거나 색상을 변경하면 Light와 Dark appearance를 모두 확인한다.
- 웹 콘텐츠와 맞닿는 navigation bar와 tab bar, 네이티브 설정 화면, launch screen에서 배경·surface·border·텍스트·accent의 의미가 동일한지 확인한다.
- 색상 변경 후 generic iOS device 빌드 검증을 실행한다.
