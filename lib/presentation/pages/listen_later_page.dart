import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/collection_provider.dart';
import '../../core/providers/content_provider.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/language_provider.dart';
import '../widgets/surah_item.dart';
import '../widgets/mini_player.dart';
import '../widgets/global_search.dart';

class ListenLaterPage extends ConsumerWidget {
  const ListenLaterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(collectionProvider);
    final content = ref.watch(contentProvider);
    final playerState = ref.watch(playerProvider);
    final notifier = ref.read(languageProvider.notifier);

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

    final listenLaterSurahs = collection.listenLater
        .map((id) => allSources.firstWhere((s) => s.id == id, orElse: () => Surah(id: id, name: "غير معروف", url: "", estimatedDuration: Duration.zero, isMakki: true)))
        .where((s) => s.url.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'الاستماع لاحقاً',
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
                  customHint: '${notifier.t('ابحث في', 'Search in', 'Pesquisar em', 'Chercher dans')} ${notifier.t('الاستماع لاحقاً', 'Listen Later', 'Ouvir Depois', 'Plus tard')}',
                  scope: listenLaterSurahs,
                ),
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      body: listenLaterSurahs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.watch_later_outlined, size: 64, color: AppColors.mutedDefault),
                  const SizedBox(height: 16),
                  Text(
                    notifier.t('قائمة الاستماع لاحقاً فارغة', 'Listen later list is empty', 'Lista de ouvir depois está vazia', 'La liste pour plus tard est vide'),
                    style: const TextStyle(color: AppColors.textSecondaryDefault),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: listenLaterSurahs.length,
                        itemBuilder: (context, index) {
                          final surah = listenLaterSurahs[index];
                          final isPlaying = playerState.currentSurah?.id == surah.id && playerState.isPlaying;
                          
                          return SurahItem(
                            key: ValueKey(surah.id),
                            surah: surah,
                            index: index,
                            isPlaying: isPlaying,
                            onTap: () => ref.read(playerProvider.notifier).playSurah(surah, listenLaterSurahs),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MiniPlayer(),
                ),
              ],
            ),
    );
  }
}
