import 'package:flutter/material.dart';

void main() {
  for (final Movie movie in movies) {
    debugPrint('${movie.id}. ${movie.title}');
  }
  debugPrint('닉네임: ${displayName(nickname)}');

  runApp(const MovieLogApp());
}

const List<Movie> movies = [
  Movie(id: 1, title: '오디세이'),
  Movie(id: 2, title: '어벤져스'),
  Movie(id: 3, title: '스파이더맨'),
];

const String? nickname = '티모';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const StartScreen(),
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.movie_outlined,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'MovieLog',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '영화의 순간을 기록하세요',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '보고싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: const Text('시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String displayName(String? nickname) {
  final String? trimmedNickname = nickname?.trim();

  if (trimmedNickname == null || trimmedNickname.isEmpty) {
    return '이름 없음';
  }

  return trimmedNickname;
}

class Movie {
  const Movie({
    required this.id,
    required this.title,
  });

  final int id;
  final String title;
}