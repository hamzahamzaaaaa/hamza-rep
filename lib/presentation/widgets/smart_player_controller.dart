import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../core/providers/player_provider.dart';

class SmartPlayerController extends ConsumerStatefulWidget {
  final VoidCallback onMinimize;

  const SmartPlayerController({super.key, required this.onMinimize});

  @override
  ConsumerState<SmartPlayerController> createState() => _SmartPlayerControllerState();
}

class _SmartPlayerControllerState extends ConsumerState<SmartPlayerController> with SingleTickerProviderStateMixin {
  bool _isVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    setState(() => _isVisible = true);
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        final isPlaying = ref.read(playerProvider).isPlaying;
        if (isPlaying) {
          setState(() => _isVisible = false);
        } else {
          // If paused, maybe keep it visible? The user said "after 2 seconds of playback or last touch". 
          // Let's hide it anyway after 2 seconds of inactivity to match "يختفي تلقائياً بعد ثانيتين من التشغيل أو من آخر لمسة".
          setState(() => _isVisible = false);
        }
      }
    });
  }

  void _toggleVisibility() {
    if (!_isVisible) {
      _startHideTimer();
    } else {
      setState(() => _isVisible = false);
      _hideTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);

    // Listen to touch events on the parent to show the controller
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _startHideTimer,
      onPanDown: (_) => _startHideTimer(),
      child: Stack(
        children: [
          // Invisible layer to capture taps when controller is hidden
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleVisibility,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSlide(
              offset: _isVisible ? Offset.zero : const Offset(0, 1.2),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header with title and minimize button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.fullscreen_exit, color: AppColors.gold, size: 28),
                                  onPressed: widget.onMinimize,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        state.currentSurah?.name ?? '',
                                        style: GoogleFonts.amiri(
                                          color: AppColors.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'حمزة مدبوح',
                                        style: TextStyle(
                                          color: AppColors.gold.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 28), // Balance for minimize button
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Slim Progress Slider
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                activeTrackColor: AppColors.gold,
                                inactiveTrackColor: Colors.white.withOpacity(0.1),
                                thumbColor: AppColors.gold,
                              ),
                              child: Slider(
                                value: state.position.inMilliseconds.toDouble(),
                                max: state.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                                onChanged: (v) {
                                  _startHideTimer();
                                  notifier.seek(Duration(milliseconds: v.toInt()));
                                },
                              ),
                            ),
                            
                            // Slim Controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
                                  onPressed: () {
                                    _startHideTimer();
                                    notifier.prevSurah();
                                  },
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _startHideTimer();
                                    notifier.togglePlay();
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                                    ),
                                    child: Icon(
                                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: AppColors.gold,
                                      size: 30,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                                  onPressed: () {
                                    _startHideTimer();
                                    notifier.nextSurah();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
