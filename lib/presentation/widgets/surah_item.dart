import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import '../pages/statistics_page.dart';
import '../../core/models/surah.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/download_provider.dart';
import '../../core/providers/playlist_provider.dart' as playlist_mgr;
import '../../core/providers/language_provider.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/collection_provider.dart';
import '../../core/providers/content_provider.dart';
import '../../core/providers/playlist_state_provider.dart' as playlist_state;
import '../pages/downloads_page.dart';
import '../pages/all_surahs_page.dart';
import '../pages/smart_mushaf_page.dart';
import 'settings_sheet.dart';
import 'mushaf_settings_panel.dart';
import 'waveform_visualizer.dart';

import 'dart:ui';

class PulsingQuranIcon extends StatefulWidget {
  const PulsingQuranIcon({super.key});

  @override
  State<PulsingQuranIcon> createState() => _PulsingQuranIconState();
}

class _PulsingQuranIconState extends State<PulsingQuranIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: const Icon(Icons.menu_book, color: AppColors.gold, size: 16),
    );
  }
}

class SurahItem extends ConsumerWidget {
  final Surah surah;
  final int index;
  final bool isPlaying;
  final VoidCallback onTap;
  final Function(int)? onNavigateToTab;
  final bool showDragHandle;
  final bool isNew;

  const SurahItem({
    super.key,
    required this.surah,
    required this.index,
    this.isPlaying = false,
    required this.onTap,
    this.onNavigateToTab,
    this.showDragHandle = false,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadProvider);
    final collectionState = ref.watch(collectionProvider);
    final isFavorite = collectionState.favorites.contains(surah.id);
    final isListenLater = collectionState.listenLater.contains(surah.id);

    final lang = ref.watch(languageProvider);
    final downloadItem = downloadState.items[surah.id];
    final isDownloaded = downloadItem?.isCompleted ?? false;
    final downloadProgress = downloadItem?.progress ?? 0.0;
    final isPreparing = downloadItem?.isPreparing ?? false;
    final isDownloading = downloadItem != null && !isDownloaded;
    final isPaused = downloadItem?.isPaused ?? false;
    final notifier = ref.read(languageProvider.notifier);
    final isQuran = surahList.any((s) => s.id == surah.id);
    final sourcePage = _getSourcePage(ref);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isPlaying ? AppColors.gold.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isPlaying
                    ? AppColors.gold
                    : AppColors.muted.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () async {
                // تشغيل السورة أولاً
                onTap();
                
                // انتظار بسيط لبدء التشغيل
                await Future.delayed(const Duration(milliseconds: 300));
                
                // فتح المصحف الورقي الذكي مباشرة
                if (context.mounted) {
                  // حفظ قائمة التشغيل
                  ref.read(playlist_state.playlistProvider.notifier).setPlaylist(
                    _getSurahListFromContext(context, ref),
                    initialIndex: _getSurahIndexFromContext(context, ref, surah),
                  );
                  
                  // التنقل إلى صفحة المصحف
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SmartMushafPage(
                        surah: surah,
                        playlist: _getSurahListFromContext(context, ref),
                      ),
                    ),
                  );
                }
              },
              onLongPress: () => _showLongPressMenu(context, ref, isDownloaded,
                  sourcePage, downloadItem?.localPath),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDownloading)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isPaused
                                ? Icons.play_circle_outline
                                : Icons.pause_circle_outline,
                            color: AppColors.gold,
                            size: 24,
                          ),
                          onPressed: () {
                            if (isPaused) {
                              ref
                                  .read(downloadProvider.notifier)
                                  .resumeDownload(surah.id, surah.url ?? '');
                            } else {
                              ref
                                  .read(downloadProvider.notifier)
                                  .pauseDownload(surah.id);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value: isPreparing ? null : downloadProgress,
                            strokeWidth: 2,
                            color: isPaused ? AppColors.muted : AppColors.gold,
                          ),
                        ),
                      ],
                    )
                  else if (!isDownloaded)
                    IconButton(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.download_for_offline_outlined,
                          color: AppColors.gold, size: 24),
                      onPressed: () {
                        ref.read(downloadProvider.notifier).downloadSurah(
                            surah.id, surah.url,
                            surahName: surah.name,
                            category: sourcePage,
                            onComplete: (id) =>
                                _showCompleteNotify(context, ref, id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(notifier.t(
                                'بدء التحميل في الخلفية',
                                'Background download started',
                                'O download em segundo plano foi iniciado',
                                'Le téléchargement en arrière-plan a commencé')),
                            backgroundColor: AppColors.surface,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  if (!isDownloading) ...[
                    IconButton(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        ref
                                .watch(playlist_mgr.playlistProvider)
                                .any((p) => p.surahIds.contains(surah.id))
                            ? Icons.bookmark
                            : Icons.bookmark_add_outlined,
                        color: AppColors.gold,
                        size: 24,
                      ),
                      onPressed: () => _showPlaylistPicker(context, ref),
                    ),
                    IconButton(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.more_vert,
                          color: AppColors.gold, size: 24),
                      onPressed: () => _showSurahMenu(
                          context, ref, isDownloaded, sourcePage, downloadItem),
                    ),
                  ]
                ],
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isPlaying) ...[
                    const PulsingQuranIcon(),
                    const SizedBox(width: 8),
                  ],
                  if (isFavorite)
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(Icons.favorite,
                          color: Color(0xFFFFE57F), size: 14),
                    ),
                  if (isListenLater)
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(Icons.watch_later,
                          color: Color(0xFFFFE57F), size: 14),
                    ),
                  if (isQuran)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        surah.isMakki ? 'مكية' : 'مدنية',
                        style: const TextStyle(
                          color: Color(0xFFFFE57F), // Light Gold
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isNew)
                          Container(
                            margin: const EdgeInsets.only(top: 4, right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('جديد',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        Flexible(
                          child: Text(
                            notifier.translateSurahName(surah.name),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.amiri(
                              color: isPlaying
                                  ? AppColors.gold
                                  : AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: isPlaying
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (!showDragHandle)
                          Padding(
                            padding: const EdgeInsets.only(left: 6, top: 4),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (surah.lrcUrl != null && surah.lrcUrl!.isNotEmpty) ...[
                    const Text(
                      'مع الكلمات',
                      style: TextStyle(
                        color: Color(0xFFFFE57F),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('•',
                        style: TextStyle(color: AppColors.muted, fontSize: 10)),
                  ],
                  if (surah.category != null) ...[
                    GestureDetector(
                      onTap: () =>
                          _navigateToCategory(context, ref, surah.category!),
                      child: Text(
                        surah.category!,
                        style: const TextStyle(
                          color: Color(0xFFFFE57F), // Light Gold
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text('•',
                        style: TextStyle(color: AppColors.muted, fontSize: 10)),
                  ],
                  FutureBuilder<Duration?>(
                    future: ref
                        .read(contentProvider.notifier)
                        .fetchRealDuration(surah),
                    builder: (context, snapshot) {
                      final duration = snapshot.data ?? surah.actualDuration;
                      if (duration != null && duration.inSeconds > 0) {
                        return Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            color: Color(0xFFFFE57F), // Light Gold
                            fontSize: 11,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  if (isDownloading) ...[
                    Text('•',
                        style: TextStyle(color: AppColors.muted, fontSize: 10)),
                    Text(
                      isPaused
                          ? 'موقف'
                          : '${(downloadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Color(0xFFFFE57F), // Light Gold
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (isPlaying) ...[
                    Text('•',
                        style: TextStyle(color: AppColors.muted, fontSize: 10)),
                    Text(
                      notifier.t('جاري التشغيل الآن', 'Playing Now',
                          'Tocando Agora', 'En cours'),
                      style: const TextStyle(
                        color: Color(0xFFFFE57F), // Light Gold
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: showDragHandle
                  ? ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.drag_handle,
                            color: AppColors.gold, size: 28),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  void _showCompleteNotify(
      BuildContext context, WidgetRef ref, String surahId) {
    if (!context.mounted) return;
    final notifier = ref.read(languageProvider.notifier);
    final allSurahs = [...surahList];
    final surah =
        allSurahs.firstWhere((s) => s.id == surahId, orElse: () => this.surah);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon badge
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: const Icon(Icons.download_done_rounded,
                    color: AppColors.gold, size: 34),
              ),
              const SizedBox(height: 18),
              Text(
                '✓ اكتمل التحميل',
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                notifier.translateSurahName(surah.name),
                style: GoogleFonts.amiri(
                    color: Colors.white70, fontSize: 17),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Buttons row
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                      ),
                      child: Text(
                        'لاحقاً',
                        style: GoogleFonts.amiri(
                          color: Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref
                            .read(playerProvider.notifier)
                            .playSurah(surah, [surah]);
                        if (onNavigateToTab != null) onNavigateToTab!(3);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 4,
                        shadowColor: AppColors.gold.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'استمع الآن',
                        style: GoogleFonts.amiri(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSurahMenu(BuildContext context, WidgetRef ref, bool isDownloaded,
      String sourcePage, DownloadItem? downloadItem) {
    final notifier = ref.read(languageProvider.notifier);
    final collection = ref.watch(collectionProvider);
    final playerState = ref.watch(playerProvider);
    final isFav = ref.read(collectionProvider.notifier).isFavorite(surah.id);
    final isLater =
        ref.read(collectionProvider.notifier).isListenLater(surah.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A141F).withOpacity(0.95),
                  const Color(0xFF2D1B3D).withOpacity(0.9),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: AppColors.gold.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    notifier.translateSurahName(surah.name),
                    style: GoogleFonts.amiri(
                        fontSize: 20,
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.gold.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // New: Source Location
                  _buildGlassMenuItem(
                    icon: Icons.location_on_outlined,
                    title: "الذهاب إلى $sourcePage",
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToCategory(context, ref, sourcePage);
                    },
                  ),

                  if (isDownloaded && downloadItem?.localPath != null)
                    _buildGlassMenuItem(
                      icon: Icons.file_open_outlined,
                      title: "موقع الملف",
                      onTap: () {
                        Navigator.pop(context);
                        OpenFilex.open(downloadItem!.localPath);
                      },
                    ),

                  if (isDownloaded)
                    _buildGlassMenuItem(
                      icon: Icons.bar_chart,
                      title: "إحصائيات الاستماع",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const StatisticsPage()));
                      },
                    ),

                  if (isDownloaded)
                    _buildGlassMenuItem(
                      icon: Icons.download_done,
                      title: "الذهاب إلى التحميلات",
                      iconColor: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        if (onNavigateToTab != null) {
                          onNavigateToTab!(4);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DownloadsPage(
                                  onNavigate: (index) =>
                                      onNavigateToTab?.call(index)),
                            ),
                          );
                        }
                      },
                    ),

                  // My Selected Verses
                  _buildGlassMenuItem(
                    icon: Icons.cut,
                    title: "آياتي المختارة",
                    subtitle: "قص ومزامنة الآيات",
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to My Selected Verses page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('قسم آياتي المختارة قيد التطوير'),
                          backgroundColor: AppColors.gold,
                        ),
                      );
                    },
                  ),

                  // My Downloads
                  _buildGlassMenuItem(
                    icon: Icons.folder,
                    title: "تحميلاتي",
                    subtitle: "عرض جميع السور المحملة",
                    onTap: () {
                      Navigator.pop(context);
                      if (onNavigateToTab != null) {
                        onNavigateToTab!(4);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DownloadsPage(
                                onNavigate: (index) =>
                                    onNavigateToTab?.call(index)),
                          ),
                        );
                      }
                    },
                  ),

                  _buildGlassMenuItem(
                    icon: isFav ? Icons.favorite : Icons.favorite_border,
                    title: isFav ? "إزالة من المفضلة" : "إضافة إلى المفضلة",
                    onTap: () {
                      ref
                          .read(collectionProvider.notifier)
                          .toggleFavorite(surah.id);
                      Navigator.pop(context);
                    },
                  ),

                  _buildGlassMenuItem(
                    icon: isLater ? Icons.watch_later : Icons.watch_later_outlined,
                    title: isLater ? "إزالة من الاستماع لاحقاً" : "الاستماع لاحقاً",
                    onTap: () {
                      ref
                          .read(collectionProvider.notifier)
                          .toggleListenLater(surah.id);
                      Navigator.pop(context);
                    },
                  ),

                  _buildGlassMenuItem(
                    icon: Icons.playlist_play,
                    title: "تشغيل التالي",
                    onTap: () {
                      ref.read(playerProvider.notifier).playNextAt(surah);
                      Navigator.pop(context);
                    },
                  ),

                  _buildGlassMenuItem(
                    icon: Icons.playlist_add,
                    title: notifier.t('إضافة إلى قائمة التشغيل', 'Add to Playlist',
                        'Adicionar à Playlist', 'Ajouter à la playlist'),
                    onTap: () {
                      Navigator.pop(context);
                      _showPlaylistPicker(context, ref);
                    },
                  ),
                  if (isDownloaded)
                    _buildGlassMenuItem(
                      icon: Icons.delete_outline,
                      title: notifier.t('حذف السورة', 'Delete Surah', 'Excluir Surah',
                          'Supprimer la sourate'),
                      iconColor: AppColors.destructive,
                      onTap: () {
                        ref
                            .read(downloadProvider.notifier)
                            .deleteDownloadedSurah(surah.id);
                        Navigator.pop(context);
                      },
                    )
                  else
                    _buildGlassMenuItem(
                      icon: Icons.download,
                      title: notifier.t('تحميل السورة', 'Download Surah',
                          'Baixar Surah', 'Télécharger la sourate'),
                      onTap: () {
                        ref.read(downloadProvider.notifier).downloadSurah(
                            surah.id, surah.url,
                            surahName: surah.name,
                            category: sourcePage,
                            onComplete: (id) =>
                                _showCompleteNotify(context, ref, id));
                        Navigator.pop(context);
                      },
                    ),
                  _buildGlassMenuItem(
                    icon: Icons.settings,
                    title: notifier.t(
                        'الإعدادات', 'Settings', 'Configurações', 'Paramètres'),
                    onTap: () {
                      Navigator.pop(context);
                      showSettingsBottomSheet(context, ref);
                    },
                  ),
                  
                  // Mushaf Settings
                  _buildGlassMenuItem(
                    icon: Icons.auto_stories,
                    title: 'إعدادات المصحف',
                    subtitle: 'Mushaf Settings',
                    onTap: () {
                      Navigator.pop(context);
                      showMushafSettingsPanel(context, ref);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.gold),
      title: Text(title, textAlign: TextAlign.right),
      subtitle: subtitle != null ? Text(subtitle, textAlign: TextAlign.right) : null,
      onTap: onTap,
    );
  }

  void _showLongPressMenu(BuildContext context, WidgetRef ref,
      bool isDownloaded, String sourcePage, String? localPath) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.transparent,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    surah.name,
                    style: GoogleFonts.amiri(
                        fontSize: 22,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Play
                  ListTile(
                    leading: const Icon(Icons.play_circle_fill,
                        color: AppColors.gold, size: 30),
                    title: Text("تشغيل السورة",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 18)),
                    onTap: () {
                      Navigator.pop(context);
                      onTap();
                    },
                  ),

                  // Redownload
                  if (isDownloaded)
                    ListTile(
                      leading: const Icon(Icons.refresh,
                          color: Colors.blueAccent, size: 28),
                      title: Text("إعادة التحميل",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 18)),
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(downloadProvider.notifier).restartDownload(
                            surah.id, surah.url,
                            surahName: surah.name, category: sourcePage);
                      },
                    ),

                  // Delete
                  if (isDownloaded)
                    ListTile(
                      leading: Icon(Icons.delete,
                          color: Colors.red.withOpacity(0.7), size: 28),
                      title: Text("حذف الملف",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: Colors.red.withOpacity(0.7),
                              fontSize: 18)),
                      onTap: () {
                        Navigator.pop(context);
                        ref
                            .read(downloadProvider.notifier)
                            .deleteDownloadedSurah(surah.id);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPlaylistPicker(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlist_mgr.playlistProvider);
    final notifier = ref.read(languageProvider.notifier);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                notifier.t('اختر قائمة التشغيل', 'Select Playlist',
                    'Selecionar Playlist', 'Sélectionner la playlist'),
                style: GoogleFonts.amiri(fontSize: 18, color: AppColors.gold)),
            const SizedBox(height: 16),
            if (playlists.isEmpty)
              Text(
                  notifier.t('لا توجد قوائم تشغيل حالياً', 'No playlists yet',
                      'Sem playlists ainda', 'Pas encore de playlists'),
                  style: const TextStyle(color: AppColors.textSecondaryDefault))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final pl = playlists[index];
                    return ListTile(
                      title: Text(pl.name,
                          textAlign: TextAlign.right,
                          style: TextStyle(color: AppColors.textPrimary)),
                      onTap: () {
                        ref
                            .read(playlist_mgr.playlistProvider.notifier)
                            .addToPlaylist(pl.id, surah.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(notifier.t('تمت الإضافة', 'Added',
                                  'Adicionado', 'Ajouté'))),
                        );
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: AppColors.backgroundDefault),
              label: Text(notifier.t('إنشاء قائمة جديدة', 'Create New Playlist',
                  'Criar Nova Playlist', 'Créer une nouvelle playlist')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.backgroundDefault,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _showCreatePlaylistDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(languageProvider.notifier);
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
            notifier.t('إنشاء قائمة جديدة', 'Create New Playlist',
                'Criar Nova Playlist', 'Créer une nouvelle playlist'),
            style: const TextStyle(color: AppColors.gold)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: notifier.t('اسم القائمة', 'Playlist Name',
                'Nome da Playlist', 'Nom de la playlist'),
            hintStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.muted)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.gold)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(notifier.t('إلغاء', 'Cancel', 'Cancelar', 'Annuler'),
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.backgroundDefault),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(playlist_mgr.playlistProvider.notifier).createPlaylist(name);
                // Get the new playlist and add this surah to it
                Future.delayed(const Duration(milliseconds: 100), () {
                  final playlists = ref.read(playlist_mgr.playlistProvider);
                  if (playlists.isNotEmpty) {
                    ref
                        .read(playlist_mgr.playlistProvider.notifier)
                        .addToPlaylist(playlists.last.id, surah.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(notifier.t(
                              'تمت الإضافة', 'Added', 'Adicionado', 'Ajouté'))),
                    );
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(notifier.t('إنشاء', 'Create', 'Criar', 'Créer')),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) return "${d.inHours}:$minutes:$seconds";
    return "$minutes:$seconds";
  }

  void _navigateToCategory(
      BuildContext context, WidgetRef ref, String category) {
    final content = ref.read(contentProvider);
    List<Surah>? targetList;
    String title = category;

    if (category.contains('2018')) {
      targetList = content.telawat2018;
    } else if (category.contains('2019'))
      targetList = content.telawat2019;
    else if (category.contains('2020'))
      targetList = content.telawat2020;
    else if (category.contains('2022'))
      targetList = content.telawat2022;
    else if (category.contains('2023'))
      targetList = content.telawat2023;
    else if (category.contains('2024'))
      targetList = content.telawat2024;
    else if (category.contains('2025'))
      targetList = content.telawat2025;
    else if (category.contains('2026'))
      targetList = content.telawat2026;
    else if (category == 'الأذكار')
      targetList = content.azkar;
    else if (category == 'الأدعية')
      targetList = content.doae;
    else if (category == 'القرآن الكريم') targetList = surahList;

    if (targetList != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AllSurahsPage(title: title, allSurahs: targetList!),
        ),
      );
    }
  }

  String _getSourcePage(WidgetRef ref) {
    final content = ref.read(contentProvider);
    if (content.telawat2026.any((s) => s.id == surah.id)) return "تلاوات 2026";
    if (content.telawat2025.any((s) => s.id == surah.id)) return "تلاوات 2025";
    if (content.telawat2024.any((s) => s.id == surah.id)) return "تلاوات 2024";
    if (content.telawat2023.any((s) => s.id == surah.id)) return "تلاوات 2023";
    if (content.telawat2022.any((s) => s.id == surah.id)) return "تلاوات 2022";
    if (content.telawat2020.any((s) => s.id == surah.id)) return "تلاوات 2020";
    if (content.telawat2018.any((s) => s.id == surah.id)) return "تلاوات 2018";
    if (content.anashid2024.any((s) => s.id == surah.id)) return "أناشيد 2024";
    if (content.anashid2023.any((s) => s.id == surah.id)) return "أناشيد 2023";
    if (content.anashid2022.any((s) => s.id == surah.id)) return "أناشيد 2022";
    if (content.anashid2020.any((s) => s.id == surah.id)) return "أناشيد 2020";
    if (content.anashid2019.any((s) => s.id == surah.id)) return "أناشيد 2019";
    if (content.anashid2018.any((s) => s.id == surah.id)) return "أناشيد 2018";
    if (content.azkar.any((s) => s.id == surah.id)) return "الأذكار";
    if (content.doae.any((s) => s.id == surah.id)) return "الأدعية";
    if (surahList.any((s) => s.id == surah.id)) return "القرآن الكريم";
    return "تلاوات متنوعة";
  }
}

class PulsingDot extends StatelessWidget {
  const PulsingDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class MiniWaveform extends ConsumerWidget {
  final bool? isPlaying;
  const MiniWaveform({super.key, this.isPlaying});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final playing = isPlaying ?? playerState.isPlaying;
    
    return WaveformVisualizer(
      isPlaying: playing,
      height: 16,
    );
  }
}

// Helper functions to extract playlist from context
List<Surah> _getSurahListFromContext(BuildContext context, WidgetRef ref) {
  // Try to get the playlist from the player provider's queue
  final playerNotifier = ref.read(playerProvider.notifier);
  try {
    // Access the current queue if available
    return playerNotifier.currentQueue;
  } catch (e) {
    // Fallback: return empty list
    return [];
  }
}

int _getSurahIndexFromContext(BuildContext context, WidgetRef ref, Surah surah) {
  final playerNotifier = ref.read(playerProvider.notifier);
  try {
    final queue = playerNotifier.currentQueue;
    final index = queue.indexWhere((s) => s.id == surah.id);
    return index >= 0 ? index : 0;
  } catch (e) {
    return 0;
  }
}
