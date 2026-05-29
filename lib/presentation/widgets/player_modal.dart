import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

import 'global_search.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/content_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/data/surah_ai_data.dart';
import 'waveform_visualizer.dart';
import 'synced_lyrics_widget.dart';
import 'mushaf_view_widget.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/advanced_settings_provider.dart';
import '../../core/providers/lrc_and_mushaf_settings_provider.dart';
import '../../core/data/telawat_2018.dart';
import '../../core/data/telawat_2020.dart';
import '../../core/data/telawat_2022.dart';
import '../pages/all_surahs_page.dart';
import '../pages/quran_page.dart';
import 'mushaf_settings_panel.dart';

enum ViewMode { none, lrc, mushaf }

class PlayerModal extends ConsumerStatefulWidget {
  final ViewMode? initialViewMode;
  
  const PlayerModal({super.key, this.initialViewMode});

  @override
  ConsumerState<PlayerModal> createState() => _PlayerModalState();
}

class _PlayerModalState extends ConsumerState<PlayerModal> {
  bool _showControls = true;
  bool _isPinned = false;
  Timer? _hideTimer;
  ViewMode _currentView = ViewMode.lrc; // Default: LRC view (مزامنة الآية)

  @override
  void initState() {
    super.initState();
    // Set initial view mode if provided
    if (widget.initialViewMode != null) {
      _currentView = widget.initialViewMode!;
    }
    _startHideTimer();

    // Auto-reset to LRC view when a new surah starts
    ref.listenManual(playerProvider.select((s) => s.currentSurah?.id), (previous, next) {
      if (previous != next && next != null) {
        setState(() {
          _currentView = ViewMode.lrc;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (_isPinned) return;

    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  Future<bool> _checkHasLyrics(String surahId, String? lrcUrl) async {
    if (lrcUrl != null && lrcUrl.startsWith('http')) return true;
    try {
      final List<String> possibleNames = [
        surahId,
        if (surahId.contains('سورة_'))
          'surah_${surahId.split('سورة_')[1].split('_')[0]}_سورة_${surahId.split('سورة_')[1].split('_')[0]}'
      ];
      if (surahId.contains('المائدة')) possibleNames.add('surah_5_سورة_المائدة');
      if (surahId.contains('الأحزاب')) possibleNames.add('surah_33_سورة_الأحزاب');

      for (var name in possibleNames) {
        try {
          await rootBundle.load('assets/lyrics/$name.lrc');
          return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  void _navigateToCategory(BuildContext context, WidgetRef ref, String category) {
    final content = ref.read(contentProvider);
    List<Surah>? targetList;
    if (category == 'تلاوات 2018') {
      targetList = content.telawat2018;
    } else if (category == 'تلاوات 2019') targetList = content.telawat2019;
    else if (category == 'تلاوات 2020') targetList = content.telawat2020;
    else if (category == 'تلاوات 2022') targetList = content.telawat2022;
    else if (category == 'تلاوات 2023') targetList = content.telawat2023;
    else if (category == 'تلاوات 2024') targetList = content.telawat2024;
    else if (category == 'تلاوات 2025') targetList = content.telawat2025;
    else if (category == 'تلاوات 2026') targetList = content.telawat2026;
    else if (category == 'أناشيد 2024') targetList = content.anashid2024;
    else if (category == 'أناشيد 2023') targetList = content.anashid2023;
    else if (category == 'أناشيد 2022') targetList = content.anashid2022;
    else if (category == 'أناشيد 2020') targetList = content.anashid2020;
    else if (category == 'أناشيد 2019') targetList = content.anashid2019;
    else if (category == 'أناشيد 2018') targetList = content.anashid2018;
    else if (category == 'الأذكار') targetList = content.azkar;
    else if (category == 'الأدعية') targetList = content.doae;
    else if (category == 'القرآن الكريم') targetList = surahList;

    if (targetList != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => AllSurahsPage(title: category, allSurahs: targetList!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final settings = ref.watch(advancedSettingsProvider);

    if (playerState.currentSurah == null) return const SizedBox.shrink();

    final surah = playerState.currentSurah!;
    final activeColor = settings.isWarmMode ? Colors.orangeAccent : AppColors.gold;

    return FutureBuilder<bool>(
      future: _checkHasLyrics(surah.id, surah.lrcUrl),
      builder: (context, snapshot) {
        final hasLyrics = snapshot.data ?? false;

        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
              if (_showControls) _startHideTimer();
            },
            onDoubleTap: () => Navigator.pop(context),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1: Base Background Image
                Image.asset(
                  'assets/images/reciter.png',
                  fit: BoxFit.cover,
                ),

                // --- START: GLASSMORPHISM LAYER ---
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // --- END: GLASSMORPHISM ---

                // Layer 2: Content View (LRC or Mushaf)
                _buildContentView(surah, playerState),
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // View Mode Toggle Buttons (Verse Sync & Mushaf)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildViewModeButton(
                                        icon: Icons.text_snippet,
                                        label: 'مزامنة الآية',
                                        mode: ViewMode.lrc,
                                        activeColor: activeColor,
                                      ),
                                      const SizedBox(width: 12),
                                      _buildViewModeButton(
                                        icon: Icons.menu_book,
                                        label: 'المصحف',
                                        mode: ViewMode.mushaf,
                                        activeColor: activeColor,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Header Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.keyboard_arrow_down, size: 32, color: activeColor),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              surah.name,
                                              style: GoogleFonts.amiri(
                                                color: AppColors.textPrimary,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (surah.category != null)
                                              GestureDetector(
                                                onTap: () {
                                                  // Not supported here as we removed navigation for simplicity or we can just pop
                                                },
                                                child: Text(
                                                  surah.category!,
                                                  style: TextStyle(
                                                    color: settings.isWarmMode ? Colors.orange : Colors.cyanAccent,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )
                                            else
                                              Text(
                                                'حمزة مدبوح',
                                                style: GoogleFonts.amiri(
                                                  color: activeColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Pin Button
                                          IconButton(
                                            icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined, 
                                              color: _isPinned ? activeColor : Colors.white),
                                            onPressed: () {
                                              setState(() {
                                                _isPinned = !_isPinned;
                                                if (_isPinned) {
                                                  _hideTimer?.cancel();
                                                } else {
                                                  _startHideTimer();
                                                }
                                              });
                                            },
                                          ),
                                          // Settings Button (Independent)
                                          IconButton(
                                            icon: Icon(Icons.settings, color: activeColor, size: 24),
                                            onPressed: () {
                                              showMushafSettingsPanel(context, ref);
                                            },
                                            tooltip: 'الإعدادات',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                              ),
                            ),
                            child: SafeArea(
                              child: _buildZoomedControlPanel(context, ref, playerState, playerNotifier, settings),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStandardControlPanel(BuildContext context, WidgetRef ref, PlayerState playerState, PlayerNotifier playerNotifier, AdvancedSettings settings) {
    String? sleepText;
    if (playerState.sleepTimerRemaining != null) {
      final minutes = playerState.sleepTimerRemaining! ~/ 60;
      final seconds = playerState.sleepTimerRemaining! % 60;
      sleepText = "$minutes:${seconds.toString().padLeft(2, '0')}";
    }

    final activeColor = settings.isWarmMode ? Colors.orangeAccent : AppColors.gold;

    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(settings.playerTransparency),
        border: Border(top: BorderSide(color: activeColor.withOpacity(0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ProgressBar(
              progress: playerState.position,
              total: playerState.duration,
              onSeek: (duration) => playerNotifier.seek(duration),
              baseBarColor: AppColors.muted,
              progressBarColor: activeColor,
              thumbColor: activeColor.withOpacity(0.8),
              timeLabelTextStyle: const TextStyle(color: AppColors.textSecondaryDefault, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          // Standard Controls
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.shuffle,
                        color: playerState.isShuffle ? activeColor : AppColors.textSecondary),
                      onPressed: () => playerNotifier.toggleShuffle(),
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_previous, size: 36, color: AppColors.textPrimary),
                      onPressed: () => playerNotifier.prevSurah(),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => playerNotifier.togglePlay(),
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 38,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.skip_next, size: 36, color: AppColors.textPrimary),
                      onPressed: () => playerNotifier.nextSurah(),
                    ),
                    IconButton(
                      icon: Icon(Icons.repeat,
                        color: playerState.isRepeat ? activeColor : AppColors.textSecondary),
                      onPressed: () => playerNotifier.toggleRepeat(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Bottom Row Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildChip(
                      icon: Icons.nights_stay,
                      label: sleepText ?? 'مؤقت',
                      onTap: () => _showSleepPicker(context, ref),
                      isActive: sleepText != null,
                      activeColor: AppColors.destructive,
                    ),
                    const SizedBox(width: 12),
                    _buildChip(
                      icon: Icons.speed,
                      label: '${playerState.speed}x',
                      onTap: () => _showSpeedPicker(context, ref, playerState.speed),
                      isActive: true,
                      activeColor: activeColor,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.menu, color: activeColor),
                      onPressed: () => _showNavigationMenu(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomedControlPanel(BuildContext context, WidgetRef ref, PlayerState state, PlayerNotifier notifier, AdvancedSettings settings) {
    final activeColor = settings.isWarmMode ? Colors.orangeAccent : AppColors.gold;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: settings.blurLevel, sigmaY: settings.blurLevel),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(settings.playerTransparency),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress Slider (Slim)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                  activeTrackColor: activeColor,
                  inactiveTrackColor: Colors.white.withOpacity(0.1),
                  thumbColor: activeColor,
                ),
                child: Slider(
                  value: state.position.inMilliseconds.toDouble(),
                  max: state.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                  onChanged: (v) => notifier.seek(Duration(milliseconds: v.toInt())),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Shuffle
                  IconButton(
                    icon: Icon(Icons.shuffle,
                      size: 20,
                      color: state.isShuffle ? activeColor : Colors.white.withOpacity(0.5)),
                    onPressed: () => notifier.toggleShuffle(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  // Prev
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
                    onPressed: () => notifier.prevSurah(),
                  ),

                  // Play/Pause
                  GestureDetector(
                    onTap: () => notifier.togglePlay(),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Icon(
                        state.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                    onPressed: () => notifier.nextSurah(),
                  ),

                  // Repeat/Hifz
                  IconButton(
                    icon: Icon(state.hifzStart != null ? Icons.loop : (state.isRepeat ? Icons.repeat_one : Icons.repeat),
                      size: 20,
                      color: state.hifzStart != null ? Colors.orangeAccent :
                             (state.isRepeat ? activeColor : Colors.white.withOpacity(0.5))),
                    onPressed: () => notifier.toggleHifzMode(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Speed Control
                  GestureDetector(
                    onTap: () {
                      final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
                      int idx = speeds.indexOf(state.speed);
                      notifier.setSpeed(speeds[(idx + 1) % speeds.length]);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${state.speed}x",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // A-B Loop
                  GestureDetector(
                    onTap: () => notifier.setABPoint(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: state.abStart != null ? AppColors.gold.withValues(alpha: 0.2) : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: state.abStart != null ? AppColors.gold : Colors.transparent),
                      ),
                      child: Text(
                        state.abStart == null ? 'A-B' : (state.abEnd == null ? 'A...' : 'A-B ∞'),
                        style: GoogleFonts.amiri(
                          color: state.abStart != null ? AppColors.gold : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Volume
                  const Icon(Icons.volume_down, color: Colors.white, size: 16),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: activeColor,
                        inactiveTrackColor: Colors.white.withOpacity(0.1),
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: state.volume,
                        onChanged: (v) => notifier.setVolume(v),
                      ),
                    ),
                  ),
                  const Icon(Icons.volume_up, color: Colors.white, size: 16),
                  const SizedBox(width: 12),
                  // Sleep Timer
                  IconButton(
                    icon: Icon(
                      state.sleepTimerRemaining != null || state.stopAfterCurrent 
                          ? Icons.hourglass_bottom 
                          : Icons.hourglass_empty,
                      size: 24,
                      color: state.sleepTimerRemaining != null || state.stopAfterCurrent 
                          ? activeColor 
                          : Colors.white.withOpacity(0.5),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A141F).withOpacity(0.8),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            border: Border.all(color: activeColor.withOpacity(0.3), width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 12),
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: activeColor.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.hourglass_bottom, color: activeColor),
                                        const SizedBox(width: 8),
                                        Text('مؤقت النوم', style: GoogleFonts.amiri(color: activeColor, fontSize: 22, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  if (state.sleepTimerRemaining != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Text(
                                        'متبقي: ${(state.sleepTimerRemaining! / 60).floor()} دقيقة و ${state.sleepTimerRemaining! % 60} ثانية',
                                        style: GoogleFonts.amiri(color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  ListTile(
                                    leading: const Icon(Icons.timer_off, color: Colors.white54),
                                    title: Text('إيقاف المؤقت', style: GoogleFonts.amiri(color: Colors.white, fontSize: 18)), 
                                    onTap: () { notifier.setSleepTimer(null); Navigator.pop(context); }
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.stop_circle_outlined, color: Colors.white54),
                                    title: Text('نهاية المقطع الحالي', style: GoogleFonts.amiri(color: Colors.white, fontSize: 18)), 
                                    onTap: () { notifier.setSleepTimer(null, stopAfterCurrent: true); Navigator.pop(context); }
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.timer_10_select, color: Colors.white54),
                                    title: Text('15 دقيقة', style: GoogleFonts.amiri(color: Colors.white, fontSize: 18)), 
                                    onTap: () { notifier.setSleepTimer(15); Navigator.pop(context); }
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.timer_10_select, color: Colors.white54),
                                    title: Text('30 دقيقة', style: GoogleFonts.amiri(color: Colors.white, fontSize: 18)), 
                                    onTap: () { notifier.setSleepTimer(30); Navigator.pop(context); }
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.timer_10_select, color: Colors.white54),
                                    title: Text('45 دقيقة', style: GoogleFonts.amiri(color: Colors.white, fontSize: 18)), 
                                    onTap: () { notifier.setSleepTimer(45); Navigator.pop(context); }
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.timer_10_select, color: Colors.white54),
                                    title: Text('60 دقيقة', style: GoogleFonts.amiri(color: Colors.white, fontSize: 18)), 
                                    onTap: () { notifier.setSleepTimer(60); Navigator.pop(context); }
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (state.abStart != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.abEnd == null ? 'تم تحديد النقطة أ، اضغط مرة أخرى لتحديد النقطة ب' : 'يتم الآن تكرار المقطع المحدد (A-B)',
                    style: GoogleFonts.amiri(color: activeColor, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : AppColors.muted,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? activeColor : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepPicker(BuildContext context, WidgetRef ref) {
    final options = [15, 30, 45, 60, 90];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('مؤقت النوم', style: GoogleFonts.amiri(fontSize: 20, color: AppColors.gold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _pickerItem(context, 'إيقاف', null, (val) {
                  ref.read(playerProvider.notifier).setSleepTimer(null);
                  Navigator.pop(context);
                }),
                ...options.map((m) => _pickerItem(context, '$m دقيقة', m, (val) {
                  ref.read(playerProvider.notifier).setSleepTimer(val);
                  Navigator.pop(context);
                })),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSpeedPicker(BuildContext context, WidgetRef ref, double current) {
    final options = [0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('سرعة التشغيل', style: GoogleFonts.amiri(fontSize: 20, color: AppColors.gold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: options.map((s) => GestureDetector(
                onTap: () {
                  ref.read(playerProvider.notifier).setSpeed(s);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: current == s ? AppColors.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${s}x',
                    style: TextStyle(
                      color: current == s ? AppColors.background : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _pickerItem(BuildContext context, String text, int? value, Function(int?) onTap) {
    return ElevatedButton(
      onPressed: () => onTap(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.muted,
        foregroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text),
    );
  }

  void _showAIInfoBottomSheet(BuildContext context, Surah surah) {
    final aiData = getAIInfo(surah.id, surah.name);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Text(
                  surah.name,
                  style: GoogleFonts.amiri(fontSize: 24, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAIChip(surah.isMakki ? 'سورة مكية' : 'سورة مدنية', Icons.place),
                _buildAIChip(aiData.verseCount > 0 ? '${aiData.verseCount} آية' : 'غير محدد', Icons.format_list_numbered),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
              ),
              child: Text(
                aiData.summary,
                style: GoogleFonts.amiri(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  height: 1.8,
                ),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'حسناً',
                style: TextStyle(color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showNavigationMenu(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(languageProvider.notifier);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notifier.t('التنقل', 'Navigation', 'Navegação', 'Navigation'),
                style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Divider(color: AppColors.gold, height: 30, indent: 50, endIndent: 50),
              _buildMenuItem(context, Icons.home, notifier.t('الرئيسية', 'Home', 'Início', 'Accueil'), () {
                Navigator.pop(context);
                Navigator.pop(context);
              }),
              _buildMenuItem(context, Icons.book, notifier.t('القرآن الكريم', 'Holy Quran', 'Alcorão', 'Saint Coran'), () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => AllSurahsPage(title: 'القرآن الكريم', allSurahs: surahList)));
              }),
              _buildMenuItem(context, Icons.history, 'تلاوات 2018', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => AllSurahsPage(title: 'تلاوات 2018', allSurahs: telawat2018List)));
              }),
              _buildMenuItem(context, Icons.library_books, 'تلاوات 2020', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => AllSurahsPage(title: 'تلاوات 2020', allSurahs: telawat2020List)));
              }),
              _buildMenuItem(context, Icons.auto_awesome, 'تلاوات 2022', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => AllSurahsPage(title: 'تلاوات 2022', allSurahs: telawat2022List)));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold),
      title: Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  /// ============================================================================
  /// VIEW MODE TOGGLE BUTTONS
  /// ============================================================================

  Widget _buildViewModeButton({
    required IconData icon,
    required String label,
    required ViewMode mode,
    required Color activeColor,
  }) {
    final isActive = _currentView == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentView = isActive ? ViewMode.none : mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : Colors.white.withOpacity(0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? activeColor : Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ============================================================================
  /// CONTENT VIEW (LRC or Mushaf)
  /// ============================================================================

  Widget _buildContentView(Surah surah, PlayerState playerState) {
    switch (_currentView) {
      case ViewMode.lrc:
        // LRC View - Synced Lyrics
        if (surah.lrcUrl != null || _hasLocalLrc(surah.id)) {
          return Positioned.fill(
            child: SyncedLyricsWidget(
              surahId: surah.id,
              position: playerState.position,
              lrcUrl: surah.lrcUrl,
            ),
          );
        } else {
          return _buildDefaultView(surah, playerState);
        }

      case ViewMode.mushaf:
        // Mushaf View - Paper Mushaf
        return Positioned.fill(
          child: MushafViewWidget(
            surahId: surah.id,
            position: playerState.position,
            lrcUrl: surah.lrcUrl,
            surahName: surah.name,
          ),
        );

      case ViewMode.none:
      default:
        // Default View - Background with waveform
        return _buildDefaultView(surah, playerState);
    }
  }

  Widget _buildDefaultView(Surah surah, PlayerState playerState) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/reciter.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          WaveformVisualizer(
            isPlaying: playerState.isPlaying,
            height: 40,
          ),
        ],
      ),
    );
  }

  bool _hasLocalLrc(String surahId) {
    try {
      final List<String> possibleNames = [
        surahId,
        if (surahId.contains('سورة_'))
          'surah_${surahId.split('سورة_')[1].split('_')[0]}_سورة_${surahId.split('سورة_')[1].split('_')[0]}'
      ];
      if (surahId.contains('المائدة')) possibleNames.add('surah_5_سورة_المائدة');
      if (surahId.contains('الأحزاب')) possibleNames.add('surah_33_سورة_الأحزاب');

      for (var name in possibleNames) {
        try {
          rootBundle.load('assets/lyrics/$name.lrc');
          return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }
}
