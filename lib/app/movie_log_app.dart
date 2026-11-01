import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/tmdb_client.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart'; // AppTheme이 있는 실제 파일명에 맞게

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
