// lib/core/network/api_error.dart — 서버 공통 응답 { isSuccess, code, message, result }에서
// 오류 code와 message를 꺼내는 공통 함수입니다.
import 'package:dio/dio.dart';

import 'auth_interceptor.dart';

/// 서버 오류 code (예: AUTH401_3, RATING409_1). 응답이 없거나 JSON이 아니면 null
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

/// 서버 오류 message. 응답이 없거나 JSON이 아니면 null
String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

/// 보호 요청에서 토큰이 없음(2) / 무효(3) / 만료(4) → 현재 세션 정리 대상
/// AUTH401_1(로그인 입력 오류)은 포함하지 않습니다.
bool isSessionAuthError(DioException error) {
  final code = apiErrorCode(error);
  return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
}

/// 요청 전에 기기 저장소에서 토큰을 읽지 못해 거절된 오류인지
bool isTokenStorageError(DioException error) =>
    error.error is TokenStorageReadException;

/// 서버 응답이 없는 오류의 화면 문구 (응답이 있으면 null)
/// - 토큰 저장소 읽기 실패와 네트워크 연결 실패를 다른 문구로 보여줍니다.
String? noResponseMessage(DioException error) {
  if (error.response != null) return null;
  if (isTokenStorageError(error)) {
    return '기기에 저장된 로그인 정보를 읽지 못했어요. 다시 시도해 주세요.';
  }
  return '서버에 연결하지 못했어요. 네트워크를 확인해 주세요.';
}

/// 화면 문구: 서버 message → 없으면 연결 실패 / fallback
String serverMessage(DioException e, {String fallback = '잠시 후 다시 시도해 주세요.'}) {
  final message = apiErrorMessage(e);
  if (message != null) return message;
  return noResponseMessage(e) ?? fallback;
}
