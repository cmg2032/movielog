import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Dio createMovieLogClient() {
  final baseUrl = dotenv.env['MOVIELOG_BASE_URL'] ?? 'http://10.0.2.2:3000';

  return Dio(
    BaseOptions(
      baseUrl: baseUrl, // /v6는 넣지 않기 (서비스 코드가 /v6/... 로 붙임). TMDB 토큰 헤더 없음
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'accept': 'application/json'},
    ),
  );
}
