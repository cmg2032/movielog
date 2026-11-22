// lib/app/movie_log_app.dart
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/tmdb_client.dart';
import '../core/network/movie_log_client.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/member_check_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/storage/saved_email_storage.dart';
import '../data/storage/token_storage.dart';
import '../router/app_router.dart';
import '../view_models/auth_view_model.dart';
import '../theme/app_theme.dart';

class MovieLogApp extends StatefulWidget {
  /// [tokenStorage]·[savedEmailStorage]: 테스트에서 메모리 저장소를 넣을 때 사용
  /// (기본은 보안 저장소 / shared_preferences)
  const MovieLogApp({super.key, this.tokenStorage, this.savedEmailStorage});

  final TokenStorage? tokenStorage;
  final SavedEmailStorage? savedEmailStorage;

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  // 저장소·Client·Service·세션은 앱이 살아 있는 동안 하나만 만듦 (Router는 _MovieLogRouterApp이 만듦)
  late final TokenStorage _tokenStorage =
      widget.tokenStorage ?? SecureTokenStorage(const FlutterSecureStorage());

  late final SavedEmailStorage _savedEmailStorage =
      widget.savedEmailStorage ?? PrefsSavedEmailStorage();

  // 공개 Client: Interceptor 없음 (로그인, 중복 체크, 회원가입, 유저별 평점 조회)
  late final Dio _publicClient = createMovieLogClient();

  // 보호 Client: AuthInterceptor 등록 (내 정보, 내 평점, 평점 등록/수정/삭제)
  // 401 만료 처리를 위해 세션을 요청 시점에 읽음 (세션이 이 Client를 쓰는 Service를 받으므로 늦게 읽기)
  late final Dio _authClient = createAuthMovieLogClient(
    _tokenStorage,
    readSession: () => _auth,
  );

  late final AuthApiService _authApiService = AuthApiService(_publicClient);
  late final MemberCheckService _memberCheckService = MemberCheckService(
    _publicClient,
  );
  late final MemberApiService _memberApiService = MemberApiService(_authClient);
  late final RatingApiService _ratingApiService = RatingApiService(
    _publicClient,
    _authClient,
  );

  // Service를 생성자로 주입받는 ViewModel
  late final AuthViewModel _auth = AuthViewModel(
    _authApiService,
    _memberApiService,
    _tokenStorage,
  );

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: _tokenStorage),
        // 로그인 화면 [이메일 저장]: 이메일만 shared_preferences에 저장
        Provider<SavedEmailStorage>.value(value: _savedEmailStorage),
        // TMDB Client에는 AuthInterceptor를 붙이지 않음 (MovieLog JWT가 TMDB로 가면 안 됨)
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        // 공개 Client
        Provider<AuthApiService>.value(value: _authApiService),
        Provider<MemberCheckService>.value(value: _memberCheckService),
        // 보호 Client (RatingApiService는 공개 조회용 Client도 함께 받음)
        Provider<MemberApiService>.value(value: _memberApiService),
        Provider<RatingApiService>.value(value: _ratingApiService),
        // Service를 주입받는 ViewModel
        ChangeNotifierProvider<AuthViewModel>.value(value: _auth),
      ],
      // providers는 그대로 두고 child만 Router 호스트로 교체
      child: const _MovieLogRouterApp(),
    );
  }
}

/// MaterialApp.router 호스트: GoRouter를 앱이 살아 있는 동안 한 번만 만듦
/// (build()에서 만들면 다시 그려질 때마다 Router가 새로 생겨 현재 위치가 초기화됨)
class _MovieLogRouterApp extends StatefulWidget {
  const _MovieLogRouterApp();

  @override
  State<_MovieLogRouterApp> createState() => _MovieLogRouterAppState();
}

class _MovieLogRouterAppState extends State<_MovieLogRouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authViewModel = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(authViewModel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) authViewModel.restoreSession();
    }); // 첫 build 이후 세션 복원을 시작합니다.
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
