import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/genre_filter.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_states.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.genreIds});

  /// URL의 ?genres=28,35 를 파싱한 값 (없으면 null = 전체)
  final List<int>? genreIds;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  MovieListViewModel? _viewModel;
  bool _isDialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<MovieListViewModel>();
    if (!identical(vm, _viewModel)) {
      _viewModel?.removeListener(_onViewModelChanged);
      _viewModel = vm..addListener(_onViewModelChanged);
    }
  }

  // URL이 바뀌어 들어온 경우(뒤로가기, 직접 이동 등) ViewModel과 맞추기
  @override
  void didUpdateWidget(covariant MovieListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final vm = _viewModel;
    if (vm == null) return;
    if (!_sameIds(widget.genreIds, vm.selectedGenreIds)) {
      // build 중에 상태를 바꾸면 안 되므로 프레임 끝난 뒤 적용
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) vm.applyGenres(widget.genreIds);
      });
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    super.dispose();
  }

  // ViewModel이 실패를 알리면 재시도 Dialog 표시
  void _onViewModelChanged() {
    final vm = _viewModel;
    if (vm == null || _isDialogOpen) return;
    if (!vm.takeRetryDialogRequest()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showRetryDialog(vm);
    });
  }

  Future<void> _showRetryDialog(MovieListViewModel vm) async {
    _isDialogOpen = true;

    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('요청 실패'),
        content: Text(vm.message ?? '영화 목록을 불러오지 못했어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('재시도'),
          ),
        ],
      ),
    );

    _isDialogOpen = false;
    if (retry == true && mounted) vm.retry();
  }

  // 필터 아이콘 → 드래그 가능한 장르 BottomSheet
  Future<void> _openGenreSheet() async {
    final vm = context.read<MovieListViewModel>();

    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true, // DraggableScrollableSheet가 커질 수 있게
      useSafeArea: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => GenreFilterSheet(
        genres: vm.genres,
        initialSelected: vm.selectedGenreIds,
      ),
    );

    if (result == null || !mounted) return; // 바깥 눌러 닫음 = 변경 없음

    final ids = result.isEmpty ? null : result; // 선택 없음 = 전체
    vm.applyGenres(ids);
    context.go(AppRouter.moviesLocation(ids)); // URL에 반영
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '영화',
        actions: [
          Consumer<MovieListViewModel>(
            builder: (context, viewModel, child) {
              final count = viewModel.selectedGenreIds?.length ?? 0;
              return IconButton(
                tooltip: '장르 필터',
                color: AppColors.violet,
                onPressed: viewModel.isBusy ? null : _openGenreSheet,
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  backgroundColor: AppColors.violet,
                  child: const Icon(Icons.filter_list),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Chip 줄 제거: 목록만
      body: Consumer<MovieListViewModel>(
        builder: (context, viewModel, child) {
          return RefreshIndicator(
            color: AppColors.violet,
            onRefresh: viewModel.refresh,
            notificationPredicate: (notification) =>
                !viewModel.isLoading && notification.depth == 0,
            child: switch (viewModel.status) {
              MovieListLoadStatus.idle ||
              MovieListLoadStatus.loading => const MovieListLoading(),
              MovieListLoadStatus.error => _ScrollableFill(
                child: MovieListError(
                  message: viewModel.message,
                  onRetry: viewModel.retry,
                ),
              ),
              MovieListLoadStatus.empty => const _ScrollableFill(
                child: MovieListEmpty(),
              ),
              MovieListLoadStatus.success => MovieGrid(
                movies: viewModel.movies,
                genres: viewModel.genres,
              ),
            },
          );
        },
      ),
    );
  }

  bool _sameIds(List<int>? a, List<int>? b) {
    final x = (a == null || a.isEmpty) ? null : a;
    final y = (b == null || b.isEmpty) ? null : b;
    if (x == null || y == null) return x == y;
    return x.length == y.length && x.toSet().containsAll(y);
  }
}

class _ScrollableFill extends StatelessWidget {
  const _ScrollableFill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
