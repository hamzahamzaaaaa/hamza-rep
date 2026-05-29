import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/download_provider.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/language_provider.dart';
import '../widgets/synced_lyrics_widget.dart';
import '../widgets/quick_index_overlay.dart';
import '../widgets/mushaf_view_widget.dart';

import 'quran_index_page.dart';

class OfflinePlayerPage extends ConsumerStatefulWidget {
  final Surah surah;
  final String? backgroundImage;
  const OfflinePlayerPage({super.key, required this.surah, this.backgroundImage});

  @override
  ConsumerState<OfflinePlayerPage> createState() => _OfflinePlayerPageState();
}

class _OfflinePlayerPageState extends ConsumerState<OfflinePlayerPage> {
  bool _showControls = true;
  bool _isZoomed = true; // Default to zoomed for immersive feel
  bool _showQuickSurahList = false;
  bool _showMushaf = false; // Toggle between lyrics and mushaf view
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  void _toggleControls() {
    if (_showQuickSurahList) return;
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_showQuickSurahList) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final notifier = ref.read(languageProvider.notifier);
    final downloads = ref.watch(downloadProvider);
    final downloadedSurahs = surahList.where((s) => 
      downloads.items.containsKey(s.id) && downloads.items[s.id]!.isCompleted).toList();
    
    final currentSurah = playerState.currentSurah ?? widget.surah;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const QuranIndexPage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black, // Pure black background for eye comfort
        body: Stack(
          children: [
            // Background image layer
            Positioned.fill(
              child: Image.asset(
                widget.backgroundImage ?? 'assets/images/reciter.png',
                fit: BoxFit.cover,
              ),
            ),
            // 60% black dimming overlay for eye comfort
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),
            // Main gesture detector and content
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleControls,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    // "Listening Offline" Indicator
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: _fadeSwitcher(
                          visible: _showControls,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wifi_off, color: Colors.greenAccent, size: 14),
                                  const SizedBox(width: 8),
                                  Text(
                                    notifier.t('أنت تستمع بدون إنترنت', 'You are listening offline', 'Você está ouvindo offline', 'Vous écoutez hors ligne'),
                                    style: GoogleFonts.cairo(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Surah & Reciter Name
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 50,
                      left: 40,
                      right: 40,
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: _fadeSwitcher(
                          visible: _showControls,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currentSurah.name,
                                style: GoogleFonts.amiri(
                                  color: AppColors.textPrimary,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'حمزة مدبوح',
                                style: GoogleFonts.amiri(
                                  color: AppColors.gold,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Lyrics / Mushaf Area
                    SafeArea(
                      child: Center(
                        child: GestureDetector(
                          onScaleUpdate: (details) {
                            if (_showMushaf) return; // Disable zoom gesture in mushaf mode
                            if (details.scale > 1.2 && !_isZoomed) {
                              setState(() => _isZoomed = true);
                            } else if (details.scale < 0.8 && _isZoomed) {
                              setState(() => _isZoomed = false);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: _isZoomed ? double.infinity : 160,
                            padding: EdgeInsets.symmetric(horizontal: _isZoomed ? 10 : 30),
                            child: IgnorePointer(
                              child: _showMushaf
                                  ? MushafViewWidget(
                                      surahId: currentSurah.id,
                                      position: playerState.position,
                                      lrcUrl: currentSurah.lrcUrl,
                                      surahName: currentSurah.name,
                                    )
                                  : SyncedLyricsWidget(
                                      surahId: currentSurah.id,
                                      position: playerState.position,
                                      lrcUrl: currentSurah.lrcUrl,
                                      isZoomed: _isZoomed,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Controls Overlay
                    IgnorePointer(
                      ignoring: !_showControls,
                      child: _fadeSwitcher(
                        visible: _showControls,
                        child: Stack(
                          children: [
                            // Exit Button
                            Positioned(
                              top: MediaQuery.of(context).padding.top + 10,
                              left: 10,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.gold),
                                onPressed: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  } else {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const QuranIndexPage()),
                                    );
                                  }
                                },
                              ),
                            ),

                            // Zoom Toggle Button
                            Positioned(
                              top: MediaQuery.of(context).padding.top + 30,
                              right: 10,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(_isZoomed ? Icons.fullscreen_exit : Icons.fullscreen, color: AppColors.gold, size: 28),
                                    onPressed: () => setState(() => _isZoomed = !_isZoomed),
                                  ),
                                  const SizedBox(height: 15),
                                  // Mushaf Toggle Button (Golden)
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showMushaf = !_showMushaf;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(30),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _showMushaf ? AppColors.gold.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _showMushaf ? AppColors.gold : Colors.white.withOpacity(0.2),
                                            width: _showMushaf ? 2 : 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.menu_book,
                                          size: 24,
                                          color: _showMushaf ? AppColors.gold : Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showQuickSurahList = !_showQuickSurahList;
                                          if (_showQuickSurahList) {
                                            _hideTimer?.cancel();
                                          } else {
                                            _startHideTimer();
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(30),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                                        ),
                                        child: const Icon(Icons.menu_book, size: 24, color: AppColors.gold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Bottom Control Panel
                            Positioned(
                              bottom: 30,
                              left: 16,
                              right: 16,
                              child: _buildControlPanel(context, ref, playerState, playerNotifier, notifier),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Quick Surah List Overlay
                    if (_showQuickSurahList)
                      QuickIndexOverlay(
                        surahs: downloadedSurahs,
                        onSurahSelected: (surah) {
                          playerNotifier.playSurah(surah, downloadedSurahs);
                          setState(() {
                            _showQuickSurahList = false;
                            _startHideTimer();
                          });
                        },
                        onClose: () => setState(() {
                          _showQuickSurahList = false;
                          _startHideTimer();
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Smooth AnimatedSwitcher fade for controls
  Widget _fadeSwitcher({required bool visible, required Widget child}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: visible
          ? KeyedSubtree(key: const ValueKey('visible'), child: child)
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }

  Widget _buildControlPanel(BuildContext context, WidgetRef ref, PlayerState state, PlayerNotifier notifier, LanguageNotifier lang) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.hifzStart != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lang.t('وضع المساعدة على الحفظ نشط', 'Hifz Mode Active', 'Modo Hifz Ativo', 'Mode Hifz Actif'),
                      style: GoogleFonts.cairo(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                  activeTrackColor: AppColors.gold,
                  inactiveTrackColor: Colors.white.withOpacity(0.1),
                  thumbColor: AppColors.gold,
                ),
                child: Slider(
                  value: state.position.inMilliseconds.toDouble(),
                  max: state.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                  onChanged: (v) => notifier.seek(Duration(milliseconds: v.toInt())),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(state.position),
                      style: GoogleFonts.robotoMono(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '-${_formatDuration(state.duration - state.position)}',
                      style: GoogleFonts.robotoMono(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.volume_mute, color: Colors.white54, size: 16),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                        activeTrackColor: Colors.white54,
                        inactiveTrackColor: Colors.white10,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: state.volume,
                        onChanged: (v) => notifier.setVolume(v),
                      ),
                    ),
                  ),
                  const Icon(Icons.volume_up, color: Colors.white54, size: 16),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(
                    icon: state.hifzStart != null ? Icons.psychology : Icons.psychology_outlined,
                    color: state.hifzStart != null ? Colors.orangeAccent : Colors.white70,
                    onTap: () => notifier.toggleHifzMode(),
                    label: lang.t('حفظ', 'Hifz', 'Hifz', 'Hifz'),
                  ),

                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                    onPressed: () => notifier.prevSurah(),
                  ),

                  GestureDetector(
                    onTap: () => notifier.togglePlay(),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 15)],
                      ),
                      child: Icon(
                        state.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 36,
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                    onPressed: () => notifier.nextSurah(),
                  ),

                  _controlButton(
                    icon: Icons.abc,
                    color: state.abStart != null ? AppColors.gold : Colors.white70,
                    onTap: () => notifier.setABPoint(),
                    label: state.abStart == null 
                        ? 'A-B' 
                        : (state.abEnd == null ? 'Set B' : 'Clear'),
                  ),

                  _controlButton(
                    icon: state.isRepeat ? Icons.repeat_one : Icons.repeat,
                    color: state.isRepeat ? AppColors.gold : Colors.white70,
                    onTap: () => notifier.toggleRepeat(),
                    label: lang.t('تكرار', 'Repeat', 'Repetir', 'Répéter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlButton({required IconData icon, required Color color, required VoidCallback onTap, required String label}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.cairo(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
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
}
