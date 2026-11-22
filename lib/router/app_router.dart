import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/member_check_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/tmdb_movie_dto.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_loader.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';
import '../widgets/movielog_button.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../view_models/sign_up_view_model.dart';

/// 세션 상태에 맞게 이동할 경로를 정함 (null이면 그대로)
String? authRedirect(AuthStatus status, String location) {
  const publicPaths = {'/login', '/register'};
  final atStart = location == '/start';
  final atPublic = publicPaths.contains(location);

  return switch (status) {
    // 토큰 확인 중 또는 확인 실패(재시도 버튼): 스플래시 화면 유지
    AuthStatus.initializing ||
    AuthStatus.retryRequired => atStart ? null : '/start',
    // 로그아웃 또는 로그인 요청 중: 공개 화면만 허용
    AuthStatus.signedOut ||
    AuthStatus.authenticating => atPublic ? null : '/login',
    // 로그인됨: 스플래시와 로그인·회원가입 화면은 홈으로 보냄
    AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
  };
}

class AppRouter {
  AppRouter._();

  /// root Navigator 키: 하단 탭을 가리는 전체 화면 라우트에 사용
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  /// 앱 시작은 /start(Splash). 앱이 살아 있는 동안 한 번만 만듭니다 (_MovieLogRouterApp.initState)
  /// redirect는 이동할 때만 호출되므로, 인증 상태가 바뀌었을 때도 다시 검사하도록
  /// refreshListenable에 AuthViewModel을 연결합니다.
  static GoRouter createRouter(AuthViewModel authViewModel) => GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey,
    refreshListenable: authViewModel, // 인증 상태가 바뀌면 redirect를 다시 실행합니다.
    // 상태만 읽고 판단합니다. 여기서 API 호출 같은 비동기 작업은 하지 않습니다.
    redirect: (context, state) =>
        authRedirect(authViewModel.status, state.uri.path),
    routes: [
      // 1주차 StartScreen 자리: 세션 확인 중 인디케이터 / 실패 시 [다시 시도]
      GoRoute(
        path: '/start',
        builder: (context, state) {
          final auth = context.watch<AuthViewModel>();
          return SplashScreen(
            message: auth.message,
            // retryRequired일 때만 [다시 시도], 그 외(initializing)는 인디케이터
            onRetry: auth.status == AuthStatus.retryRequired
                ? auth.restoreSession
                : null,
          );
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) => SignUpViewModel(
            context.read<MemberCheckService>(),
            context.read<AuthApiService>(),
          ),
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        // 로그인 화면은 AuthViewModel.login()만 호출 (별도 ViewModel 없음)
        builder: (context, state) => const LoginScreen(),
      ),

      // 탭별 Navigation 상태 보존
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          // 0: 홈
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) =>
                    ChangeNotifierProvider<MovieHomeViewModel>(
                      create: (context) =>
                          MovieHomeViewModel(context.read<TmdbMovieService>())
                            ..loadPopular(),
                      child: const HomeScreen(),
                    ),
              ),
            ],
          ),

          // 1: 영화 (/movies?genres=28,35)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (context, state) {
                  final genreIds = parseGenreIds(
                    state.uri.queryParameters['genres'],
                  );
                  return ChangeNotifierProvider<MovieListViewModel>(
                    create: (context) => MovieListViewModel(
                      context.read<TmdbMovieService>(),
                      initialGenreIds: genreIds,
                    )..loadInitial(),
                    child: MovieListScreen(genreIds: genreIds),
                  );
                },
              ),
            ],
          ),

          // 2: 마이
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  // 최종 경로: /my/profile/edit (마이페이지 수정 버튼은 member != null일 때만 켜짐)
                  GoRoute(
                    path: 'profile/edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final auth = context.watch<AuthViewModel>();
                      if (auth.member == null) {
                        // 주소로 바로 들어온 경우 등: 내 정보 준비 전 / 실패 시 재시도
                        return Scaffold(
                          appBar: AppBar(
                            centerTitle: true,
                            title: const Text('프로필 수정'),
                          ),
                          body: Center(
                            child: auth.memberStatus == MemberLoadStatus.error
                                ? MovieLogButton(
                                    label: '다시 시도',
                                    onPressed: () =>
                                        auth.loadMember(force: true),
                                  )
                                : const CircularProgressIndicator(),
                          ),
                        );
                      }
                      return ChangeNotifierProvider<EditProfileViewModel>(
                        create: (context) => EditProfileViewModel(
                          context.read<MemberApiService>(),
                          auth,
                        ),
                        child: const EditProfileScreen(),
                      );
                    },
                  ),
                  // 최종 경로: /my/ratings
                  GoRoute(
                    path: 'ratings',
                    // root Navigator 위에 띄워서 하단 NavigationBar를 가림
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      if (!context.read<AuthViewModel>().isLoggedIn) {
                        return Scaffold(
                          appBar: AppBar(
                            centerTitle: true,
                            title: const Text('내가 등록한 평점'),
                          ),
                          body: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('로그인이 필요합니다.'),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => context.go('/login'),
                                  child: const Text('로그인하러 가기'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ChangeNotifierProvider<MyRatingsViewModel>(
                        create: (context) => MyRatingsViewModel(
                          context.read<RatingApiService>(),
                          context.read<TmdbMovieService>(),
                        )..load(),
                        child: const MyRatingsScreen(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // 상세 (탭 바깥, 전체 화면)
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['movieId'] ?? '');
          if (id == null || id < 1) {
            return const Scaffold(
              body: Center(child: Text('영화 ID가 올바르지 않습니다.')),
            );
          }
          final extra = state.extra;
          return MovieDetailLoader(
            movieId: id,
            initialMovie: extra is TmdbMovieDto && extra.id == id
                ? extra
                : null,
          );
        },
      ),
    ],
  );

  /// "28,35" → [28, 35]. 비었거나 잘못된 값이면 null(전체)
  static List<int>? parseGenreIds(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final ids = raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
    return ids.isEmpty ? null : ids;
  }

  /// [28, 35] → "/movies?genres=28%2C35", null → "/movies"
  static String moviesLocation(List<int>? genreIds) {
    if (genreIds == null || genreIds.isEmpty) return '/movies';
    return Uri(
      path: '/movies',
      queryParameters: {'genres': genreIds.join(',')},
    ).toString();
  }
}
