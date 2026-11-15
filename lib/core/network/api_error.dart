// lib/core/network/api_error.dart
import 'package:dio/dio.dart';

String serverMessage(DioException e, {String fallback = '잠시 후 다시 시도해 주세요.'}) {
  final data = e.response?.data;
  if (data is Map && data['message'] is String) {
    return data['message'] as String;
  }
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout) {
    return '서버에 연결하지 못했어요. 네트워크를 확인해 주세요.';
  }
  return fallback;
}
