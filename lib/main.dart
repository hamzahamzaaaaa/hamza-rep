import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:dio/dio.dart';

import 'core/providers/theme_provider.dart';
import 'core/models/surah.dart';

import 'core/providers/content_provider.dart';
import 'dart:math' as math;
import 'core/constants/colors.dart';
import 'core/providers/player_provider.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/download_provider.dart';
import 'core/services/audio_handler.dart';
import 'core/services/notification_service.dart';
import 'presentation/widgets/pulsing_download_icon.dart';
import 'presentation/widgets/surah_item.dart';
import 'presentation/widgets/mini_player.dart';
import 'presentation/pages/recently_added_page.dart';
import 'presentation/pages/more_page.dart';
import 'presentation/pages/downloads_page.dart';
import 'presentation/pages/quran_page.dart';
import 'presentation/pages/currently_page.dart';
import 'presentation/pages/all_surahs_page.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/widgets/global_search.dart';

import 'presentation/pages/quran_index_page.dart';
import 'presentation/pages/offline_player_page.dart';
import 'presentation/pages/statistics_page.dart';
import 'presentation/widgets/player_modal.dart';

final container = ProviderContainer();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  String artUriPath = ''; // Declare at the top
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Web-specific initialization
    if (kIsWeb) {
      // Skip mobile-only features on web
      print('Running on Web - Skipping mobile-specific initialization');
    } else {
      // Mobile/Desktop initialization
      FlutterForegroundTask.initCommunicationPort();
      
      // Notifications only supported on mobile/desktop
      await NotificationService.init(
        onAction: (actionId) {
          if (actionId == 'pause_all') {
            container.read(downloadProvider.notifier).pauseAllDownloads();
          } else if (actionId == 'cancel_all') {
            container.read(downloadProvider.notifier).clearAllDownloads();
          }
        },
        onSelectNotification: (payload) {
          if (payload != null && payload.startsWith('play_')) {
            // Split payload to extract ID, Background path, and Sync Type
            final parts = payload.split('|');
            final surahId = parts[0].replaceFirst('play_', '');
            final bgPath = parts.length > 1 ? parts[1] : 'assets/images/reciter.png';
            final syncType = parts.length > 2 ? parts[2] : 'lrc'; // Default to LRC
            
            // Wait for app to be ready then play
            Future.delayed(const Duration(milliseconds: 500), () {
              final content = container.read(contentProvider);
              final allSurahs = [
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
              
              try {
                final surah = allSurahs.firstWhere((s) => s.id == surahId);
                
                // Check if surah is downloaded - if so, use full features
                final downloads = container.read(downloadProvider);
                final isDownloaded = downloads.items[surahId]?.isCompleted == false;
                
                container.read(playerProvider.notifier).playSurah(surah, [surah]);
                
                // Navigate to the unified Player Modal with sync type
                ViewMode initialView = ViewMode.none;
                if (syncType == 'lrc') {
                  initialView = ViewMode.lrc;
                } else if (syncType == 'mushaf') {
                  initialView = ViewMode.mushaf;
                }
                
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => PlayerModal(initialViewMode: initialView),
                  ),
                );
              } catch (e) {
                print("Error playing from notification: $e");
              }
            });
          }
        }
      );

      // Request permissions - only on native platforms
      try {
        await [
          Permission.notification,
          Permission.storage,
        ].request();

        // Android specific optimizations
        if (Platform.isAndroid) {
          // Request to ignore battery optimizations for uninterrupted background tasks
          if (await Permission.ignoreBatteryOptimizations.isDenied) {
            await Permission.ignoreBatteryOptimizations.request();
          }
          
          // Double check if we can open the restricted settings page if needed
          if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
            await FlutterForegroundTask.requestIgnoreBatteryOptimization();
          }
        }
      } catch (e) {
        print("Permissions error: $e");
      }
      
      // Pre-connect Dio to warm up the connection
      try {
        Dio().get('https://raw.githubusercontent.com').timeout(const Duration(seconds: 2)).catchError((_) => Response(requestOptions: RequestOptions(path: '')));
      } catch (_) {}

      // Copy reciter image to temp directory for AudioService notification
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/reciter.png');
        if (!await file.exists()) {
          final byteData = await rootBundle.load('assets/images/reciter.png');
          await file.writeAsBytes(byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        }
        artUriPath = 'file://${file.path}';
      } catch (e) {
        print("Art URI setup error: $e");
      }
    }

    // Initialize the background audio service - Skip on web
    if (!kIsWeb) {
      final handler = await AudioService.init(
        builder: () => MyAudioHandler(artUriPath: artUriPath),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.hamza.medbouh.channel.audio',
          androidNotificationChannelName: 'Hamza Medbouh Quran Playback',
          androidStopForegroundOnPause: false, // Keep notification when paused
          androidNotificationIcon: 'mipmap/ic_launcher',
        ),
      );
      container.read(playerProvider.notifier).setHandler(handler);
    } else {
      print('Web platform: AudioService initialization skipped');
    }

    // Sort global surahList by mushafIndex
    surahList.sort((a, b) => a.mushafIndex.compareTo(b.mushafIndex));

    // Launch the UI
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const MedbouhQuranApp(),
      ),
    );
  } catch (e) {
    print("Global Startup Error: $e");
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF08060A),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'خطأ في التشغيل: $e',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    runApp(const MedbouhQuranApp());
                  },
                  child: const Text('إعادة المحاولة / Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MedbouhQuranApp extends ConsumerWidget {
  const MedbouhQuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langState = ref.watch(languageProvider);
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      key: ValueKey(langState.selectedLanguage), // Added key to force rebuild
      title: 'حمزة مدبوح',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.mode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.gold,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
          },
        ),
        colorScheme: ColorScheme.light(
          primary: AppColors.gold,
          secondary: AppColors.goldDark,
          surface: AppColors.surface,
        ),
        textTheme:
            GoogleFonts.amiriTextTheme(ThemeData.light().textTheme).copyWith(
          displayLarge: GoogleFonts.amiri(
            color: AppColors.gold,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: GoogleFonts.amiri(
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.gold,
        colorScheme: ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.goldDark,
          surface: AppColors.surface,
        ),
        textTheme:
            GoogleFonts.amiriTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.amiri(
            color: AppColors.gold,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: GoogleFonts.amiri(
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

class HomeRecommendationsNotifier extends StateNotifier<List<Surah>> {
  final Ref _ref;
  Timer? _timer;

  HomeRecommendationsNotifier(this._ref) : super([]) {
    _ref.listen(contentProvider, (previous, next) {
      shuffle();
    });
    shuffle();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 3000), (_) => shuffle());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void shuffle() {
    final content = _ref.read(contentProvider);
    final allTracks = [
      ...surahList,
      ...content.telawat2026,
      ...content.telawat2018,
      ...content.telawat2020,
      ...content.telawat2022,
      ...content.telawat2023,
      ...content.telawat2024,
      ...content.telawat2025,
      ...content.telawat2026Local,
      ...content.azkar,
      ...content.doae,
    ];
    if (allTracks.isNotEmpty) {
      final list = List<Surah>.from(allTracks)..shuffle();
      state = list.take(20).toList();
    } else {
      final list = List<Surah>.from(surahList)..shuffle();
      state = list.take(20).toList();
    }
  }
}

final homeRecommendationsProvider = StateNotifierProvider<HomeRecommendationsNotifier, List<Surah>>((ref) {
  return HomeRecommendationsNotifier(ref);
});

final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    ref.read(homeRecommendationsProvider.notifier).shuffle();
    ref.read(playerProvider.notifier).setMiniPlayerVisibility(index != 3);
  }

  void switchToCurrentlyPage() {
    _onItemTapped(3);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final notifier = ref.read(languageProvider.notifier);

    final List<Widget> screens = [
      HomeScreen(onNavigate: _onItemTapped),
      QuranPage(onNavigate: _onItemTapped),
      const RecentlyAddedPage(),
      const CurrentlyPage(),
      DownloadsPage(onNavigate: _onItemTapped),
      const MorePage(),
    ];

    final playerState = ref.watch(playerProvider);
    final isZoomed = playerState.isLyricsZoomed;
    final isCurrentlyPage = _selectedIndex == 3;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Visibility(
              visible: !(isZoomed && isCurrentlyPage),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (playerState.showMiniPlayer) const MiniPlayer(),
                  Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.black.withOpacity(0.95),
                    ),
                    child: BottomNavigationBar(
                      currentIndex: _selectedIndex,
                      onTap: _onItemTapped,
                      backgroundColor: Colors.black.withOpacity(0.95),
                      selectedItemColor: const Color(0xFFFFD700), // Bright Gold
                      unselectedItemColor: AppColors.textSecondary,
                      type: BottomNavigationBarType.fixed,
                      elevation: 0,
                      iconSize: 28,
                      selectedFontSize: 14,
                      unselectedFontSize: 12,
                      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      items: [
                        BottomNavigationBarItem(
                            icon: const Icon(Icons.home_filled),
                            activeIcon: const GlowingActiveIcon(icon: Icons.home_filled),
                            label: notifier.t('الرئيسية', 'Home', 'Início', 'Accueil')),
                        BottomNavigationBarItem(
                            icon: const Icon(Icons.menu_book),
                            activeIcon: const GlowingActiveIcon(icon: Icons.menu_book),
                            label: notifier.t('تلاوات', 'Recitations', 'Recitações', 'Récitations')),
                        const BottomNavigationBarItem(
                          icon: PulsingTextIcon(),
                          activeIcon: PulsingTextIcon(),
                          label: '',
                        ),
                        BottomNavigationBarItem(
                          icon: const Icon(Icons.play_circle_filled, color: Colors.red),
                          activeIcon: const GlowingActiveIcon(icon: Icons.play_circle_filled, color: Colors.red),
                          label: notifier.t('حالياً', 'Now', 'Agora', 'Actuellement'),
                        ),
                        BottomNavigationBarItem(
                            icon: const PulsingDownloadIcon(),
                            activeIcon: const PulsingDownloadIcon(),
                            label: notifier.t('التحميلات', 'Downloads', 'Downloads', 'Téléchargements')),
                        BottomNavigationBarItem(
                            icon: const Icon(Icons.more_horiz),
                            activeIcon: const GlowingActiveIcon(icon: Icons.more_horiz),
                            label: notifier.t('المزيد', 'More', 'Mais', 'Plus')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class GlowingActiveIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const GlowingActiveIcon({super.key, required this.icon, this.color = const Color(0xFFFFD700)});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.2,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

class PulsingTextIcon extends StatefulWidget {
  const PulsingTextIcon({super.key});

  @override
  State<PulsingTextIcon> createState() => _PulsingTextIconState();
}

class _PulsingTextIconState extends State<PulsingTextIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Text(
              'مُضافة حديثاً',
              style: TextStyle(
                fontSize: 11 + 2 * _controller.value,
                fontWeight: FontWeight.bold,
                color: Color.lerp(
                    AppColors.gold, Colors.white, _controller.value),
              ),
            ),
            Positioned(
              top: -8,
              right: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: const Text('جديد',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const PulsingIcon({super.key, required this.icon, required this.color});

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + 0.2 * _controller.value,
          child: Icon(widget.icon,
              color: widget.color.withOpacity(0.6 + 0.4 * _controller.value)),
        );
      },
    );
  }
}

class HomeScreen extends ConsumerWidget {
  final Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(languageProvider.notifier);
    final downloads = ref.watch(downloadProvider);
    final activeDownload = ref.read(downloadProvider.notifier).activeDownload;

    return Container(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Hero Background
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsPage()));
                  },
                  child: SizedBox(
                    height: 400,
                    width: double.infinity,
                    child: Hero(
                      tag: 'reciter_image',
                      child: Image.asset(
                        'assets/images/reciter.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0x8808060A),
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: SizedBox(),
                ),
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: HeroTitleSection(),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: HeroControlsSection(onNavigate: onNavigate),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllSurahsPage(
                            title: notifier.t(
                                'جميع التلاوات',
                                'All Recitations',
                                'Ver Tudo',
                                'Toutes les récitions'),
                            allSurahs: surahList,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      notifier.t(
                          'عرض الكل', 'See All', 'Ver Tudo', 'Voir tout'),
                      style: GoogleFonts.amiri(
                          color: AppColors.gold, fontSize: 16),
                    ),
                  ),
                  Text(
                    notifier.t(
                        'مقترح لك', 'Recommended', 'Recomendado', 'Recommandé'),
                    style: GoogleFonts.amiri(
                      color: AppColors.gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),
          const SliverSuggestedList(),
        ],
      ),
    );
  }
}

class SliverSuggestedList extends ConsumerWidget {
  const SliverSuggestedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final recommended = ref.watch(homeRecommendationsProvider);
    
    if (recommended.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 150),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final surah = recommended[index];
            final isCurrent = playerState.currentSurah?.id == surah.id;

            return SurahItem(
              key: ValueKey('suggested_${surah.id}'), // Stable key
              surah: surah,
              index: index,
              isPlaying: isCurrent && playerState.isPlaying,
              onTap: () => playerNotifier.playSurah(surah, surahList),
            );
          },
          childCount: recommended.length,
        ),
      ),
    );
  }
}

extension on HomeScreen {
  void _playRandomSuggestion(BuildContext context, WidgetRef ref) {
    final content = ref.read(contentProvider);
    final allTracks = [
      ...surahList,
      ...content.telawat2026,
      ...content.azkar,
      ...content.doae,
      ...content.telawat2018,
      ...content.telawat2020,
      ...content.telawat2022,
      ...content.telawat2023,
      ...content.telawat2024,
      ...content.telawat2025,
      ...content.telawat2026Local,
    ];

    if (allTracks.isNotEmpty) {
      final randomTrack = allTracks[math.Random().nextInt(allTracks.length)];
      ref.read(playerProvider.notifier).playSurah(randomTrack, allTracks);

      final notifier = ref.read(languageProvider.notifier);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.gold,
          content: Text(
            '${notifier.t('اقتراح اليوم: ', 'Today\'s Suggestion: ', 'Sugestão de hoje: ', 'Suggestion du jour: ')}${randomTrack.name}',
            style: const TextStyle(
                color: AppColors.backgroundDefault,
                fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _showCompleteNotify(
      BuildContext context, WidgetRef ref, String surahId, Function(int) onNavigate) {
    final surah = [
      ...surahList,
      ...ref.read(contentProvider).telawat2026,
      ...ref.read(contentProvider).azkar,
      ...ref.read(contentProvider).doae,
      ...ref.read(contentProvider).telawat2018,
      ...ref.read(contentProvider).telawat2020,
      ...ref.read(contentProvider).telawat2022,
      ...ref.read(contentProvider).telawat2023,
      ...ref.read(contentProvider).telawat2024,
      ...ref.read(contentProvider).telawat2025,
      ...ref.read(contentProvider).telawat2026Local,
    ].firstWhere((s) => s.id == surahId);
    final notifier = ref.read(languageProvider.notifier);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.gold,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: notifier.t(
              'تشغيل الآن', 'Play Now', 'Tocar Agora', 'Jouer maintenant'),
          textColor: AppColors.backgroundDefault,
          onPressed: () {
            ref.read(playerProvider.notifier).playSurah(surah, [surah]);
            onNavigate(4);
          },
        ),
        content: Text(
          '${notifier.t('تم تحميل', 'Downloaded', 'Baixado', 'Téléchargé')}: ${notifier.translateSurahName(surah.name)}',
          style: const TextStyle(
              color: AppColors.backgroundDefault, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showLanguageSwitcher(BuildContext context, WidgetRef ref) {
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
            ListTile(
                title: const Text('العربية'),
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('ar');
                  Navigator.pop(context);
                }),
            ListTile(
                title: const Text('English'),
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('en');
                  Navigator.pop(context);
                }),
            ListTile(
                title: const Text('Português'),
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('pt');
                  Navigator.pop(context);
                }),
            ListTile(
                title: const Text('Français'),
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('fr');
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }
}

class HeroTitleSection extends ConsumerWidget {
  const HeroTitleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(languageProvider.notifier);

    String getGreeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) {
        return notifier.t('صباح الخير،', 'Good Morning,', 'Bom dia,', 'Bonjour,');
      } else if (hour < 18) {
        return notifier.t('مساء الخير،', 'Good Afternoon,', 'Boa tarde,', 'Bon après-midi,');
      } else {
        return notifier.t('طاب مساؤك،', 'Good Evening,', 'Boa noite,', 'Bonsoir,');
      }
    }

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            getGreeting(),
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
          Text(
            'حمزة مدبوح',
            style: GoogleFonts.amiri(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class HeroControlsSection extends ConsumerWidget {
  final Function(int)? onNavigate;
  const HeroControlsSection({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(languageProvider.notifier);
    final playerState = ref.watch(playerProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (playerState.currentSurah != null)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      notifier.translateSurahName(playerState.currentSurah!.name),
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    notifier.t(' - حالياً', ' - Now', ' - Agora', ' - Actuellement'),
                    style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  const PulsingDot(),
                ],
              ),
            )
          else
            const SizedBox(),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(ref: ref, onNavigate: onNavigate),
              );
            },
            icon: const Icon(Icons.search, color: AppColors.gold, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuranIndexPage()),
              );
            },
            icon: const PulsingIcon(
              icon: Icons.menu_book,
              color: AppColors.backgroundDefault,
            ),
            label: Text(notifier.t(
                'القرآن الكريم', 'The Holy Quran', 'O Alcorão Sagrado', 'Le Saint Coran'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.backgroundDefault,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: AppColors.gold, size: 24),
            onSelected: (lang) {
              ref.read(languageProvider.notifier).setLanguage(lang);
            },
            color: AppColors.surface,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ar', child: Text('العربية', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
    );
  }
}
