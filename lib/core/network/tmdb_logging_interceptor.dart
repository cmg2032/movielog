import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TmdbLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final auth = options.headers['Authorization'] as String?;
    debugPrint('➡️ ${options.method} ${options.uri}');
    debugPrint('   Authorization: ${_mask(auth)}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('✅ ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final code = err.response?.statusCode;

    debugPrint('❌ ${code ?? '-'} ${options.method} ${options.uri}');
    debugPrint('   type: ${err.type.name}');
    debugPrint('   message: ${err.message ?? err.error}');
    debugPrint(
      '   Authorization: ${_mask(options.headers['Authorization'] as String?)}',
    );
    if (code == 401) {
      debugPrint('   → 토큰이 잘못되었거나 비어 있어요. .env를 확인하세요.');
    }
    handler.next(err);
  }

  /// "Bearer eyJhbGciOi...Xy9z" → "Bearer eyJh****Xy9z"
  String _mask(String? value) {
    if (value == null || value.isEmpty) return '(없음)';

    const prefix = 'Bearer ';
    final token = value.startsWith(prefix)
        ? value.substring(prefix.length)
        : value;

    if (token.length <= 8) return '$prefix****';
    return '$prefix${token.substring(0, 4)}****${token.substring(token.length - 4)}';
  }
}
