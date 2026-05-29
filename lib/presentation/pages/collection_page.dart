import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/player_provider.dart';
import '../widgets/surah_item.dart';
import '../widgets/mini_player.dart';
import '../widgets/play_download_all_bar.dart';

class CollectionPage extends ConsumerWidget {
  final String title;
  final List<Surah> surahs;

  const CollectionPage({
    super.key,
    required this.title,
    required this.surahs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: Text(
          title,
          style: GoogleFonts.amiri(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          PlayDownloadAllBar(surahs: surahs, category: title),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 150),
                  itemCount: surahs.length,
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    final isPlaying = playerState.currentSurah?.id == surah.id && playerState.isPlaying;
                    
                    return SurahItem(
                      key: ValueKey(surah.id),
                      surah: surah,
                      index: index,
                      isPlaying: isPlaying,
                      onTap: () => ref.read(playerProvider.notifier).playSurah(surah, surahs),
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
