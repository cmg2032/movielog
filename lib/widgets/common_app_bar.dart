import 'package:flutter/material.dart';

import 'package:flutter_application_1/theme/app_colors.dart';
import 'package:flutter_application_1/theme/app_text_styles.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.titleStyle,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style:
            titleStyle ??
            AppTextStyles.titleLarge.copyWith(
              color: AppColors.violet,
              fontWeight: FontWeight.w700,
            ),
      ),
      centerTitle: centerTitle,
      leading: onBack == null
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              color: AppColors.violet,
              onPressed: onBack,
            ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
