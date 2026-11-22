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

  /// 토큰 원문은 일부도 찍지 않고, 붙어 있는지만 표시
  String _mask(String? value) {
    if (value == null || value.isEmpty || value == 'Bearer ') return '(없음)';
    return 'Bearer ****(있음)';
  }
}
