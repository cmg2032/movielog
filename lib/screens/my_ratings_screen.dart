import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/rating_api_service.dart';
import '../models/rating_dto.dart';
import '../models/rating_with_movie.dart';
import '../theme/app_colors.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

// ─────────────────────────────────────────────
// 내가 등록한 평점: 화면 (/my/ratings)
// 중앙 AppBar + 뒤로가기, 하단 NavigationBar 없음
// ─────────────────────────────────────────────

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyRatingsViewModel>();
    final canSelect =
        viewModel.status == MyRatingsLoadStatus.success &&
        viewModel.ratings.isNotEmpty;

    final isDeleting = viewModel.isDeletingSelected;
    final selectedCount = viewModel.selectedRatingIds.length;

    // 다중 삭제 중: 뒤로가기 막고, 화면 전체(AppBar·하단 버튼 포함)를 덮어 다른 조작을 막음
    return PopScope(
      canPop: !isDeleting,
      child: LoadingOverlay(
        isLoading: isDeleting,
        child: Scaffold(
          appBar: CommonAppBar(
            title: '내가 등록한 평점',
            centerTitle: true,
            // context.pop()은 PopScope를 거치지 않으므로 삭제 중에는 직접 막음
            onBack: () {
              if (isDeleting) return;
              context.pop();
            },
          ),
          bottomNavigationBar: viewModel.isSelecting && canSelect
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: MovieLogButton(
                      label: '선택한 $selectedCount개 삭제',
                      width: double.infinity,
                      height: 56,
                      borderRadius: 28,
                      // 선택이 1개 이상일 때만 활성화
                      onPressed: selectedCount == 0 || isDeleting
                          ? null
                          : () => onDeleteSelectedPressed(context),
                    ),
                  ),
                )
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 편집 줄: 기본 = 오른쪽 [편집] / 선택 중 = 왼쪽 "N개 선택됨" + 오른쪽 [취소]
              if (canSelect || viewModel.isSelecting)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
                  child: Row(
                    children: [
                      if (viewModel.isSelecting)
                        Text(
                          '$selectedCount개 선택됨',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.violet,
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: isDeleting
                            ? null
                            : viewModel.toggleSelecting,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.violet,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(viewModel.isSelecting ? '취소' : '편집'),
                      ),
                    ],
                  ),
                ),
              const Expanded(child: _MyRatingsListView()),
            ],
          ),
        ),
      ),
    );
  }
}

/// 평점 목록 본문 (로딩 / 에러 / 빈 목록 / 목록)
class _MyRatingsListView extends StatelessWidget {
  const _MyRatingsListView();

  @override
  Widget build(BuildContext context) {
    return Consumer<MyRatingsViewModel>(
      builder: (context, viewModel, child) {
        switch (viewModel.status) {
          case MyRatingsLoadStatus.idle:
          case MyRatingsLoadStatus.loading:
            return const Center(child: CircularProgressIndicator());

          case MyRatingsLoadStatus.error:
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.gray,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      viewModel.message ?? '평점을 불러오지 못했습니다.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: viewModel.load,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            );

          case MyRatingsLoadStatus.empty:
            return const Center(child: Text('아직 등록한 평점이 없어요.'));

          case MyRatingsLoadStatus.success:
            final hasNotice = viewModel.message != null;
            return RefreshIndicator(
              color: AppColors.violet,
              onRefresh: viewModel.load,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: viewModel.ratings.length + (hasNotice ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (hasNotice && index == 0) {
                    return _NoticeBanner(message: viewModel.message!);
                  }
                  final entry = viewModel.ratings[index - (hasNotice ? 1 : 0)];
                  return _MyRatingCard(
                    entry: entry,
                    isSelecting: viewModel.isSelecting,
                    isSelected: viewModel.selectedRatingIds.contains(
                      entry.rating.ratingId,
                    ),
                    onSelectedChanged: viewModel.isDeletingSelected
                        ? null
                        : () => viewModel.toggleSelected(entry.rating.ratingId),
                  );
                },
              ),
            );
        }
      },
    );
  }
}

/// 선택한 평점 삭제: 확인 Dialog는 바로 닫히고, 삭제는 화면에서 진행 (로딩 오버레이 표시)
Future<void> onDeleteSelectedPressed(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _ConfirmDialogLayout(
      title: '선택한 평점을 삭제할까요?',
      message: '삭제한 평점은 복구할 수 없습니다.',
      confirmLabel: '삭제',
      onCancel: () => Navigator.pop(dialogContext, false),
      onConfirm: () => Navigator.pop(dialogContext, true),
    ),
  );
  // 여기서 Dialog는 바로 닫힙니다. 삭제 요청은 Dialog가 닫힌 뒤 화면에서 시작합니다.

  if (confirmed != true || !context.mounted) return;

  final viewModel = context.read<MyRatingsViewModel>();
  try {
    await viewModel.deleteSelectedRatings();
  } catch (_) {
    // 예상하지 못한 오류(예: 204가 아닌 삭제 응답): 로딩은 ViewModel이 이미 해제함
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('삭제 중 오류가 발생했습니다. 목록을 새로고침해 주세요.')),
      );
    return;
  }

  if (!context.mounted) return;
  // 일부만 실패: 성공한 항목은 이미 목록에서 사라졌고, 실패 개수를 SnackBar로 안내
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(viewModel.deleteSelectedMessage ?? '선택한 평점을 삭제했습니다.'),
      ),
    );
}

/// 삭제 확인 Dialog 공통 모양: 가운데 제목 + 안내 문구 + [취소] [확인] 버튼
class _ConfirmDialogLayout extends StatelessWidget {
  const _ConfirmDialogLayout({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.isLoading = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool isLoading; // 확인 버튼에 로딩 표시

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 48, 36, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.gray),
            ),
            const SizedBox(height: 56),
            Row(
              children: [
                Expanded(
                  child: MovieLogButton(
                    label: '취소',
                    height: 52,
                    backgroundColor: AppColors.lightViolet,
                    foregroundColor: AppColors.violet,
                    onPressed: onCancel,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: MovieLogButton(
                    label: confirmLabel,
                    height: 52,
                    isLoading: isLoading,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 평점 수정 Dialog 열기 (저장은 Dialog 안에서 onSubmit으로 실행)
Future<void> onEditPressed(BuildContext context, RatingDto rating) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => RatingDialog(
      initialScore: rating.score,
      initialComment: rating.comment, // null이면 TextField가 빈 칸으로 시작합니다.
      onSubmit: (score, comment) =>
          context.read<MyRatingsViewModel>().updateRating(
            ratingId: rating.ratingId,
            score: score,
            comment: comment,
          ),
    ),
  );

  if (!context.mounted || saved != true) return;
}

/// 평점 삭제 확인 Dialog 열기 (삭제는 Dialog 안에서 onConfirm으로 실행)
Future<void> onDeletePressed(BuildContext context, RatingDto rating) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 삭제 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => _DeleteRatingDialog(
      onConfirm: () =>
          context.read<MyRatingsViewModel>().deleteRating(rating.ratingId),
    ),
  );
  // confirmed는 실제로 삭제까지 마쳤을 때만 true입니다.
  if (!context.mounted || confirmed != true) return;
}

class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.onConfirm});
  final Future<void> Function() onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: _ConfirmDialogLayout(
        title: '평점을 삭제할까요?',
        message: '삭제한 평점은 복구할 수 없습니다.',
        confirmLabel: '삭제',
        isLoading: _isDeleting,
        onCancel: _isDeleting ? null : () => Navigator.pop(context, false),
        onConfirm: _isDeleting ? null : _onConfirm,
      ),
    );
  }

  Future<void> _onConfirm() async {
    setState(() => _isDeleting = true);
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is DioException
                ? writeErrorMessage(error)
                : '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.',
          ),
        ),
      );
    }
  }
}

class _MyRatingCard extends StatelessWidget {
  const _MyRatingCard({
    required this.entry,
    this.isSelecting = false,
    this.isSelected = false,
    this.onSelectedChanged,
  });

  final RatingWithMovie entry;
  final bool isSelecting; // 선택 모드면 체크박스 카드 (탭 = 선택), 수정·삭제 버튼 없음
  final bool isSelected;
  final VoidCallback? onSelectedChanged;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;

    // TMDB에서 영화를 찾지 못하면 대체 제목
    final title = (movie != null && movie.title.isNotEmpty)
        ? movie.title
        : '영화 #${rating.movieId}';

    final comment = rating.comment?.trim() ?? '';
    final hasPoster = movie?.posterPath != null;

    if (isSelecting) {
      return Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.outline, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelectedChanged, // 카드 어디를 눌러도 선택/해제
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 128),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 24, 24),
              child: Row(
                children: [
                  Transform.scale(
                    scale: 1.3,
                    child: Checkbox(
                      value: isSelected,
                      activeColor: AppColors.violet,
                      side: const BorderSide(color: AppColors.gray, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: onSelectedChanged == null
                          ? null
                          : (_) => onSelectedChanged!(),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$title · 별점 ${rating.score}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            comment,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.outline, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // 영화 정보가 있을 때만 상세로 이동 (TMDB id 전달)
        onTap: movie == null
            ? null
            : () => context.push(
                '/movies/${movie.id}',
                extra: movie, // TmdbMovieDto 그대로 넘기면 상세에서 다시 받지 않음
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 포스터 (없으면 빈 박스)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 82,
                  height: 124,
                  child: hasPoster
                      ? TmdbPosterImage(
                          posterPath: movie!.posterPath,
                          width: 82,
                          height: 124,
                        )
                      : const ColoredBox(color: AppColors.outline),
                ),
              ),
              const SizedBox(width: 16),

              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '별점 ${rating.score} / 5',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.violet,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      comment.isNotEmpty
                          ? comment
                          : (hasPoster ? '작성한 후기가 없어요' : '포스터 정보 없음'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CardActionButton(
                    label: '수정',
                    backgroundColor: AppColors.lightViolet,
                    foregroundColor: AppColors.violet,
                    onPressed: () => onEditPressed(context, rating),
                  ),
                  const SizedBox(height: 12),
                  _CardActionButton(
                    label: '삭제',
                    backgroundColor: AppColors.lightRed,
                    foregroundColor: AppColors.red,
                    onPressed: () => onDeletePressed(context, rating),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightViolet,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.violet),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

/// 평점 카드 오른쪽의 작은 버튼 (수정 / 삭제)
class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 36,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}
