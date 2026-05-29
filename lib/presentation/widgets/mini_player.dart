import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/download_provider.dart';
import '../../core/constants/colors.dart';
import 'surah_item.dart'; // To use MiniWaveform and PulsingDot
import '../pages/smart_mushaf_page.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    
    // Select only the first active download to minimize rebuilds
    final activeDownload = ref.watch(downloadProvider.select((s) => 
      s.items.values.where((item) => !item.isCompleted && !item.isPaused).firstOrNull));

    if (playerState.currentSurah == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        if (playerState.currentSurah != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SmartMushafPage(
                surah: playerState.currentSurah!,
                playlist: playerNotifier.currentQueue,
              ),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activeDownload != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'جاري تحميل: ${activeDownload.surahId}',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(activeDownload.progress * 100).toInt()}%',
                    style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Container(
            height: 65,
            margin: EdgeInsets.fromLTRB(12, activeDownload != null ? 0 : 8, 12, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A).withValues(alpha: 0.95), // Deep Black
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const PulsingDot(),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/reader.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              playerState.currentSurah!.name,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              if (playerState.isPlaying) {
                                _waveController.repeat();
                              } else {
                                _waveController.stop();
                              }
                              return CustomPaint(
                                size: const Size(40, 16),
                                painter: _WavePainter(
                                  animation: _waveController,
                                  isPlaying: playerState.isPlaying,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'حالياً',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'حمزة مدبوح',
                        style: TextStyle(
                          color: AppColors.gold.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    playerState.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: AppColors.gold,
                    size: 32,
                  ),
                  onPressed: () => playerNotifier.togglePlay(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                  onPressed: () => playerNotifier.closePlayer(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 0) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) return "${d.inHours}:$minutes:$seconds";
    return "$minutes:$seconds";
  }
}

// Custom wave painter for animated waveform
class _WavePainter extends CustomPainter {
  final Animation<double> animation;
  final bool isPlaying;

  _WavePainter({required this.animation, required this.isPlaying})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    const barCount = 5;
    final barWidth = size.width / (barCount * 2 - 1);
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      double barHeight;
      if (isPlaying) {
        // Animated height using sine wave
        final wave = (animation.value * 2 * 3.14159) + (i * 0.8);
        barHeight = 4 + (size.height * 0.6 * (0.5 + 0.5 * sin(wave)));
      } else {
        barHeight = 4;
      }

      final x = i * barWidth * 2;
      final top = centerY - barHeight / 2;

      // Draw rounded bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        const Radius.circular(1.5),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.isPlaying != isPlaying;
  }
}
