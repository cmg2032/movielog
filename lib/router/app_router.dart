import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../data/services/member_check_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/movie.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/sign_up_view_model.dart';

class AppRouter {
  AppRouter._();

  /// root Navigator 키: 하단 탭을 가리는 전체 화면 라우트에 사용
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) =>
              SignUpViewModel(context.read<MemberCheckService>()),
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

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
                  // 최종 경로: /my/ratings
                  GoRoute(
                    path: 'ratings',
                    // root Navigator 위에 띄워서 하단 NavigationBar를 가림
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        ChangeNotifierProvider<MyRatingsViewModel>(
                          create: (context) => MyRatingsViewModel(
                            context.read<RatingApiService>(),
                            context.read<TmdbMovieService>(),
                            sampleMemberId, // 학습용 ID 1
                          )..load(),
                          child: const MyRatingsScreen(),
                        ),
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
          final movieId = int.tryParse(state.pathParameters['movieId'] ?? '');
          final movie = state.extra as Movie? ?? findMovieById(movieId);
          if (movie == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('영화를 찾을 수 없습니다')),
            );
          }
          return MovieDetailScreen(movie: movie);
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
