import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// isLoading일 때 child 위를 반투명 배경 + 로딩 표시로 덮어 터치를 막음
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const ModalBarrier(dismissible: false, color: Colors.black45),
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.white),
          ),
      ],
    );
  }
}
