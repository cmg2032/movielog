# MovieLog (Flutter)

TMDB 영화 정보와 MovieLog 워크북 서버(v7)를 연결한 영화 평점 앱입니다.

## 8주차: 로그인과 토큰 인증

### 구조

| 구분 | Client | 토큰 | 사용하는 API |
|---|---|---|---|
| TMDB | `createTmdbClient()` | TMDB Read Access Token (.env) | 영화 목록·상세·장르 |
| MovieLog 공개 | `createMovieLogClient()` | 없음 | 로그인, 중복 체크, 회원가입, 유저별 평점 조회 |
| MovieLog 보호 | `createAuthMovieLogClient()` + `AuthInterceptor` | MovieLog JWT | 내 정보 조회·수정, 내 평점, 평점 등록·수정·삭제 |

- JWT는 `flutter_secure_storage`(`SecureTokenStorage`)에만 저장합니다. 비밀번호는 저장하지 않고 로그에도 남기지 않습니다.
- `AuthInterceptor`는 MovieLog 서버(baseUrl과 같은 호스트)의 보호 경로에만 `Authorization: Bearer`를 붙입니다.
- 로그인 화면의 "이메일 저장"은 이메일만 `shared_preferences`에 저장합니다.

### 오류 구분

| 상황 | 처리 |
|---|---|
| 로그인 401 (`AUTH401_1`) | 입력 오류 문구. 세션·만료 안내와 무관 |
| 보호 API 401 (`AUTH401_2/3/4`) | 세션 정리 → `/login` 이동 + 만료 SnackBar 한 번 |
| 403 (`RATING403_1`), 409 | 안내만, 로그인 유지 |
| 네트워크 실패 | 토큰 삭제·로그아웃 없음. 앱 시작이면 Splash 재시도, 그 외 재시도 버튼·안내 |

- 앱 재시작: 저장된 토큰 → `GET /v7/members/me` 성공 뒤에만 `signedIn`(홈 이동)
- 신규 로그인: 토큰 저장 → `signedIn` → `MainScreen`이 `loadMember()`로 내 정보 조회
- `sessionVersion`으로 로그아웃·회원 전환 뒤 늦게 도착한 이전 응답을 무시합니다.

### 알려진 한계: 내 평점 전체 복원

- v7 로그인 응답(`nickname`, `accessToken`)과 `GET /v7/members/me`(`email`, `nickname`, `createdAt`)에는 **memberId가 없습니다.** JWT payload에서 memberId를 꺼내 쓰지도 않습니다.
- 워크북 v7에는 **토큰으로 내 평점 전체를 조회하는 API가 없고**, 유저별 평점 조회는 memberId가 필요한 공개 API(`GET /v7/members/{memberId}/ratings`)뿐입니다.
- 따라서 워크북 계약만으로는 앱 재시작·재로그인 후 "내가 등록한 평점" 전체를 복원할 수 없습니다.
- 이 프로젝트는 로컬 NestJS 서버에 `GET /v7/members/me/ratings`(AuthGuard, 토큰의 memberId로 조회)를 추가해 이 화면을 구현했습니다. **워크북 서버(`workbook.devnoco.com`)로 바꾸면 이 경로가 없어 내 평점 목록이 동작하지 않습니다.**
- 평점은 `movieId`(TMDB id)로 TMDB 영화 정보를 연결하며, TMDB에서 찾지 못한 영화는 제목·포스터 대신 placeholder로 표시합니다.

### 실행 환경

- Flutter 3.50.0 (Dart 3.14.0), `material_ui` 패키지 사용
- `.env`: `TMDB_ACCESS_TOKEN`, `MOVIELOG_BASE_URL` (기본값 `http://10.0.2.2:3000`, 안드로이드 에뮬레이터 → 로컬 서버)
- `.env`는 저장소에 올리지 않습니다.

### 검증 기록

- `flutter analyze`: No issues found
- `flutter test`: 57개 통과 (인증 상태·redirect·Interceptor·로그인/마이페이지/프로필 수정 위젯·평점 API)

수동 검증 (플랫폼: ________ / 날짜: ________)

- [ ] 첫 실행: Splash → 로그인 화면
- [ ] 로그인 성공 → 홈, 마이페이지에 닉네임·가입일·이메일 표시
- [ ] 앱 재시작 → Splash → GET me 성공 뒤 홈 (secure storage 토큰 유지)
- [ ] 서버를 끈 채 재시작 → Splash 재시도 화면, 토큰 유지
- [ ] 이메일·비밀번호 오류 → 입력 오류 문구 (만료 SnackBar 없음)
- [ ] 평점 등록·수정·삭제 (Authorization 헤더만으로 처리)
- [ ] 이미 평점이 있는 영화 등록 → 409 안내, 로그인 유지
- [ ] 닉네임 수정: 2~12자 검증, 중복(409) 입력값 유지, 성공 시 마이페이지 즉시 반영
- [ ] 변경 후 뒤로가기 → 확인 Dialog
- [ ] 로그아웃 → 로그인 화면, 재시작 시 자동 로그인 안 됨
- [ ] 토큰 만료(401) → 로그인 화면 + 만료 SnackBar 한 번
