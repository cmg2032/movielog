import 'package:material_ui/material_ui.dart';

abstract final class AppColors {
  static const violet = Color(0xFF6750A4);
  static const lightViolet = Color(0xFFEADDFF);

  static const warmWhite = Color(0xFFFAF9F5);
  static const white = Color(0xFFFFFFFF);
  static const lightGray = Color(0xFFF5F3F0);

  static const black = Color(0xFF1C1B1F);
  static const gray = Color(0xFF79747E);

  // 삭제 버튼 (연한 빨강 배경 + 빨강 글씨)
  static const red = Color(0xFFB3261E);
  static const lightRed = Color(0xFFFFEEEE);

  // 카드 테두리·포스터 자리, 입력창 배경
  static const outline = Color(0xFFD9D4E3);
  static const paleViolet = Color(0xFFF9F7FC);
  static const TextStyle chipLabel = TextStyle(color: AppColors.violet);
}
