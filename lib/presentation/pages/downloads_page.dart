import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/download_provider.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/content_provider.dart';
import '../../core/providers/playlist_provider.dart';
import '../widgets/surah_item.dart';
import '../widgets/global_search.dart';

class DownloadsPage extends ConsumerWidget {
  final Function(int) onNavigate;
  const DownloadsPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the stream provider for real-time progress, but fallback to the static state
    final downloadProgressAsync = ref.watch(downloadProgressStreamProvider);
    final staticDownloads = ref.watch(downloadProvider);
    final downloads = downloadProgressAsync.value ?? staticDownloads;
    
    final groupedSurahs = ref.watch(groupedDownloadsProvider);

    final content = ref.watch(contentProvider);
    final notifier = ref.read(languageProvider.notifier);

    // List of all items for "Resume All" logic
    final List<Surah> allPossibleSurahs = [
      ...surahList,
      ...content.telawat2026,
      ...content.telawat2025,
      ...content.telawat2024,
      ...content.telawat2023,
      ...content.telawat2022,
      ...content.telawat2020,
      ...content.telawat2018,
      ...content.azkar,
      ...content.doae,
    ];

    final allDownloadedSurahs = groupedSurahs.values.expand((list) => list).toList();
    final activeDownload = ref.watch(downloadProvider.notifier).activeDownload;
    final isDownloading = downloads.currentSpeed > 0 || activeDownload != null;

    final hasCompleted = allDownloadedSurahs.any((s) => downloads.items[s.id]?.isCompleted == true);
    final hasItems = downloads.items.isNotEmpty;
    final showGroupControls = isDownloading || hasItems;

    return Scaffold(
      backgroundColor: Colors.black, // Pure black for eye comfort
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          notifier.t('تحميلاتي', 'My Downloads', 'Meus Downloads', 'Mes Téléchargements'),
          style: GoogleFonts.amiri(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // 1. Static Icons (Anchored to the left edge in RTL)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.gold),
            color: AppColors.surface,
            onSelected: (value) async {
              if (value == 'storage') {
                _showSpaceManager(context, ref, allDownloadedSurahs.where((s) => downloads.items[s.id]!.isCompleted).toList());
              } else if (value == 'battery') {
                ref.read(downloadProvider.notifier).requestUnrestrictedBattery();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'storage',
                child: Row(
                  children: [
                    const Icon(Icons.storage, color: AppColors.gold, size: 20),
                    const SizedBox(width: 12),
                    Text(notifier.t('إدارة المساحة', 'Manage Storage', 'Gerenciar Espaço', 'Gérer l\'espace'), 
                         style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'battery',
                child: Row(
                  children: [
                    const Icon(Icons.battery_saver, color: AppColors.gold, size: 20),
                    const SizedBox(width: 12),
                    Text(notifier.t('ضبط البطارية', 'Battery Settings', 'Ajustar Bateria', 'Réglage batterie'),
                         style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.gold),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(
                  ref: ref,
                  customHint: '${notifier.t('ابحث في', 'Search in', 'Pesquisar em', 'Chercher dans')} ${notifier.t('تحميلاتي', 'Downloads', 'Downloads', 'Téléchargements')}',
                  scope: allDownloadedSurahs,
                ),
              );
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.gold),
            onPressed: () => ref.read(downloadProvider.notifier).refresh(),
          ),

          // 2. Conditional Icons (These appear to the right of static icons, closer to the title)
          if (showGroupControls) ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppColors.destructive),
              tooltip: notifier.t('حذف الكل', 'Delete All', 'Excluir Tudo', 'Tout supprimer'),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: Text(notifier.t('تأكيد الحذف', 'Confirm Delete', 'Confirmar Exclusão', 'Confirmer la suppression'),
                      style: const TextStyle(color: AppColors.gold)),
                    content: Text(notifier.t('هل أنت متأكد من حذف جميع التحميلات؟', 'Are you sure you want to delete all downloads?', 'Tem certeza de que deseja excluir todos os downloads?', 'Êtes-vous sûr de vouloir supprimer tous les téléchargements ?'),
                      style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(notifier.t('إلغاء', 'Cancel', 'Cancelar', 'Annuler'), style: const TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(notifier.t('حذف', 'Delete', 'Excluir', 'Supprimer'), style: const TextStyle(color: AppColors.destructive)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await ref.read(downloadProvider.notifier).clearAllDownloads();
                }
              },
            ),
            IconButton(
              icon: Icon(downloads.isPausedAll ? Icons.play_circle_filled : Icons.pause_circle_filled, 
                   color: downloads.isPausedAll ? AppColors.gold : AppColors.destructive),
              onPressed: () {
                if (downloads.isPausedAll) {
                  ref.read(downloadProvider.notifier).resumeAllDownloads(allPossibleSurahs);
                } else {
                  ref.read(downloadProvider.notifier).pauseAllDownloads();
                }
              },
            ),
          ],
          
          if (hasCompleted)
            IconButton(
              icon: const Icon(Icons.play_circle_filled, color: AppColors.gold),
              onPressed: () {
                final completed = allDownloadedSurahs.where((s) => downloads.items[s.id]?.isCompleted == true).toList();
                if (completed.isNotEmpty) {
                  ref.read(playerProvider.notifier).playSurah(completed.first, completed);
                  ref.read(playerProvider.notifier).toggleLyricsZoom(true);
                  onNavigate(3);
                }
              },
            ),
        ],
      ),
      body: allDownloadedSurahs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.download_for_offline, size: 64, color: AppColors.mutedDefault),
                  const SizedBox(height: 16),
                  Text(
                    notifier.t('لا توجد تحميلات حالياً', 'No downloads yet', 'Sem downloads ainda', 'Pas encore de téléchargements'),
                    style: const TextStyle(color: AppColors.textSecondaryDefault),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Statistics Banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.speed, color: AppColors.gold, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            downloads.currentSpeed > 1024 ? '${(downloads.currentSpeed / 1024).toStringAsFixed(2)} MB/s' : '${downloads.currentSpeed.toStringAsFixed(1)} KB/s',
                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            '${allDownloadedSurahs.where((s) => downloads.items[s.id]?.isCompleted == true).length} ${notifier.t('مكتمل', 'Done', 'Concluído', 'Terminé')}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.pending, color: Colors.orange, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            downloads.globalEta.isNotEmpty
                                ? downloads.globalEta
                                : '${downloads.remainingInQueue} ${notifier.t('متبقي', 'Left', 'Restante', 'Restant')}',
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: groupedSurahs.length,
                    itemBuilder: (context, index) {
                      final category = groupedSurahs.keys.elementAt(index);
                      final categorySurahs = groupedSurahs[category]!;

                      final downloadingCount = categorySurahs.where((s) => downloads.items[s.id]?.isCompleted == false).length;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.1)),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: index == 0,
                            iconColor: AppColors.gold,
                            collapsedIconColor: AppColors.gold,
                            trailing: const Icon(Icons.folder_outlined, color: AppColors.gold),
                            title: Text(
                              (category == 'General' || category == 'تلاوات متنوعة') ? notifier.t('تلاوات متنوعة', 'Miscellaneous', 'Geral', 'Divers') : category,
                              textAlign: TextAlign.right,
                              style: const TextStyle(color: AppColors.textPrimaryDefault, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (downloadingCount > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${notifier.t('متبقي', 'Remaining', 'Restante', 'Restant')}: $downloadingCount',
                                      style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  '${categorySurahs.length} ${notifier.t('عنصر', 'items', 'itens', 'éléments')}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(color: AppColors.textSecondaryDefault, fontSize: 12),
                                ),
                              ],
                            ),
                            children: [
                              // Play all folder button
                              if (categorySurahs.any((s) => downloads.items[s.id]?.isCompleted == true))
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.play_arrow, color: AppColors.backgroundDefault, size: 20),
                                    label: Text(
                                      notifier.t('تشغيل القائمة', 'Play List', 'Tocar Lista', 'Jouer la liste'),
                                      style: const TextStyle(color: AppColors.backgroundDefault, fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gold.withValues(alpha: 0.8),
                                      minimumSize: const Size(double.infinity, 40),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      final completed = categorySurahs.where((s) => downloads.items[s.id]?.isCompleted == true).toList();
                                      if (completed.isNotEmpty) {
                                        ref.read(playerProvider.notifier).playSurah(completed.first, completed);
                                      }
                                    },
                                  ),
                                ),
                              ...categorySurahs.map((surah) {
                                final isCompleted = ref.watch(downloadProvider.select((s) => s.items[surah.id]?.isCompleted == true));
                                
                                if (isCompleted) {
                                  return SurahItem(
                                    key: ValueKey(surah.id),
                                    surah: surah,
                                    index: categorySurahs.indexOf(surah),
                                    isPlaying: ref.watch(playerProvider).currentSurah?.id == surah.id,
                                    onTap: () {
                                      final completed = categorySurahs.where((s) => ref.read(downloadProvider).items[s.id]?.isCompleted == true).toList();
                                      ref.read(playerProvider.notifier).playSurah(surah, completed);
                                      ref.read(playerProvider.notifier).toggleLyricsZoom(true);
                                      onNavigate(3);
                                    },
                                  );
                                }

                                // High-performance downloading view with .select
                                return _DownloadingItem(surah: surah);
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showSpaceManager(BuildContext context, WidgetRef ref, List<Surah> surahs) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SpaceManager(surahs: surahs),
    );
  }

  void _showDownloadOptions(BuildContext context, WidgetRef ref, Surah surah, DownloadItem item) {
    final notifier = ref.read(languageProvider.notifier);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notifier.translateSurahName(surah.name),
              style: GoogleFonts.amiri(fontSize: 20, color: AppColors.gold, fontWeight: FontWeight.bold),
            ),
            const Divider(color: AppColors.gold, indent: 50, endIndent: 50),
            if (!item.isCompleted) ...[
              ListTile(
                leading: Icon(item.isPaused ? Icons.play_arrow : Icons.pause, color: AppColors.gold),
                title: Text(item.isPaused ? notifier.t('استئناف', 'Resume', 'Retomar', 'Reprendre') : notifier.t('توقف مؤقت', 'Pause', 'Pausa', 'Pause'), textAlign: TextAlign.right),
                onTap: () {
                  Navigator.pop(context);
                  if (item.isPaused) {
                    ref.read(downloadProvider.notifier).resumeDownload(surah.id, surah.url);
                  } else {
                    ref.read(downloadProvider.notifier).pauseDownload(surah.id);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: AppColors.gold),
                title: Text(notifier.t('إلغاء', 'Cancel', 'Cancelar', 'Annuler'), textAlign: TextAlign.right),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(downloadProvider.notifier).cancelDownload(surah.id);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.gold),
              title: Text(notifier.t('إعادة التحميل', 'Restart', 'Reiniciar', 'Redémarrer'), textAlign: TextAlign.right),
              onTap: () {
                Navigator.pop(context);
                ref.read(downloadProvider.notifier).restartDownload(surah.id, surah.url, surahName: surah.name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.destructive),
              title: Text(notifier.t('حذف', 'Delete', 'Excluir', 'Supprimer'), textAlign: TextAlign.right, style: const TextStyle(color: AppColors.destructive)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: Text(notifier.t('تأكيد الحذف', 'Confirm Delete', 'Confirmar', 'Confirmer')),
                    content: Text(notifier.t('هل تريد حذف الملف؟', 'Delete file?', 'Excluir?', 'Supprimer?')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text(notifier.t('إلغاء', 'Cancel', 'Cancelar', 'Annuler'))),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text(notifier.t('حذف', 'Delete', 'Excluir', 'Supprimer'), style: const TextStyle(color: AppColors.destructive))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  ref.read(downloadProvider.notifier).deleteDownloadedSurah(surah.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SpaceManager extends ConsumerWidget {
  final List<Surah> surahs;
  const SpaceManager({super.key, required this.surahs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(languageProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            notifier.t('مدير المساحة', 'Space Manager', 'Gerente de Espaço', 'Gestionnaire d\'espace'),
            style: GoogleFonts.amiri(fontSize: 22, color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(notifier.t('الملفات', 'Files', 'Arquivos', 'Fichiers'), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('${surahs.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gold)),
                  ],
                ),
                Container(width: 1, height: 30, color: AppColors.gold.withValues(alpha: 0.3)),
                Column(
                  children: [
                    Text(notifier.t('الحالة', 'Status', 'Status', 'Statut'), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(notifier.t('نشط', 'Active', 'Ativo', 'Actif'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (surahs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_sweep, color: AppColors.backgroundDefault),
                label: Text(
                  notifier.t('حذف الكل', 'Delete All', 'Excluir Tudo', 'Tout supprimer'),
                  style: const TextStyle(color: AppColors.backgroundDefault, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.destructive,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: Text(notifier.t('تأكيد الحذف', 'Confirm Delete', 'Confirmar Exclusão', 'Confirmer la suppression')),
                      content: Text(notifier.t('هل أنت متأكد من حذف جميع التحميلات؟', 'Are you sure you want to delete all downloads?', 'Tem certeza de que deseja excluir todos os downloads?', 'Êtes-vous sûr de vouloir supprimer tous les téléchargements ?')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(notifier.t('إلغاء', 'Cancel', 'Cancelar', 'Annuler'), style: const TextStyle(color: Colors.white)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(notifier.t('حذف', 'Delete', 'Excluir', 'Supprimer'), style: const TextStyle(color: AppColors.destructive)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref.read(downloadProvider.notifier).clearAllDownloads();
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: surahs.length,
              itemBuilder: (context, index) {
                final surah = surahs[index];
                return ListTile(
                  title: Text(notifier.translateSurahName(surah.name), textAlign: TextAlign.right),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.destructive),
                    onPressed: () {
                      ref.read(downloadProvider.notifier).deleteDownloadedSurah(surah.id);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadingItem extends ConsumerWidget {
  final Surah surah;
  const _DownloadingItem({required this.surah});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(languageProvider.notifier);
    
    // Efficiently watch only the properties needed for this specific item
    final progress = ref.watch(downloadProvider.select((s) => s.items[surah.id]?.progress ?? 0.0));
    final isPaused = ref.watch(downloadProvider.select((s) => s.items[surah.id]?.isPaused ?? false));
    final currentSpeed = ref.watch(downloadProvider.select((s) => s.currentSpeed));
    final item = ref.watch(downloadProvider.select((s) => s.items[surah.id]));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline,
                      color: AppColors.gold,
                      size: 24,
                    ),
                    onPressed: () {
                      if (isPaused) {
                        ref.read(downloadProvider.notifier).resumeDownload(surah.id, surah.url);
                      } else {
                        ref.read(downloadProvider.notifier).pauseDownload(surah.id);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2,
                      color: isPaused ? AppColors.muted : AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      ref.watch(playlistProvider).any((p) => p.surahIds.contains(surah.id))
                          ? Icons.bookmark
                          : Icons.bookmark_add_outlined,
                      color: AppColors.gold,
                      size: 24,
                    ),
                    onPressed: () {
                      // Handled by SurahItem usually
                    },
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.more_vert, color: AppColors.gold, size: 24),
                    onPressed: () {
                      if (item != null) {
                        DownloadsPage(onNavigate: (_) {})._showDownloadOptions(context, ref, surah, item);
                      }
                    },
                  ),
                ],
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      notifier.translateSurahName(surah.name),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.amiri(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isPaused && currentSpeed > 0)
                    Text(
                      "${currentSpeed.toStringAsFixed(1)} KB/s",
                      style: const TextStyle(color: AppColors.gold, fontSize: 10),
                    ),
                  if (!isPaused && currentSpeed > 0)
                    Text(' • ', style: TextStyle(color: AppColors.muted.withValues(alpha: 0.5))),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(color: Color(0xFFFFE57F), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
