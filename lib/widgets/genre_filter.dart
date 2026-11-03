import 'package:flutter/material.dart';

import '../models/tmdb_genre_dto.dart';
import '../theme/app_colors.dart';

class GenreChip extends StatelessWidget {
  const GenreChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.violet,
      backgroundColor: AppColors.lightViolet,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.white : AppColors.black,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

/// 장르 필터 BottomSheet
/// - 처음엔 화면 절반 높이, 목록을 위로 끌어올리면 최대 90%까지 펼쳐짐
/// - 체크는 시트 안에서만 바뀌고, [확인]을 눌러야 실제 필터로 적용
/// - 확인: 선택한 id 목록 반환 (빈 목록 = 전체), 바깥 눌러 닫기: null
class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    this.initialSelected,
  });

  final List<TmdbGenreDto> genres;
  final List<int>? initialSelected;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  // 시트 안에서만 쓰는 임시 선택 상태 (확인 전까지 영화 목록에 영향 없음)
  late final Set<int> _draft = {...?widget.initialSelected};

  void _toggle(int id) {
    setState(() {
      if (!_draft.remove(id)) _draft.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5, // 처음 열릴 때 화면의 50%
      minChildSize: 0.3,
      maxChildSize: 0.9, // 위로 끌면 90%까지
      builder: (context, scrollController) {
        return Column(
          children: [
            // 드래그 핸들
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 제목 + 안내 문구
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '장르 필터',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '여러 장르를 선택할 수 있어요',
                      style: TextStyle(fontSize: 14, color: AppColors.gray),
                    ),
                  ],
                ),
              ),
            ),

            // 장르 체크박스 목록 (이 영역만 스크롤)
            Expanded(
              child: Scrollbar(
                controller: scrollController,
                child: ListView.builder(
                  controller: scrollController, // 시트 높이 조절과 연결
                  itemCount: widget.genres.length,
                  itemBuilder: (context, index) {
                    final genre = widget.genres[index];
                    return CheckboxListTile(
                      value: _draft.contains(genre.id),
                      onChanged: (_) => _toggle(genre.id),
                      title: Text(
                        genre.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                      ),
                      activeColor: AppColors.violet,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      visualDensity: const VisualDensity(vertical: 1),
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1),

            // 확인 버튼 (하단 고정)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.violet,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, _draft.toList()),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
