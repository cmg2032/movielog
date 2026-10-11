import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../screen/home_screen.dart';
import '../screen/main_screen.dart';
import '../screen/movie_detail_screen.dart';
import '../screen/movie_list_screen.dart';
import '../screen/profile_screen.dart';
import '../screen/register_screen.dart';
import '../screen/start_screen.dart';
import '../screen/login_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(
            currentIndex: indexFromLocation(state.uri.path),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) {
              final genre = state.uri.queryParameters['genre'];
              return MovieListScreen(genre: genre);
            },
          ),
          GoRoute(
            path: '/my',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final movieId = state.pathParameters['movieId'];
          final movie = findMovieById(int.tryParse(movieId ?? ''));
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

  static int indexFromLocation(String path) {
    if (path.startsWith('/movies')) return 1;
    if (path.startsWith('/my')) return 2;

    return 0;
  }
}
