import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/collection_provider.dart';
import '../../core/providers/content_provider.dart';
import '../../core/providers/player_provider.dart';
import '../widgets/surah_item.dart';
import '../widgets/play_download_all_bar.dart';
import '../widgets/global_search.dart';
import '../../core/providers/language_provider.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(collectionProvider);
    final content = ref.watch(contentProvider);

    final allSources = [
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
      ...content.remoteGithubList,
      ...content.quranKareemRemote,
      ...content.githubList,
      ...content.youtubeRecitationsList,
    ];

    final favoriteSurahs = collection.favorites
        .map((id) => allSources.firstWhere((s) => s.id == id, orElse: () => Surah(id: id, name: "غير معروف", url: "", estimatedDuration: Duration.zero, isMakki: true)))
        .where((s) => s.url.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'المفضلة',
          style: GoogleFonts.amiri(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.gold),
            onPressed: () {
              final notifier = ref.read(languageProvider.notifier);
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(
                  ref: ref,
                  customHint: '${notifier.t('ابحث في', 'Search in', 'Pesquisar em', 'Chercher dans')} ${notifier.t('المفضلة', 'Favorites', 'Favoritos', 'Favoris')}',
                  scope: favoriteSurahs,
                ),
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      body: favoriteSurahs.isEmpty
          ? const Center(child: Text('لا توجد مفضلات حالياً', style: TextStyle(color: AppColors.textSecondaryDefault)))
          : Column(
              children: [
                PlayDownloadAllBar(surahs: favoriteSurahs, category: "المفضلة"),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: favoriteSurahs.length,
                    itemBuilder: (context, index) {
                      final surah = favoriteSurahs[index];
                      return SurahItem(
                        key: ValueKey(surah.id),
                        surah: surah,
                        index: index,
                        isPlaying: ref.watch(playerProvider).currentSurah?.id == surah.id,
                        onTap: () => ref.read(playerProvider.notifier).playSurah(surah, favoriteSurahs),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
