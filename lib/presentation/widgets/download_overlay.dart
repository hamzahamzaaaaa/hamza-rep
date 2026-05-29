import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/download_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/constants/colors.dart';

class DownloadOverlay extends ConsumerWidget {
  const DownloadOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadProvider);
    final activeDownload = ref.watch(downloadProvider.notifier).activeDownload;
    final notifier = ref.read(languageProvider.notifier);

    // Only show if there's an active (non-completed) download
    // even if it's paused, we show it to allow resumption?
    // The request said: "only when there is an active download, and when it completes or stops, it disappears"
    // "Active" usually means downloading. If it's paused, we'll keep it visible if there's an item in the queue.
    
    final items = downloadState.items.values.where((i) => !i.isCompleted).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final currentItem = activeDownload ?? items.first;
    final progress = currentItem.progress;
    final speed = currentItem.speed; // KB/s
    final speedText = speed > 1024 
        ? "${(speed / 1024).toStringAsFixed(1)} MB/s" 
        : "${speed.toStringAsFixed(0)} KB/s";
    
    final eta = downloadState.globalEta;
    
    // Using a dark purple/violet color to match the image
    const purpleBg = Color(0xFF4A3F75);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: purpleBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Controls (Left) and Title (Right)
            Row(
              children: [
                // Controls
                Row(
                  children: [
                    IconButton(
                      onPressed: () => ref.read(downloadProvider.notifier).cancelDownload(currentItem.surahId),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.white70, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        if (currentItem.isPaused) {
                          ref.read(downloadProvider.notifier).resumeDownload(currentItem.surahId, currentItem.url ?? '');
                        } else {
                          ref.read(downloadProvider.notifier).pauseDownload(currentItem.surahId);
                        }
                      },
                      icon: Icon(
                        currentItem.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Spacer(),
                // Title and Icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${notifier.t('جاري تحميل', 'Downloading', 'Baixando', 'Téléchargement')}: ${notifier.translateSurahName(currentItem.surahName ?? currentItem.surahId.split('_').last)}',
                          style: GoogleFonts.amiri(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.cloud_download_outlined, color: AppColors.gold, size: 20),
                      ],
                    ),
                    Text(
                      notifier.t('مكتبة القرآن • يتم تحميل السورة الحالية', 'Quran Library • Current Surah is being downloaded', 'Biblioteca do Alcorão • A Surata atual está sendo baixada', 'Bibliothèque du Coran • La sourate actuelle est en cours de téléchargement'),
                      style: GoogleFonts.amiri(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Middle Row: Speed, Percentage, ETA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ETA
                if (eta.isNotEmpty && !currentItem.isPaused)
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${notifier.t('متبقي', 'Remaining', 'Restante', 'Restant')} $eta',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                
                // Percentage
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                
                // Speed
                Row(
                  children: [
                    Text(
                      speedText,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.trending_up, color: Colors.white54, size: 14),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                color: AppColors.gold,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
