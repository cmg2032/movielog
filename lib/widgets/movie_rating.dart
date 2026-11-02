import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 0.5,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: 40,
      itemBuilder: (context, index) {
        return const Icon(Icons.star, color: Colors.amber);
      },
      onRatingUpdate: onChanged,
    );
  }
}

class MovieRatingDisplay extends StatelessWidget {
  const MovieRatingDisplay({
    super.key,
    required this.rating,
    this.itemSize = 24,
    this.color = Colors.amber,
  });

  final double rating;
  final double itemSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBarIndicator(
          rating: rating,
          itemCount: 5,
          itemSize: itemSize,
          itemBuilder: (context, index) {
            return Icon(Icons.star, color: color);
          },
        ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// 별점 남기기 Dialog
/// - 반환값: 선택한 점수(0.5~5.0), 0.0 = 평점 삭제, null = 변경 없이 닫기
class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, this.initialRating = 0});

  /// 이미 남긴 평점 (없으면 0)
  final double initialRating;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double _rating = widget.initialRating;

  /// 이미 평가한 영화면 읽기 전용으로 시작
  late bool _isEditing = widget.initialRating == 0;

  /// 바뀌면 별 입력 위젯을 새로 만들어 화면의 별까지 초기화
  int _inputKey = 0;

  bool get _hasSavedRating => widget.initialRating > 0;

  void _reset() {
    setState(() {
      _rating = 0;
      _inputKey++;
    });
  }

  void _startReselect() {
    setState(() {
      _isEditing = true;
      _inputKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEditing ? '영화는 어떠셨나요?' : '내가 남긴 평점',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),

            // 별 영역
            if (_isEditing)
              MovieRatingInput(
                key: ValueKey(_inputKey),
                rating: _rating,
                onChanged: (value) => setState(() => _rating = value),
              )
            else
              MovieRatingDisplay(rating: _rating, itemSize: 36),

            const SizedBox(height: 12),
            Text(
              _rating > 0
                  ? '${_rating.toStringAsFixed(1)}점'
                  : '별을 눌러 평점을 선택해 주세요',
              style: const TextStyle(fontSize: 14, color: AppColors.gray),
            ),
            const SizedBox(height: 24),

            // 버튼 영역
            if (_isEditing) _buildEditButtons() else _buildViewButtons(),
          ],
        ),
      ),
    );
  }

  // 선택 중: [평점 초기화] [확인]
  Widget _buildEditButtons() {
    // 처음 평가인데 아무것도 안 골랐으면 확인할 게 없음
    final canConfirm = _rating > 0 || _hasSavedRating;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _rating > 0 ? _reset : null,
            child: const Text('평점 초기화'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: canConfirm
                ? () => Navigator.pop(context, _rating)
                : null,
            child: Text(_rating == 0 && _hasSavedRating ? '평점 삭제' : '확인'),
          ),
        ),
      ],
    );
  }

  // 이미 평가함: [다시 선택하기] [닫기]
  Widget _buildViewButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _startReselect,
            child: const Text('다시 선택하기'),
          ),
        ),
      ],
    );
  }
}
