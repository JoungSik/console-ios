# Hotwire Native Rules

- Rails는 인증, HTML 콘텐츠, 사용자 계정 설정, 화면별 액션을 담당한다.
- iOS 앱은 하단 전역 내비게이션, Navigator, 네이티브 화면 전환, 앱 자체 설정을 담당한다.
- 전역 이동은 `AppTabs`의 하단 탭으로 제공하고, 폼 제출과 화면별 액션은 웹 본문 UI를 사용한다.
- 인증 상태와 관계없이 동일한 하단 탭 구성을 유지한다.
- 로그인, 로그아웃, `401 Unauthorized`를 감지하면 모든 탭의 Navigator stack과 snapshot cache를 초기화한다.
- Native navigation bar에는 웹 액션 버튼을 추가하지 않는다.
- 모달에 별도 완료 버튼을 추가하지 않고 웹 폼의 저장 버튼을 사용한다.
- 웹 본문의 페이지 title과 웹용 뒤로가기는 Native에서 숨기고, title과 뒤로가기는 Native navigation bar가 담당한다.
- 웹 계정 설정(`/mypage/user`)과 네이티브 앱 설정을 구분한다.
- 로컬 Path Configuration을 fallback으로 두고 환경별 서버 설정을 마지막에 로드한다.
- 미인증 `401`은 세션 쿠키를 별도 복제하지 않고 웹 로그인 화면으로 연결한다.
