import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import '../theme/app_colors.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

/// 별점 + 코멘트 입력 Dialog
/// - 저장 로직은 [onSubmit]으로 받아 Dialog 안에서 실행 (저장 중 상태를 Dialog가 관리)
/// - 반환값: onSubmit 성공 = true, 취소 = false (onSubmit 호출 안 함)
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
  });

  final int initialScore;
  final String? initialComment;
  final Future<void> Function(int score, String? comment) onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;
  late final _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 저장 중에는 뒤로가기·바깥 탭으로 닫히지 않게 막음
      canPop: !_isSubmitting,
      child: Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '평점을 남겨주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: MovieRatingInput(
                    rating: _score.toDouble(),
                    enabled: !_isSubmitting,
                    onChanged: (value) =>
                        setState(() => _score = validateServerScore(value)),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  '코멘트 (선택, 최대 500자)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  minLines: 4,
                  maxLines: 4,
                  maxLength: 500,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: '이 영화의 인상적인 장면은...',
                    hintStyle: const TextStyle(color: AppColors.gray),
                    counterText: '', // 글자 수 제한은 위 라벨로 안내
                    filled: true,
                    fillColor: AppColors.paleViolet,
                    contentPadding: const EdgeInsets.all(16),
                    enabledBorder: _border(AppColors.outline),
                    disabledBorder: _border(AppColors.outline),
                    focusedBorder: _border(AppColors.violet),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorText!,
                    style: const TextStyle(fontSize: 13, color: AppColors.red),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: MovieLogButton(
                        label: '취소',
                        height: 52,
                        borderRadius: 26,
                        backgroundColor: AppColors.lightViolet,
                        foregroundColor: AppColors.violet,
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MovieLogButton(
                        label: '확인',
                        height: 52,
                        borderRadius: 26,
                        isLoading: _isSubmitting,
                        onPressed: _score > 0 && !_isSubmitting
                            ? _onConfirm
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: 1.5),
  );

  Future<void> _onConfirm() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final trimmed = _commentController.text.trim();
    if (trimmed.length > 500) {
      setState(() {
        _isSubmitting = false;
        _errorText = '코멘트는 500자 이하로 입력해 주세요.';
      });
      return;
    }
    try {
      await widget.onSubmit(_score, trimmed.isEmpty ? null : trimmed);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      // 입력한 별점·코멘트는 그대로 두고 문구만 표시 (서버 응답이 있으면 그 message)
      setState(() {
        _isSubmitting = false;
        _errorText = error is DioException
            ? writeErrorMessage(error)
            : '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      });
    }
  }
}
