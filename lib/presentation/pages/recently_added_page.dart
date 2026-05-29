import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/content_provider.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/language_provider.dart';
import '../widgets/surah_item.dart';
import '../widgets/global_search.dart';

class RecentlyAddedPage extends ConsumerWidget {
  const RecentlyAddedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    final notifier = ref.read(languageProvider.notifier);

    // Filter "New" content: prioritizing recent tracks
    final recentContent = [
      ...content.telawat2026,
      ...content.telawat2025,
      ...content.quranKareemRemote,
      ...content.remoteGithubList,
      ...content.azkar,
      ...content.doae,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.gold, size: 18),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.gold, Colors.white, AppColors.gold],
              ).createShader(bounds),
              child: Text(
                notifier.t('مُضافة حديثاً', 'Recently Added', 'Recém Adicionado', 'Récemment ajouté'),
                style: GoogleFonts.amiri(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  shadows: [
                    Shadow(
                      color: AppColors.gold.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.auto_awesome, color: AppColors.gold, size: 18),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.gold),
            onPressed: () {
              final recentlyAdded = [
                ...content.telawat2026,
                ...content.telawat2025,
                ...content.telawat2026Local
              ];
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(
                  ref: ref,
                  customHint: '${notifier.t('ابحث في', 'Search in', 'Pesquisar em', 'Chercher dans')} ${notifier.t('مُضافة حديثاً', 'Recently Added', 'Recém Adicionado', 'Récemment ajouté')}',
                  scope: recentlyAdded,
                ),
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      body: recentContent.isEmpty
          ? Center(
              child: Text(
                notifier.t('لا يوجد محتوى جديد حالياً', 'No new content yet', 'Sem conteúdo novo', 'Pas de nouveau contenu'),
                style: const TextStyle(color: AppColors.textSecondaryDefault),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: recentContent.length,
              itemBuilder: (context, index) {
                final surah = recentContent[index];
                return SurahItem(
                  key: ValueKey(surah.id),
                  surah: surah,
                  index: index,
                  isNew: true,
                  isPlaying: ref.watch(playerProvider).currentSurah?.id == surah.id,
                  onTap: () => ref.read(playerProvider.notifier).playSurah(surah, recentContent),
                );
              },
            ),
    );
  }
}
