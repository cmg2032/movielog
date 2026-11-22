import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// 입력칸 위에 붙는 회색 라벨 (로그인·프로필 수정 공통)
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: AppColors.gray),
    );
  }
}

/// 둥근 테두리 입력칸 스타일 (로그인·프로필 수정 공통)
/// [readOnly]: 회색 배경 (예: 변경할 수 없는 이메일)
InputDecoration movieLogInputDecoration({
  bool readOnly = false,
  String? errorText,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: readOnly ? AppColors.lightGray : AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    errorText: errorText,
    border: border(AppColors.outline),
    enabledBorder: border(AppColors.outline),
    disabledBorder: border(AppColors.outline),
    focusedBorder: border(AppColors.violet),
    errorBorder: border(AppColors.red),
    focusedErrorBorder: border(AppColors.red),
  );
}
