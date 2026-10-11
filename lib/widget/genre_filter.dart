import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
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

class GenreFilterSheet extends StatelessWidget {
  const GenreFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final genres = movies.map((m) => m.genre).toSet().toList();

    return ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          title: const Text('전체'),
          onTap: () {
            final router = GoRouter.of(context);
            Navigator.pop(context);
            router.go('/movies');
          },
        ),
        for (final g in genres)
          ListTile(
            title: Text(g),
            onTap: () {
              final router = GoRouter.of(context);
              Navigator.pop(context);
              router.go(
                Uri(path: '/movies', queryParameters: {'genre': g}).toString(),
              );
            },
          ),
      ],
    );
  }
}
