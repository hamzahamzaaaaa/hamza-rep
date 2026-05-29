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
import '../widgets/mushaf_settings_panel.dart';

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

  /// The index of the currently highlighted verse.
  int _activeVerseIndex = -1;
  bool _isLoadingLrc = true;
  final ScrollController _scrollController = ScrollController();

  // ── API Verse Text (Uthmanic Script) ─────────────────────────────────────
  List<String> _apiVerseTexts = [];  // empty = API not loaded yet

  // Tracks the last position we synced so we skip redundant work
  Duration _lastSyncedPosition = const Duration(seconds: -1);

  // Display settings
  bool _showControls = true;
  Timer? _hideTimer;
  
  // Paper customization
  Color _paperColor = const Color(0xFFF5E6D3); // Sepia
  double _fontSize = 32.0;
  String _fontName = 'Amiri';
  double _opacity = 1.0;
  
  // Offset correction for sync (in milliseconds)
  int syncOffsetMs = -500; // Subtracts 500ms from current time to prevent early jumping

  @override
  void initState() {
    super.initState();
    _loadLrc();
    _startAutoHideTimer();
  }

  @override
  void didUpdateWidget(SmartMushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Feature 3: Dynamic Loading - Clear old data when surah changes
    if (oldWidget.surah.id != widget.surah.id) {
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
    if (widget.surah.lrcUrl == null || widget.surah.lrcUrl!.isEmpty) {
      setState(() => _isLoadingLrc = false);
      return;
    }

    try {
      // ── Step 1: Load LRC file as timing engine ──────────────────────────
      String content;
      if (widget.surah.lrcUrl!.startsWith('http')) {
        final response = await http.get(Uri.parse(widget.surah.lrcUrl!));
        content = utf8.decode(response.bodyBytes);
      } else {
        final byteData = await rootBundle.load(widget.surah.lrcUrl!);
        content = utf8.decode(byteData.buffer.asUint8List());
      }

      final entries = _parseLRC(content);

      // ── Step 2: Fetch verified Uthmanic text from alquran.cloud ─────────
      final surahNum = widget.surah.mushafIndex;
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

      setState(() {
        lrcLines = entries;
        _apiVerseTexts = apiTexts;
        _isLoadingLrc = false;
      });
    } catch (e) {
      debugPrint('Error loading LRC: $e');
      setState(() => _isLoadingLrc = false);
    }
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
    _hideTimer = Timer(const Duration(seconds: 5), () {
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
    
    // We now scroll based on the number of actual verses, not LRC entries
    final totalVerses = _apiVerseTexts.isNotEmpty ? _apiVerseTexts.length : lrcLines.last.apiVerseIndex + 1;
    if (totalVerses <= 0) return;
    
    final fraction = _activeVerseIndex / totalVerses;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetScroll = (fraction * maxScroll).clamp(0.0, maxScroll);
    
    _scrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
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
            final activeVerseIndex = lrcLines[foundIndex].apiVerseIndex;
            
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
          ],
        ),
      ),
    );
  }

  Widget _buildMushafPage() {
    return Container(
      color: _paperColor.withOpacity(_opacity),
      child: SafeArea(
        child: Column(
          children: [
            _buildSurahHeader(),
            
            const SizedBox(height: 20),
            
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _buildFlowingText(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: const Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 10),
              Container(
                width: 100,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFFD4AF37),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.auto_awesome, color: const Color(0xFFD4AF37), size: 20),
            ],
          ),
          const SizedBox(height: 15),
          
          Text(
            widget.surah.name,
            style: GoogleFonts.amiri(
              fontSize: _fontSize + 8,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Build flowing text with verses. 
  /// Displays full verses instead of LRC sub-timings.
  Widget _buildFlowingText() {
    final List<InlineSpan> spans = [];
    
    // Consolidate texts: Use API text if available, else reconstruct from LRC lines
    final List<String> displayVerses = [];
    if (_apiVerseTexts.isNotEmpty) {
      displayVerses.addAll(_apiVerseTexts);
    } else {
      Map<int, String> lrcVerses = {};
      for (var line in lrcLines) {
        if (line.apiVerseIndex >= 0) {
          final prefix = lrcVerses.containsKey(line.apiVerseIndex) ? lrcVerses[line.apiVerseIndex]! + ' ' : '';
          lrcVerses[line.apiVerseIndex] = prefix + line.verseText;
        }
      }
      final maxIndex = lrcVerses.keys.isNotEmpty ? lrcVerses.keys.reduce((a, b) => a > b ? a : b) : -1;
      for (int i = 0; i <= maxIndex; i++) {
        displayVerses.add(lrcVerses[i]?.trim() ?? '');
      }
    }

    for (int i = 0; i < displayVerses.length; i++) {
      final isActive = i == _activeVerseIndex;
      final Color bgColor = isActive
          ? const Color(0xFFFFD700).withOpacity(0.4)
          : Colors.transparent;

      spans.add(
        TextSpan(
          text: '${displayVerses[i]} ',
          style: _getFontStyle(isActive).copyWith(
            backgroundColor: bgColor,
            color: isActive ? const Color(0xFFB8860B) : Colors.black87,
          ),
        ),
      );

      spans.add(
        TextSpan(
          text: '\ufd3f${i + 1}\ufd3e ',
          style: GoogleFonts.amiri(
            fontSize: _fontSize * 0.85,
            color: isActive ? const Color(0xFFB8860B) : const Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return RichText(
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: const TextStyle(height: 2.0),
        children: spans,
      ),
    );
  }

  TextStyle _getFontStyle(bool isActive) {
    TextStyle style;
    
    switch (_fontName) {
      case 'Cairo':
        style = GoogleFonts.cairo(
          fontSize: _fontSize,
          height: 1.8,
          color: isActive ? Colors.black : Colors.black87,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        );
        break;
      case 'Noto Naskh Arabic':
        style = GoogleFonts.notoNaskhArabic(
          fontSize: _fontSize,
          height: 1.8,
          color: isActive ? Colors.black : Colors.black87,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        );
        break;
      case 'Scheherazade New':
        style = GoogleFonts.scheherazadeNew(
          fontSize: _fontSize,
          height: 1.8,
          color: isActive ? Colors.black : Colors.black87,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
        );
        break;
      default: // Amiri
        style = GoogleFonts.amiri(
          fontSize: _fontSize,
          height: 1.8,
          color: isActive ? Colors.black : Colors.black87,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        );
    }

    return style;
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            
            const Spacer(),
            
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.gold),
              onPressed: _showSettingsPanel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(PlayerState playerState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildMiniWaveform(playerState.isPlaying),
                const SizedBox(width: 10),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'حالياً: ',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.surah.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'مزامنة الآية',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
                  onPressed: () {
                    ref.read(playerProvider.notifier).prevSurah();
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    playerState.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: AppColors.gold,
                    size: 48,
                  ),
                  onPressed: () {
                    ref.read(playerProvider.notifier).togglePlay();
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
                  onPressed: () {
                    ref.read(playerProvider.notifier).nextSurah();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
