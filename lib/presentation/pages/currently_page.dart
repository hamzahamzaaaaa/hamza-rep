import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/content_provider.dart';
import '../../core/providers/advanced_settings_provider.dart';
import '../pages/collection_page.dart';
import '../widgets/surah_item.dart';
import '../widgets/synced_lyrics_widget.dart';
import '../widgets/global_search.dart';
import '../widgets/quick_index_overlay.dart';
import '../../core/data/surah_ai_data.dart';
import '../widgets/waveform_visualizer.dart';
import '../widgets/sync_settings_bottom_sheet.dart';
import '../widgets/player_modal.dart';


class CurrentlyPage extends ConsumerStatefulWidget {
  const CurrentlyPage({super.key});

  @override
  ConsumerState<CurrentlyPage> createState() => _CurrentlyPageState();
}

class _CurrentlyPageState extends ConsumerState<CurrentlyPage> {
  bool _showControls = true;
  bool _showQuickSurahList = false;
  bool _isIndexVisible = false; // New state to manage immersive list visibility
  bool _isLyricsVisible = true; // State for toggling lyrics visibility
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';
  Timer? _hideTimer;
  List<Surah>? _shuffledSuggestions;

  @override
  void initState() {
    super.initState();
    // Hide MiniPlayer when entering CurrentlyPage
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ref.read(playerProvider.notifier).setMiniPlayerVisibility(false);
    // });
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
    if (!_isLyricsVisible) return; // Do not auto-hide in Luxury Design
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
    _searchController.dispose();
    // Show MiniPlayer when exiting CurrentlyPage
    // ref.read(playerProvider.notifier).setMiniPlayerVisibility(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final contentState = ref.watch(contentProvider);
    final isZoomed = playerState.isLyricsZoomed;
    final notifier = ref.read(languageProvider.notifier);
    final settings = ref.watch(advancedSettingsProvider);

    if (isZoomed && playerState.currentSurah != null) {
      final playerNotifier = ref.read(playerProvider.notifier);
      final bool hasLyrics = playerState.currentSurah!.hasLyrics;
      final bool showLyricsContainer = hasLyrics && _isLyricsVisible;

      String formatDuration(Duration? duration) {
        if (duration == null) return "00:00";
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
        String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
        if (duration.inHours > 0) return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
        return "$twoDigitMinutes:$twoDigitSeconds";
      }

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          playerNotifier.toggleLyricsZoom();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: _toggleControls,
            onDoubleTap: () => playerNotifier.toggleLyricsZoom(),
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                // Layer 1: Background Image — always visible (never fades to black)
                Positioned.fill(
                  child: Hero(
                    tag: 'reciter_image',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      transform: Matrix4.identity()..scale(showLyricsContainer ? 1.0 : 1.15),
                      transformAlignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/reciter.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(color: Colors.black.withOpacity(0.35 + (settings.dimLevel * 0.5))),
                  ),
                ),

                // Layer 2: Main Content Area (SafeArea)
                SafeArea(
                  child: Column(
                    children: [
                      // Top Section & Dynamic Center Content
                      Expanded(
                        child: AnimatedOpacity(
                          opacity: _showControls ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: IgnorePointer(
                            ignoring: !_showControls,
                            child: Stack(
                              children: [
                                // Top Actions (Search, Exit Zoom, Toggle)
                                Positioned(
                                  top: 20,
                                  left: 20,
                                  right: 20,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Left: Actions
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.fullscreen_exit, size: 30, color: AppColors.gold),
                                            onPressed: () => playerNotifier.toggleLyricsZoom(),
                                          ),
                                          const SizedBox(height: 15),
                                          IconButton(
                                            icon: const Icon(Icons.search, size: 28, color: AppColors.gold),
                                            onPressed: () {
                                                setState(() => _showQuickSurahList = true);
                                            },
                                          ),
                                        ],
                                      ),
                                      // Right: Toggle Sync
                                      if (hasLyrics)
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                _isLyricsVisible ? Icons.subtitles_off : Icons.subtitles,
                                                size: 28,
                                                color: AppColors.gold,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _isLyricsVisible = !_isLyricsVisible;
                                                  if (!_isLyricsVisible) {
                                                    _showControls = true; // Ensure controls are visible when entering Luxury Design
                                                    _hideTimer?.cancel();
                                                  } else {
                                                    _startHideTimer();
                                                  }
                                                });
                                              },
                                            ),
                                            if (_isLyricsVisible) ...[
                                              const SizedBox(height: 15),
                                              IconButton(
                                                icon: const Icon(Icons.settings, size: 28, color: AppColors.gold),
                                                onPressed: () {
                                                  _hideTimer?.cancel();
                                                  showSyncSettingsBottomSheet(context, ref);
                                                },
                                              ),
                                            ],
                                          ],
                                        )
                                      else
                                        const SizedBox(width: 48), // Spacer
                                    ],
                                  ),
                                ),
                                // Center: Animated Waveform and Title
                                AnimatedAlign(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                  alignment: showLyricsContainer ? Alignment.topCenter : Alignment.center,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: showLyricsContainer ? 20 : 0),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeInOut,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            playerState.currentSurah!.name,
                                            style: GoogleFonts.amiri(
                                              color: AppColors.textPrimary,
                                              fontSize: showLyricsContainer ? 22 : 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(
                                            'حمزة مدبوح',
                                            style: GoogleFonts.amiri(
                                              color: AppColors.gold,
                                              fontSize: showLyricsContainer ? 14 : 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          AnimatedSize(
                                            duration: const Duration(milliseconds: 500),
                                            curve: Curves.easeInOut,
                                            child: SizedBox(
                                              height: showLyricsContainer ? 40 : 80,
                                              child: WaveformVisualizer(isPlaying: playerState.isPlaying, height: showLyricsContainer ? 40 : 80),
                                            ),
                                          ),
                                          AnimatedSize(
                                            duration: const Duration(milliseconds: 500),
                                            curve: Curves.easeInOut,
                                            child: showLyricsContainer 
                                              ? const SizedBox.shrink()
                                              : Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: AnimatedOpacity(
                                                    opacity: showLyricsContainer ? 0.0 : 1.0,
                                                    duration: const Duration(milliseconds: 500),
                                                    child: Text(
                                                      formatDuration(playerState.position),
                                                      style: GoogleFonts.amiri(
                                                        color: AppColors.gold,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 1.2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Center Section: Lyrics Container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        height: showLyricsContainer
                            ? MediaQuery.of(context).size.height *
                                (settings.syncDisplayAreaSize == SyncDisplayAreaSize.quarter
                                    ? 0.25
                                    : settings.syncDisplayAreaSize == SyncDisplayAreaSize.half
                                        ? 0.45
                                        : 0.65)
                            : 0,
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withOpacity(0.05),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  )
                                ]
                              ),
                              child: SyncedLyricsWidget(
                                surahId: playerState.currentSurah!.id,
                                position: playerState.position,
                                lrcUrl: playerState.currentSurah!.lrcUrl,
                                isZoomed: true, // we use true to tell it to be large
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom padding for player
                      const SizedBox(height: 120),
                    ],
                  ),
                ),

              // Layer 4: Bottom Controls (Slide Up Animation)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                bottom: _showControls ? 30 : -200,
                left: 16,
                right: 16,
                child: _buildZoomedControlPanel(context, ref, playerState, playerNotifier),
              ),

              // Layer 4.5: Swipe-up invisible handle at the bottom
              if (!_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! < -5) {
                        setState(() {
                          _showControls = true;
                        });
                        _startHideTimer();
                      }
                    },
                  ),
                ),

              // Layer 5: Immersive Quick Index Overlay
              if (_isIndexVisible)
                QuickIndexOverlay(
                  surahs: surahList,
                  onSurahSelected: (surah) {
                    playerNotifier.playSurah(surah, surahList);
                    setState(() {
                      _isIndexVisible = false;
                      _startHideTimer();
                    });
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const PlayerModal(),
                    );
                  },
                  onClose: () => setState(() {
                    _isIndexVisible = false;
                    _startHideTimer();
                  }),
                ),

              // Layer 6: Original Quick Surah List Overlay (Legacy)
              if (_showQuickSurahList)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _showQuickSurahList = false;
                      _startHideTimer();
                    }),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withOpacity(0.7),
                        child: Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: MediaQuery.of(context).size.height * 0.7,
                            decoration: BoxDecoration(
                              color: AppColors.surface.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    notifier.t('اختر سورة', 'Select Surah', 'Selecionar Surah', 'Choisir une Sourate'),
                                    style: GoogleFonts.amiri(fontSize: 22, color: AppColors.gold, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    itemCount: surahList.length,
                                    separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                                    itemBuilder: (context, index) {
                                      final surah = surahList[index];
                                      final isPlaying = playerState.currentSurah?.id == surah.id;
                                      return ListTile(
                                        onTap: () {
                                          playerNotifier.playSurah(surah, surahList);
                                          setState(() {
                                            _showQuickSurahList = false;
                                            _startHideTimer();
                                          });
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            useSafeArea: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => const PlayerModal(),
                                          );
                                        },
                                        leading: Text('${index + 1}', style: const TextStyle(color: Colors.white38)),
                                        title: Text(
                                          surah.name,
                                          style: GoogleFonts.amiri(
                                            color: isPlaying ? AppColors.gold : Colors.white,
                                            fontSize: 18,
                                            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                        trailing: isPlaying ? const Icon(Icons.play_circle_fill, color: AppColors.gold) : null,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

            ],
          ),
        ),
      ));
    }

    // Combine lists for endless suggestions
    final allSuggestions = _shuffledSuggestions ?? [
      ...surahList,
      ...contentState.telawat2026,
      ...contentState.telawat2018,
      ...contentState.telawat2019,
      ...contentState.telawat2020,
      ...contentState.telawat2022,
      ...contentState.telawat2023,
      ...contentState.telawat2024,
      ...contentState.telawat2025,
      ...contentState.telawat2026Local,
      ...contentState.anashid2018,
      ...contentState.anashid2019,
      ...contentState.anashid2020,
      ...contentState.anashid2022,
      ...contentState.anashid2023,
      ...contentState.anashid2024,
      ...contentState.azkar,
      ...contentState.doae,
      ...contentState.githubList,
      ...contentState.youtubeRecitationsList,
      ...contentState.remoteGithubList,
      ...contentState.quranKareemRemote,
    ];

    final collections = [
      {
        'title': notifier.t('القرآن الكريم', 'Holy Quran', 'Alcorão', 'Saint Coran'),
        'list': surahList
      },
      if (contentState.telawat2026.isNotEmpty)
      {
        'title': 'تلاوات 2026',
        'list': contentState.telawat2026
      },
      {
        'title': 'تلاوات 2018',
        'list': contentState.telawat2018
      },
      {
        'title': 'سور 2018',
        'list': contentState.telawat2022
      },
      {
        'title': 'تلاوات 2019',
        'list': contentState.telawat2019
      },
      {
        'title': 'تلاوات 2020',
        'list': contentState.telawat2020
      },
      {
        'title': 'تلاوات 2023',
        'list': contentState.telawat2023
      },
      {
        'title': 'تلاوات 2024',
        'list': contentState.telawat2024
      },
      if (contentState.telawat2025.isNotEmpty)
      {
        'title': 'تلاوات 2025',
        'list': contentState.telawat2025
      },
      {
        'title': 'أناشيد 2018',
        'list': contentState.anashid2018
      },
      {
        'title': 'أناشيد 2019',
        'list': contentState.anashid2019
      },
      {
        'title': 'أناشيد 2020',
        'list': contentState.anashid2020
      },
      {
        'title': 'أناشيد 2024',
        'list': contentState.anashid2024
      },
      if (contentState.azkar.isNotEmpty)
      {
        'title': notifier.t('الأذكار', 'Azkar', 'Azkar', 'Azkar'),
        'list': contentState.azkar
      },
      if (contentState.doae.isNotEmpty)
      {
        'title': notifier.t('الأدعية', 'Duas', 'Duas', 'Douas'),
        'list': contentState.doae
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 40,
        title: Text(
          notifier.t('جاري التشغيل الآن', 'Currently Playing', 'Tocando Agora',
              'En cours'),
          style:
              GoogleFonts.amiri(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          showSearch(
                            context: context,
                            delegate: GlobalSearchDelegate(ref: ref),
                          );
                        },
                        icon: const Icon(Icons.search,
                            color: AppColors.gold, size: 24),
                      ),
                      Text(
                        notifier.t('تلاوات +', 'Recitations +', 'Recitações +',
                            'Récitations +'),
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: collections.length,
                    itemBuilder: (context, index) {
                      final title = collections[index]['title'] as String;
                      final list = collections[index]['list'] as List<Surah>;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CollectionPage(title: title, surahs: list),
                            ),
                          );
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            children: [
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.gold, width: 2),
                                  image: const DecorationImage(
                                    image:
                                        AssetImage('assets/images/reader.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                title,
                                style: GoogleFonts.amiri(
                                    color: AppColors.textPrimary, fontSize: 11),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Consumer(
                builder: (context, ref, child) {
                  final playerState = ref.watch(playerProvider);
                  final isZoomed = playerState.isLyricsZoomed;

                  if (playerState.currentSurah == null) {
                    return Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.muted),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.music_note,
                              size: 48, color: AppColors.mutedDefault),
                          const SizedBox(height: 16),
                          Text(
                            notifier.t(
                                'لا يوجد تشغيل حالياً',
                                'No playback active',
                                'Nenhuma reprodução ativa',
                                'Aucune lecture active'),
                            style:
                                const TextStyle(color: AppColors.textSecondaryDefault),
                          ),
                        ],
                      ),
                    );
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    padding: EdgeInsets.all(isZoomed ? 0 : 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(isZoomed ? 0 : 16),
                      border: Border.all(
                          color: isZoomed ? Colors.transparent : Colors.red.withOpacity(0.3),
                          width: 1),
                      boxShadow: isZoomed ? [] : [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isZoomed) ...[
                          // New Header for CurrentlyPage
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const PulsingDot(),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  notifier.translateSurahName(
                                      playerState.currentSurah!.name),
                                  style: GoogleFonts.amiri(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'حمزة مدبوح',
                                style: TextStyle(
                                    color: AppColors.gold.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const MiniWaveform(),
                          const SizedBox(height: 8),
                        ],
                        // Lyrics Area in Glassmorphism Container
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.gold.withOpacity(0.05),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        )
                                      ],
                                    ),
                                    child: SyncedLyricsWidget(
                                      surahId: playerState.currentSurah!.id,
                                      position: playerState.position,
                                      lrcUrl: playerState.currentSurah!.lrcUrl,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.fullscreen, color: AppColors.gold, size: 32),
                                  onPressed: () {
                                    ref.read(playerProvider.notifier).toggleLyricsZoom();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isZoomed) ...[
                          const SizedBox(height: 12),
                          // New Progress Slider Section
                          Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                                  activeTrackColor: AppColors.gold,
                                  inactiveTrackColor: AppColors.gold.withOpacity(0.1),
                                  thumbColor: AppColors.gold,
                                ),
                                child: Slider(
                                  value: playerState.position.inMilliseconds.toDouble(),
                                  max: playerState.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                                  onChanged: (v) => ref.read(playerProvider.notifier).seek(Duration(milliseconds: v.toInt())),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(playerState.position),
                                      style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '-${_formatDuration(playerState.duration - playerState.position)}',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Bottom Controls Redesign
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0A0A), // Royal Black
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // AI Information Button
                                IconButton(
                                  icon: const Icon(Icons.psychology, color: AppColors.gold, size: 28),
                                  onPressed: () => _showAIInfoBottomSheet(context, playerState.currentSurah!),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.skip_previous, color: AppColors.gold, size: 32),
                                  onPressed: () => ref.read(playerProvider.notifier).prevSurah(),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () => ref.read(playerProvider.notifier).togglePlay(),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.gold,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.gold.withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: const Color(0xFF0A0A0A), // Royal Black
                                      size: 36,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                IconButton(
                                  icon: const Icon(Icons.skip_next, color: AppColors.gold, size: 32),
                                  onPressed: () => ref.read(playerProvider.notifier).nextSurah(),
                                ),
                                const SizedBox(width: 8),
                                // Repeat Toggle Button
                                IconButton(
                                  icon: Icon(
                                    playerState.isRepeat ? Icons.repeat_one : Icons.repeat,
                                    color: playerState.isRepeat ? AppColors.gold : AppColors.gold.withOpacity(0.5),
                                    size: 26,
                                  ),
                                  onPressed: () => ref.read(playerProvider.notifier).toggleRepeat(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle, color: AppColors.gold, size: 24),
                        onPressed: () {
                          final all = [
                            ...surahList,
                            ...contentState.telawat2026,
                            ...contentState.telawat2018,
                            ...contentState.telawat2019,
                            ...contentState.telawat2020,
                            ...contentState.telawat2022,
                            ...contentState.telawat2023,
                            ...contentState.telawat2024,
                            ...contentState.telawat2025,
                            ...contentState.telawat2026Local,
                            ...contentState.anashid2018,
                            ...contentState.anashid2019,
                            ...contentState.anashid2020,
                            ...contentState.anashid2022,
                            ...contentState.anashid2023,
                            ...contentState.anashid2024,
                          ];
                          all.shuffle();
                          setState(() {
                            _shuffledSuggestions = all;
                          });
                        },
                      ),
                      Text(
                        notifier.t('تلاوات مقترحة', 'Suggested Recitations',
                            'Recitações Sugeridas', 'Récitations Suggérées'),
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final playerState = ref.watch(playerProvider);
              final playerNotifier = ref.read(playerProvider.notifier);

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 150),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final surah = allSuggestions[index];
                      final isCurrent =
                          playerState.currentSurah?.id == surah.id;

                      return SurahItem(
                        key: ValueKey(surah.id),
                        surah: surah,
                        index: index,
                        isPlaying: isCurrent && playerState.isPlaying,
                        onTap: () => playerNotifier.playSurah(surah, allSuggestions.cast<Surah>()),
                      );
                    },
                    childCount: allSuggestions.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
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

  Widget _buildZoomedControlPanel(BuildContext context, WidgetRef ref, PlayerState state, PlayerNotifier notifier) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
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
              // Progress Slider (Slim & Responsive)
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
                  onChanged: (v) {
                    _startHideTimer();
                    notifier.seek(Duration(milliseconds: v.toInt()));
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Elapsed Time on the Right (Arabic Context)
                  Text(
                    _formatDuration(state.position),
                    style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  // Remaining Time on the Left
                  Text(
                    '-${_formatDuration(state.duration - state.position)}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.shuffle,
                      size: 20,
                      color: state.isShuffle ? AppColors.gold : Colors.white.withOpacity(0.5)),
                    onPressed: () {
                      _startHideTimer();
                      notifier.toggleShuffle();
                    },
                  ),
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
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1),
                        boxShadow: [
                          BoxShadow(color: AppColors.gold.withOpacity(0.1), blurRadius: 10)
                        ],
                      ),
                      child: Icon(
                        state.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppColors.gold,
                        size: 32,
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
                  IconButton(
                    icon: Icon(state.isRepeat ? Icons.repeat_one : Icons.repeat,
                      size: 20,
                      color: state.isRepeat ? AppColors.gold : Colors.white.withOpacity(0.5)),
                    onPressed: () {
                      _startHideTimer();
                      notifier.toggleRepeat();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
                const Icon(Icons.auto_awesome, color: AppColors.gold),
                const SizedBox(width: 8),
                Text(
                  surah.name,
                  style: GoogleFonts.amiri(
                      fontSize: 24,
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAIChip(
                    surah.isMakki ? 'سورة مكية' : 'سورة مدنية', Icons.place),
                _buildAIChip(
                    aiData.verseCount > 0 ? '${aiData.verseCount} آية' : 'غير محدد',
                    Icons.format_list_numbered),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withOpacity(0.2)),
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
                backgroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'حسناً',
                style: TextStyle(
                    color: AppColors.backgroundDefault,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
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
          Text(label,
              style:
                  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(languageProvider.notifier);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(notifier.t('اختر اللغة', 'Select Language', 'Selecione o idioma', 'Choisir la langue'),
                style: GoogleFonts.amiri(fontSize: 20, color: AppColors.gold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _pickerItem(context, 'العربية', 'ar', (val) {
                  notifier.setLanguage('ar');
                  Navigator.pop(context);
                }),
                _pickerItem(context, 'English', 'en', (val) {
                  notifier.setLanguage('en');
                  Navigator.pop(context);
                }),
                _pickerItem(context, 'Français', 'fr', (val) {
                  notifier.setLanguage('fr');
                  Navigator.pop(context);
                }),
                _pickerItem(context, 'Português', 'pt', (val) {
                  notifier.setLanguage('pt');
                  Navigator.pop(context);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerItem(BuildContext context, String text, String value, Function(String) onTap) {
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
}
