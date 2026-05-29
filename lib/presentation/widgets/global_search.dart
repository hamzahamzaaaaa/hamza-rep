import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/content_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/player_provider.dart';
import 'surah_item.dart';

class GlobalSearchDelegate extends SearchDelegate<Surah?> {
  final WidgetRef ref;
  final Function(int)? onNavigate;
  final String? customHint;
  final List<Surah>? scope;

  GlobalSearchDelegate({
    required this.ref,
    this.onNavigate,
    this.customHint,
    this.scope,
  });

  @override
  String get searchFieldLabel => customHint ?? ref.read(languageProvider.notifier).t(
    'بحث عن سورة، تلاوة، أو ذكر...',
    'Search for Surah, Recitation, or Azkar...',
    'Pesquisar por Surah, Recitação ou Azkar...',
    'Rechercher une Sourate, Récitation ou Azkar...'
  );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF08060A), // Inlined AppColors.background to avoid non-const error
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  List<Surah> _getAllTracks() {
    final content = ref.read(contentProvider);
    return [
      ...surahList,
      ...content.telawat2026,
      ...content.telawat2018,
      ...content.telawat2020,
      ...content.telawat2022,
      ...content.telawat2023,
      ...content.telawat2024,
      ...content.telawat2025,
      ...content.telawat2026Local,
      ...content.azkar,
      ...content.doae,
    ];
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: AppColors.gold),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final allTracks = scope ?? _getAllTracks();
    final results = allTracks.where((s) {
      final name = s.name.toLowerCase();
      final search = query.toLowerCase();
      return name.contains(search);
    }).toList();

    if (results.isEmpty) {
      return Container(
        color: AppColors.background,
        child: Center(
          child: Text(
            ref.read(languageProvider.notifier).t(
              'لا توجد نتائج',
              'No results found',
              'Nenhum resultado encontrado',
              'Aucun résultat trouvé'
            ),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final surah = results[index];
          final playerState = ref.watch(playerProvider);
          final isCurrent = playerState.currentSurah?.id == surah.id;

          return SurahItem(
            key: ValueKey(surah.id),
            surah: surah,
            index: index,
            isPlaying: isCurrent && playerState.isPlaying,
            onNavigateToTab: onNavigate ?? (idx) {},
            onTap: () {
              ref.read(playerProvider.notifier).playSurah(surah, results);
              close(context, surah);
            },
          );
        },
      ),
    );
  }
}
