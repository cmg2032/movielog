import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../widget/common_app_bar.dart';
import '../widget/genre_filter.dart';
import '../widget/movie_card.dart';
import '../models/movie.dart';
import '../services/genre_preference.dart';
import '../widget/movie_list_states.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.genre});

  final String? genre;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final movieService = const FakeMovieService();
  final genrePreference = GenrePreference();

  late Future<List<Movie>> _moviesFuture;
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _selectedGenre = widget.genre;
    _moviesFuture = _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant MovieListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.genre != widget.genre) {
      _selectedGenre = widget.genre;
      genrePreference.save(widget.genre ?? '전체');
    }
  }

  Future<List<Movie>> _loadInitialData() async {
    final results = await Future.wait([
      movieService.fetchMovies(),
      genrePreference.read(),
    ]);

    final loadedMovies = results[0] as List<Movie>;
    final savedGenre = results[1] as String;

    if (widget.genre == null && savedGenre != '전체' && mounted) {
      setState(() {
        _selectedGenre = savedGenre;
      });
    }

    return loadedMovies;
  }

  void _retry() {
    setState(() {
      _moviesFuture = movieService.fetchMovies();
    });
  }

  void _selectGenre(String? selected) {
    if (selected == null) {
      context.go('/movies');
    } else {
      context.go(
        Uri(path: '/movies', queryParameters: {'genre': selected}).toString(),
      );
    }
    setState(() {
      _selectedGenre = selected;
    });
    genrePreference.save(selected ?? '전체');
  }

  @override
  Widget build(BuildContext context) {
    final genres = movies.map((m) => m.genre).toSet().toList();

    return Scaffold(
      appBar: CommonAppBar(
        title: '영화',
        actions: [
          IconButton(
            tooltip: '장르로 찾기',
            icon: const Icon(Icons.search),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                useSafeArea: true,
                builder: (sheetContext) => const GenreFilterSheet(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: genres.length + 1,
              separatorBuilder: (context, index) {
                return const SizedBox(width: 8);
              },
              itemBuilder: (context, index) {
                final String? value = index == 0 ? null : genres[index - 1];
                return GenreChip(
                  label: value ?? '전체',
                  selected: value == _selectedGenre,
                  onSelected: () => _selectGenre(value),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const MovieListLoading();
                }

                if (snapshot.hasError) {
                  return MovieListError(onRetry: _retry);
                }

                final loadedMovies = snapshot.data ?? const <Movie>[];
                final filtered = _selectedGenre == null
                    ? loadedMovies
                    : loadedMovies
                          .where((m) => m.genre == _selectedGenre)
                          .toList();

                if (filtered.isEmpty) {
                  return const MovieListEmpty();
                }

                return MovieGrid(movies: filtered);
              },
            ),
          ),
        ],
      ),
    );
  }
}
