import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/playlist_provider.dart';
import '../../core/providers/player_provider.dart';
import '../widgets/surah_item.dart';
import '../widgets/play_download_all_bar.dart';

import '../../core/providers/content_provider.dart';

class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);
    final contentState = ref.watch(contentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'قوائم التشغيل',
          style: GoogleFonts.amiri(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gold),
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildSectionHeader('قوائمي المحلية'),
          ),
          playlists.isEmpty
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.playlist_add, size: 64, color: AppColors.mutedDefault),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد قوائم حالياً',
                            style: TextStyle(color: AppColors.textSecondaryDefault),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final pl = playlists[index];
                      return ListTile(
                        onTap: () => _openPlaylist(context, ref, pl),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Text(
                          pl.name,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text(
                          '${pl.surahIds.length} سورة',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.destructive),
                          onPressed: () => ref.read(playlistProvider.notifier).deletePlaylist(pl.id),
                        ),
                        trailing: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.muted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.playlist_play, color: AppColors.gold),
                        ),
                      );
                    },
                    childCount: playlists.length,
                  ),
                ),

          if (contentState.remoteGithubList.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader('تلاوات خارجية (JSON Remote)'),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSourceItem(context, ref, contentState.remoteGithubList[index], contentState.remoteGithubList),
                childCount: contentState.remoteGithubList.length,
              ),
            ),
          ],

          if (contentState.githubList.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader('تلاوات جديدة (GitHub)'),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSourceItem(context, ref, contentState.githubList[index], contentState.githubList),
                childCount: contentState.githubList.length,
              ),
            ),
          ],

          if (contentState.youtubeRecitationsList.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader('تلاوات YouTube المميزة'),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSourceItem(context, ref, contentState.youtubeRecitationsList[index], contentState.youtubeRecitationsList),
                childCount: contentState.youtubeRecitationsList.length,
              ),
            ),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        textAlign: TextAlign.right,
        style: GoogleFonts.amiri(
          color: AppColors.gold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSourceItem(BuildContext context, WidgetRef ref, Surah surah, List<Surah> queue) {
    final playerState = ref.watch(playerProvider);
    final isPlaying = playerState.currentSurah?.id == surah.id && playerState.isPlaying;

    return ListTile(
      onTap: () => ref.read(playerProvider.notifier).playSurah(surah, queue),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        surah.name,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: isPlaying ? AppColors.gold : AppColors.textPrimary,
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      leading: isPlaying
        ? const Icon(Icons.volume_up, color: AppColors.gold)
        : Icon(Icons.play_circle_outline, color: AppColors.textSecondary),
      trailing: const Icon(Icons.cloud_download_outlined, color: AppColors.gold, size: 20),
    );
  }

  void _openPlaylist(BuildContext context, WidgetRef ref, Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Consumer(
          builder: (context, ref, child) {
            // Find the updated playlist from the provider
            final currentPlaylist = ref.watch(playlistProvider).firstWhere(
                  (p) => p.id == playlist.id,
                  orElse: () => playlist,
                );
            
            // Function to resolve a Surah ID from all possible sources
            Surah resolveSurah(String id) {
              // 1. Check local surahList (Quran)
              final quranMatch = surahList.where((s) => s.id == id).firstOrNull;
              if (quranMatch != null) return quranMatch;

              // 2. Check ContentProvider (GitHub, 2026, Azkar, Doae)
              final content = ref.read(contentProvider);
              final allSources = [
                ...content.telawat2026,
                ...content.telawat2018,
                ...content.telawat2020,
                ...content.telawat2022,
                ...content.telawat2023,
                ...content.telawat2024,
                ...content.telawat2025,
                ...content.telawat2026Local,
                ...content.azkar,
                ...content.doae
              ];
              final otherMatch = allSources.where((s) => s.id == id).firstOrNull;
              if (otherMatch != null) return otherMatch;

              // Fallback (Avoid crash)
              return Surah(id: id, name: "غير معروف", url: "", estimatedDuration: Duration.zero, isMakki: true);
            }

            // Map the IDs to Surah objects
            final surahs = currentPlaylist.surahIds
                .map((id) => resolveSurah(id))
                .toList();

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(currentPlaylist.name, style: GoogleFonts.amiri(color: AppColors.gold, fontWeight: FontWeight.bold)),
                centerTitle: true,
                actions: [
                  PlayDownloadAllBar(surahs: surahs, category: currentPlaylist.name),
                ],
              ),
              body: surahs.isEmpty
                  ? Center(child: Text('هذه القائمة فارغة', style: TextStyle(color: AppColors.textSecondary)))
                  : Column(
                      children: [
                        Expanded(
                          child: ReorderableListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: surahs.length,
                            onReorder: (oldIndex, newIndex) {
                              ref.read(playlistProvider.notifier).reorderSurah(currentPlaylist.id, oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final surah = surahs[index];
                              final playerState = ref.watch(playerProvider);
                              return Container(
                                key: ValueKey(surah.id),
                                child: SurahItem(
                                  key: ValueKey(surah.id),
                                  surah: surah,
                                  index: index,
                                  isPlaying: playerState.currentSurah?.id == surah.id && playerState.isPlaying,
                                  showDragHandle: true,
                                  onTap: () => ref.read(playerProvider.notifier).playSurah(surah, surahs),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('إنشاء قائمة جديدة', textAlign: TextAlign.right, style: GoogleFonts.amiri(color: AppColors.gold)),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'اسم القائمة',
            hintStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(playlistProvider.notifier).createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('إنشاء', style: TextStyle(color: AppColors.backgroundDefault)),
          ),
        ],
      ),
    );
  }
}
