import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/models/surah.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/advanced_settings_provider.dart';
import '../widgets/mushaf_settings_panel.dart';
import '../widgets/quick_index_overlay.dart';
import '../widgets/sync_settings_bottom_sheet.dart';

/// ============================================================================
/// SMART MUSHAF PAGE - تجربة المصحف الورقي الكاملة
/// ============================================================================
/// 
/// Features:
/// - تصميم المصحف الحقيقي (سيبيا، إطارات إسلامية)
/// - تظليل الآيات مع مزامنة الصوت
/// - إعدادات التخصيص (التعتيم، لون الورق، الخطوط)
/// - تحكم ذكي بالشاشة

class SmartMushafPage extends ConsumerStatefulWidget {
  final Surah surah;
  final List<Surah> playlist;

  const SmartMushafPage({
    super.key,
    required this.surah,
    required this.playlist,
  });

  @override
  ConsumerState<SmartMushafPage> createState() => _SmartMushafPageState();
}

class _SmartMushafPageState extends ConsumerState<SmartMushafPage> {
  // ── LRC (Timing Engine) ──────────────────────────────────────────────────
  List<LrcEntry> lrcLines = [];
  final List<GlobalKey> _verseKeys = [];

  /// The index of the currently highlighted verse.
  int _activeVerseIndex = -1;
  bool _isLoadingLrc = true;
  final ScrollController _scrollController = ScrollController();

  // ── API Verse Text (Uthmanic Script) ─────────────────────────────────────
  List<String> _apiVerseTexts = [];  // empty = API not loaded yet

  // Tracks the last position we synced so we skip redundant work
  final Duration _lastSyncedPosition = const Duration(seconds: -1);

  // Display settings
  bool _showControls = true;
  Timer? _hideTimer;
  
  // Paper customization
  Color _paperColor = const Color(0xFF001219); // Deep Midnight Blue
  double _fontSize = 32.0;
  String _fontName = 'Amiri';
  double _opacity = 1.0;

  bool _showQuickIndex = false;
  
  // Offset correction for sync (in milliseconds)
  int syncOffsetMs = -500; // Subtracts 500ms from current time to prevent early jumping

  late Surah _currentSurah;

  @override
  void initState() {
    super.initState();
    _currentSurah = widget.surah;
    _loadLrc();
    _startAutoHideTimer();
  }

  @override
  void didUpdateWidget(SmartMushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dynamic Loading - Clear old data when surah changes
    if (oldWidget.surah.id != widget.surah.id) {
      _currentSurah = widget.surah;
      setState(() {
        lrcLines.clear();
        _apiVerseTexts.clear();
        _activeVerseIndex = -1;
        _isLoadingLrc = true;
      });
      _loadLrc();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load LRC synchronization data AND Quran verse text from alquran.cloud
  Future<void> _loadLrc() async {
    if (_currentSurah.lrcUrl == null || _currentSurah.lrcUrl!.isEmpty) {
      setState(() => _isLoadingLrc = false);
      return;
    }

    try {
      // ── Step 1: Load LRC file as timing engine ──────────────────────────
      String content;
      if (_currentSurah.lrcUrl!.startsWith('http')) {
        final response = await http.get(Uri.parse(_currentSurah.lrcUrl!));
        content = utf8.decode(response.bodyBytes);
      } else {
        final byteData = await rootBundle.load(_currentSurah.lrcUrl!);
        content = utf8.decode(byteData.buffer.asUint8List());
      }

      final entries = _parseLRC(content);

      // ── Step 2: Fetch verified Uthmanic text from alquran.cloud ─────────
      final surahNum = _currentSurah.mushafIndex;
      List<String> apiTexts = [];

      if (surahNum < 999) {
        try {
          final apiUrl =
              'https://api.alquran.cloud/v1/surah/$surahNum/quran-uthmani';
          final apiResp = await http.get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 8));

          if (apiResp.statusCode == 200) {
            final decoded = jsonDecode(utf8.decode(apiResp.bodyBytes));
            final ayahs = decoded['data']['ayahs'] as List<dynamic>;
            // Retrieve full surah verses without any slicing
            apiTexts = ayahs.map<String>((a) => a['text'] as String).toList();
          }
        } catch (apiErr) {
          debugPrint('alquran.cloud API error: $apiErr — falling back to LRC text');
        }
      }

      // Feature 1 & 3: Grouping Logic & Index Mapping
      // Match each LRC line to the correct API verse using text analysis
      if (apiTexts.isNotEmpty) {
        _mapLrcToApiVerses(entries, apiTexts);
      } else {
        // Fallback if offline
        for (int i = 0; i < entries.length; i++) {
          entries[i].apiVerseIndex = i;
        }
      }

      // CRITICAL FIX: The user wants long verses to be highlighted PART BY PART.
      // We will NO LONGER merge the LRC entries into a single group.
      // Instead, each LRC line (segment) will be its own highlight block.
      
      _verseKeys.clear();
      for (int i = 0; i < entries.length; i++) {
        _verseKeys.add(GlobalKey());
      }

      setState(() {
        lrcLines = entries; // Use the raw segments as requested
        _apiVerseTexts = apiTexts;
        _isLoadingLrc = false;
      });
    } catch (e) {
      debugPrint('Error loading LRC: $e');
      setState(() => _isLoadingLrc = false);
    }
  }

  List<LrcEntry> _groupLrcByVerse(List<LrcEntry> entries) {
    if (entries.isEmpty) return [];
    
    List<LrcEntry> grouped = [];
    int currentApiIndex = -1;
    LrcEntry? currentGroup;

    for (var entry in entries) {
      if (entry.apiVerseIndex != currentApiIndex) {
        if (currentGroup != null) {
          grouped.add(currentGroup);
        }
        currentApiIndex = entry.apiVerseIndex;
        currentGroup = LrcEntry(
          startTime: entry.startTime,
          verseText: entry.verseText,
          verseNumber: entry.verseNumber,
          apiVerseIndex: entry.apiVerseIndex,
        );
      } else if (currentGroup != null) {
        currentGroup = LrcEntry(
          startTime: currentGroup.startTime,
          verseText: '${currentGroup.verseText} ${entry.verseText}'.trim(),
          verseNumber: currentGroup.verseNumber,
          apiVerseIndex: currentGroup.apiVerseIndex,
        );
      }
    }
    
    if (currentGroup != null) {
      grouped.add(currentGroup);
    }
    return grouped;
  }

  /// Normalizes Arabic text for accurate matching (removes tashkeel, standardizes letters)
  String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u0617-\u061A\u064B-\u0652\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]'), '') // Remove Tashkeel
        .replaceAll(RegExp(r'[ٱأإآ]'), 'ا') // Normalize Alif
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ء', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\d+'), '') // Remove any digits (line numbers)
        // CRITICAL FIX: \w removes Arabic! Use Unicode block \u0621-\u064A for Arabic letters.
        .replaceAll(RegExp(r'[^\u0621-\u064A\s]'), '') 
        .trim();
  }

  /// Intelligently links LRC sub-timings to the correct API Verse
  void _mapLrcToApiVerses(List<LrcEntry> entries, List<String> apiTexts) {
    if (apiTexts.isEmpty || entries.isEmpty) return;

    List<String> normApi = apiTexts.map((e) => _normalizeArabic(e)).toList();
    int currentApiIndex = 0;

    for (var entry in entries) {
      String normLrc = _normalizeArabic(entry.verseText);
      
      if (normLrc.isEmpty) {
        entry.apiVerseIndex = currentApiIndex;
        continue;
      }

      bool found = false;
      // 1. Strict substring match
      for (int i = currentApiIndex; i < normApi.length; i++) {
        if (normApi[i].contains(normLrc) || normLrc.contains(normApi[i])) {
          currentApiIndex = i;
          found = true;
          break;
        }
      }

      // 2. Word intersection (match significant words)
      if (!found) {
        final lrcWords = normLrc.split(' ');
        for (int i = currentApiIndex; i < normApi.length; i++) {
           final apiWords = normApi[i].split(' ');
           for (var w in lrcWords) {
             // length >= 2 to catch short verses like "طه"
             if (w.length >= 2 && apiWords.contains(w)) {
                currentApiIndex = i;
                found = true;
                break;
             }
           }
           if (found) break;
        }
      }

      entry.apiVerseIndex = currentApiIndex;
    }
  }

  /// Parse LRC content
  List<LrcEntry> _parseLRC(String content) {
    final entries = <LrcEntry>[];
    final lines = content.split('\n');
    final RegExp timeRegex = RegExp(r'\[(\d{1,2}):(\d{1,2})[.:](\d{1,3})\](.*)');

    for (final line in lines) {
      final match = timeRegex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisText = match.group(3)!;
        String rawText = match.group(4)!.trim();

        int milliseconds = int.parse(millisText);
        if (millisText.length == 1) milliseconds *= 100;
        if (millisText.length == 2) milliseconds *= 10;
        final time = Duration(minutes: minutes, seconds: seconds, milliseconds: milliseconds);

        // Clean text for display (remove brackets and leading numbers)
        String cleanText = rawText
            .replaceAll(RegExp(r'[﴿\(\[\{٭]\s*\d+\s*[﴾\)\]\}٭]'), '')
            .replaceAll(RegExp(r'^\d+\s*'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        entries.add(LrcEntry(
          startTime: time,
          verseText: cleanText,
          verseNumber: 0, // Deprecated, using apiVerseIndex instead
          apiVerseIndex: 0, // Will be intelligently assigned by _mapLrcToApiVerses
        ));
      }
    }

    return entries;
  }

  void _startAutoHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startAutoHideTimer();
    }
  }

  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MushafSettingsPanel(
        currentPaperColor: _paperColor,
        currentFontSize: _fontSize,
        currentFontName: _fontName,
        currentOpacity: _opacity,
        onPaperColorChanged: (color) {
          setState(() => _paperColor = color);
        },
        onFontSizeChanged: (size) {
          setState(() => _fontSize = size);
        },
        onFontNameChanged: (name) {
          setState(() => _fontName = name);
        },
        onOpacityChanged: (opacity) {
          setState(() => _opacity = opacity);
        },
      ),
    );
  }

  /// Conditional Scrolling: scroll only if activeVerseIndex changes.
  void _scrollToActiveVerse() {
    if (!_scrollController.hasClients || lrcLines.isEmpty || _activeVerseIndex < 0) return;
    
    // FEATURE 1: Fixed Viewport Logic (Second/Third Line Rule)
    // We use GlobalKeys to find the exact position of the active verse container
    if (_activeVerseIndex < _verseKeys.length) {
      final context = _verseKeys[_activeVerseIndex].currentContext;
      if (context != null) {
        // alignment: 0.15 ensures the active item is placed at 15% from the top
        // which is roughly the second or third line of the screen.
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 700),
          alignment: 0.15,
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);

    // ── STRICT REAL-TIME SYNC ──────────────────────────────────────────────
    ref.listen<Duration>(
      playerProvider.select((s) => s.position),
      (previous, currentPosition) {
        if (mounted && lrcLines.isNotEmpty) {
          final effectivePosition = currentPosition + Duration(milliseconds: syncOffsetMs);
          
          // ابحث في كامل القائمة في كل مرة لضمان عدم التجمد
          final foundIndex = lrcLines.lastIndexWhere((line) => line.startTime <= effectivePosition);
          
          if (foundIndex != -1) {
            // معالجة الفهارس (Index Alignment) للحفاظ على التجميع
            final activeVerseIndex = foundIndex; // Since grouped, index is the verse
            
            if (activeVerseIndex != _activeVerseIndex) {
              setState(() {
                _activeVerseIndex = activeVerseIndex;
              });
              // تفعيل التمرير القسري واللحظي
              _scrollToActiveVerse();
            }
          }
        }
      },
    );

    // ── STATE REFRESH ON SURAH CHANGE ─────────────────────────────────────
    ref.listen<Surah?>(
      playerProvider.select((s) => s.currentSurah),
      (previous, current) {
        if (current != null && mounted) {
          if (_currentSurah.id != current.id) {
            _currentSurah = current;
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              );
            }
            setState(() {
              lrcLines.clear();
              _apiVerseTexts.clear();
              _activeVerseIndex = -1;
              _isLoadingLrc = true;
            });
            _loadLrc();
          }
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Positioned.fill(
              child: _isLoadingLrc
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : _buildMushafPage(),
            ),

            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),

            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomControls(playerState),
              ),

            if (_showQuickIndex)
              QuickIndexOverlay(
                surahs: widget.playlist,
                onSurahSelected: (surah) {
                  ref.read(playerProvider.notifier).playSurah(surah, widget.playlist);
                  setState(() => _showQuickIndex = false);
                },
                onClose: () => setState(() => _showQuickIndex = false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMushafPage() {
    final settings = ref.watch(advancedSettingsProvider);
    final pageColor = Color(int.parse(settings.mushafPageColorHex.replaceFirst('#', '0xFF')));

    return Container(
      color: pageColor.withOpacity(_opacity),
      child: SafeArea(
        child: Column(
          children: [
            if (_showControls) _buildSurahHeader(),
            
            const SizedBox(height: 10),
            
            Expanded(
              child: lrcLines.isEmpty
                  ? Center(
                      child: Text(
                        'لا تتوفر مزامنة الآية لهذه السورة',
                        style: GoogleFonts.amiri(
                          fontSize: _fontSize,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: _buildFlowingText(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahHeader() {
    final settings = ref.watch(advancedSettingsProvider);
    final barColor = Color(int.parse(settings.mushafBarColorHex.replaceFirst('#', '0xFF')));
    final textColor = Color(int.parse(settings.mushafVerseTextColorHex.replaceFirst('#', '0xFF')));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Index button
              GestureDetector(
                onTap: () => setState(() => _showQuickIndex = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: barColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_rounded, color: barColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'السور',
                        style: GoogleFonts.amiri(
                          color: barColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Right side: Surah Name
              Text(
                _currentSurah.name,
                style: GoogleFonts.amiri(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 1.5,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  barColor.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build flowing text with verses. 
  /// Displays structured blocks for perfect multi-line highlighting.
  Widget _buildFlowingText() {
    final settings = ref.watch(advancedSettingsProvider);
    final highlightColor = Color(int.parse(settings.mushafVerseHighlightColorHex.replaceFirst('#', '0xFF')));
    final textColor = Color(int.parse(settings.mushafVerseTextColorHex.replaceFirst('#', '0xFF')));
    final barColor = Color(int.parse(settings.mushafBarColorHex.replaceFirst('#', '0xFF')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(lrcLines.length, (i) {
        final isActive = i == _activeVerseIndex;
        
        // FEATURE 4: Deep Highlight Logic (Solid block for multi-line support)
        final Color bgColor = isActive
            ? highlightColor.withOpacity(0.85) // High density deep highlight
            : Colors.transparent;

        return AnimatedContainer(
          key: _verseKeys[i],
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            // Suble border when active to enhance depth
            border: Border.all(
              color: isActive ? highlightColor.withOpacity(0.5) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RichText(
                textAlign: lrcLines[i].verseText.split(' ').length > 4 
                    ? TextAlign.justify 
                    : TextAlign.center,
                textDirection: TextDirection.rtl,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${lrcLines[i].verseText} ',
                      style: _getFontStyle(isActive).copyWith(
                        color: isActive 
                            ? (highlightColor.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                            : textColor.withOpacity(0.9),
                        wordSpacing: 0,
                        letterSpacing: 0,
                      ),
                    ),
                    
                    // Verse Number Logic
                    // Show number if it's the end of an API verse
                    if (i == lrcLines.length - 1 || lrcLines[i].apiVerseIndex != lrcLines[i + 1].apiVerseIndex)
                      TextSpan(
                        text: ' \ufd3f${lrcLines[i].apiVerseIndex + 1}\ufd3e ',
                        style: GoogleFonts.amiri(
                          fontSize: _fontSize * 0.75,
                          color: isActive 
                              ? (highlightColor.computeLuminance() > 0.5 ? Colors.black45 : Colors.white60)
                              : barColor.withOpacity(0.6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  TextStyle _getFontStyle(bool isActive) {
    TextStyle style;
    
    // Default base style with no spacing to force Kashida usage by the font engine
    final baseStyle = TextStyle(
      height: 1.8,
      wordSpacing: 0,
      letterSpacing: 0,
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    );

    switch (_fontName) {
      case 'Cairo':
        style = GoogleFonts.cairo(
          textStyle: baseStyle.copyWith(fontSize: _fontSize),
        );
        break;
      case 'Noto Naskh Arabic':
        style = GoogleFonts.notoNaskhArabic(
          textStyle: baseStyle.copyWith(fontSize: _fontSize, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal),
        );
        break;
      case 'Scheherazade New':
        style = GoogleFonts.scheherazadeNew(
          textStyle: baseStyle.copyWith(fontSize: _fontSize, fontWeight: isActive ? FontWeight.w700 : FontWeight.normal),
        );
        break;
      case 'UthmanTaha':
        style = baseStyle.copyWith(
          fontFamily: 'UthmanTaha',
          fontSize: _fontSize,
        );
        break;
      default: // Amiri
        style = GoogleFonts.amiri(
          textStyle: baseStyle.copyWith(fontSize: _fontSize),
        );
    }

    return style;
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            
            const SizedBox(width: 4),

            // Redesigned Swar Button to prevent overlap
            GestureDetector(
              onTap: () => setState(() => _showQuickIndex = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book, color: AppColors.gold, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'السور',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),
            
            Text(
              _currentSurah.name,
              style: GoogleFonts.amiri(
                color: AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(width: 12),

            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70, size: 22),
              onPressed: _showSettingsPanel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(PlayerState playerState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── NEW: Transparent Seek Bar ───
            _buildProgressBar(playerState),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                _buildMiniWaveform(playerState.isPlaying),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentSurah.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'مزامنة الآية الحية',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Playback Controls Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
                      onPressed: () => ref.read(playerProvider.notifier).prevSurah(),
                    ),
                    IconButton(
                      icon: Icon(
                        playerState.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: AppColors.gold,
                        size: 44,
                      ),
                      onPressed: () => ref.read(playerProvider.notifier).togglePlay(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                      onPressed: () => ref.read(playerProvider.notifier).nextSurah(),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // Secondary Controls Row: Repeat, Hifz Help, Offset
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    playerState.isRepeat ? Icons.repeat_one : Icons.repeat,
                    color: playerState.isRepeat ? AppColors.gold : Colors.white70,
                    size: 22,
                  ),
                  onPressed: () => ref.read(playerProvider.notifier).toggleRepeat(),
                ),
                
                TextButton.icon(
                  onPressed: () {
                    showSyncSettingsBottomSheet(context, ref);
                  },
                  icon: const Icon(Icons.psychology_alt, color: AppColors.gold, size: 20),
                  label: const Text(
                    'مساعد الحفظ',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history, color: Colors.white60, size: 22),
                      onPressed: () => setState(() => syncOffsetMs -= 100),
                    ),
                    Text(
                      '${syncOffsetMs}ms',
                      style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.update, color: Colors.white60, size: 22),
                      onPressed: () => setState(() => syncOffsetMs += 100),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(PlayerState state) {
    final double progress = state.duration.inMilliseconds > 0
        ? (state.position.inMilliseconds / state.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: AppColors.gold,
            overlayColor: AppColors.gold.withOpacity(0.2),
          ),
          child: Slider(
            value: progress,
            onChanged: (value) {
              final target = Duration(milliseconds: (value * state.duration.inMilliseconds).toInt());
              ref.read(playerProvider.notifier).seek(target);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(state.position), style: const TextStyle(color: Colors.white70, fontSize: 10)),
              Text(_formatDuration(state.duration), style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildMiniWaveform(bool isPlaying) {
    return SizedBox(
      width: 24,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          return _WaveformBar(
            isPlaying: isPlaying,
            index: index,
          );
        }),
      ),
    );
  }
}

class LrcEntry {
  final Duration startTime;
  final String verseText;
  final int verseNumber;
  int apiVerseIndex;

  LrcEntry({
    required this.startTime,
    required this.verseText,
    required this.verseNumber,
    this.apiVerseIndex = 0,
  });
}

class _WaveformBar extends StatefulWidget {
  final bool isPlaying;
  final int index;

  const _WaveformBar({
    required this.isPlaying,
    required this.index,
  });

  @override
  State<_WaveformBar> createState() => _WaveformBarState();
}

class _WaveformBarState extends State<_WaveformBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + widget.index * 100),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_WaveformBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 3,
          height: 8 + (_animation.value * 12),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
