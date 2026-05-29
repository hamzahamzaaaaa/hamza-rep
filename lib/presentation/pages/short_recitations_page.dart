import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/content_provider.dart';
import '../widgets/surah_item.dart';
import '../widgets/mini_player.dart';

class ShortRecitationsNotifier extends StateNotifier<List<Surah>> {
  final Ref _ref;
  ShortRecitationsNotifier(this._ref) : super([]) {
    shuffle();
  }

  void shuffle() {
    final content = _ref.read(contentProvider);
    final allTracks = [
      ...surahList,
      ...content.telawat2026,
      ...content.telawat2018,
      ...content.telawat2019,
      ...content.telawat2020,
      ...content.telawat2022,
      ...content.telawat2023,
      ...content.telawat2024,
      ...content.telawat2025,
      ...content.telawat2026Local,
      ...content.githubList,
      ...content.youtubeRecitationsList,
      ...content.remoteGithubList,
      ...content.quranKareemRemote,
    ];

    final poeticNames = [
      'تلاوة هادئة تريح القلب', 'مقطع خاشع لتهدئة النفس', 'تلاوة مريحة للنوم', 'سكينة وطمأنينة', 'تلاوة باكية',
      'راحة نفسية', 'تلاوة شجية', 'خشوع واطمئنان'
    ];
    
    final emojis = ['❤️', '🌙', '🌲', '✨', '🕊️', '💎', '🌟', '🌧️', '🕌', '📜', '🕯️', '🌿', '🌈', '🤍', '🌑', '🌸', '🌊'];
    final random = math.Random();

    final list = List<Surah>.from(allTracks)..shuffle();
    state = list.take(15).map<Surah>((s) {
      final pName = poeticNames[random.nextInt(poeticNames.length)];
      final emoji = emojis[random.nextInt(emojis.length)];
      return s.copyWith(name: '$pName $emoji (${s.name})');
    }).toList();
  }
}

final shortRecitationsProvider = StateNotifierProvider.autoDispose<ShortRecitationsNotifier, List<Surah>>((ref) {
  return ShortRecitationsNotifier(ref);
});

class ShortRecitationsPage extends ConsumerWidget {
  const ShortRecitationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(languageProvider.notifier);
    final playerNotifier = ref.read(playerProvider.notifier);
    final playerState = ref.watch(playerProvider);
    final shuffledTracks = ref.watch(shortRecitationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          notifier.t('تلاوات قصيرة', 'Short Recitations', 'Recitações Curtas', 'Récitations Courtes'),
          style: GoogleFonts.amiri(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.only(bottom: 150),
            itemCount: shuffledTracks.length,
            itemBuilder: (context, index) {
              final displaySurah = shuffledTracks[index];
              final isCurrent = playerState.currentSurah?.id == displaySurah.id;

              return SurahItem(
                key: ValueKey('short_${displaySurah.id}_$index'),
                surah: displaySurah,
                index: index,
                isPlaying: isCurrent && playerState.isPlaying,
                onTap: () {
                  playerNotifier.playSurah(displaySurah, shuffledTracks);
                },
              );
            },
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}
