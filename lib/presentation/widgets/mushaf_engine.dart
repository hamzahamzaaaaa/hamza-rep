import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdfx/pdfx.dart';
import '../../core/providers/advanced_settings_provider.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

// ============================================================================
// MUSHAF ENGINE - PDF-based Quran Page Viewer
// ============================================================================

class LrcEntry {
  final Duration timestamp;
  final int verseNumber;
  final String verseText;
  final int pageNumber;

  LrcEntry({
    required this.timestamp,
    required this.verseNumber,
    required this.verseText,
    required this.pageNumber,
  });

  @override
  String toString() {
    return 'LrcEntry(time: ${timestamp.inSeconds}s, verse: $verseNumber, page: $pageNumber)';
  }
}

class VerseHighlightBox {
  final double x; // Relative (0.0 - 1.0)
  final double y; // Relative (0.0 - 1.0)
  final double width; // Relative (0.0 - 1.0)
  final double height; // Relative (0.0 - 1.0)
  final List<WordHighlightBox>? words; // Feature 5: Word-level coordinates

  VerseHighlightBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.words,
  });
}

/// Feature 5: Word-level highlight box
class WordHighlightBox {
  final int wordIndex;
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;

  WordHighlightBox({
    required this.wordIndex,
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

// ============================================================================
// MAIN WIDGET
// ============================================================================

class MushafEngine extends StatefulWidget {
  final String surahId;
  final String? lrcUrl;
  final Duration position; // Current playback position
  final String? surahName; // Added for backward compatibility

  const MushafEngine({
    super.key,
    required this.surahId,
    this.lrcUrl,
    required this.position,
    this.surahName, // Optional parameter
  });

  @override
  State<MushafEngine> createState() => _MushafEngineState();
}

class _MushafEngineState extends State<MushafEngine>
    with TickerProviderStateMixin {
  // Loading states
  bool _isLrcLoading = true;
  String? _errorDetails;
  bool _lrcLoadFailed = false;

  // LRC synchronization data
  List<LrcEntry> _lrcEntries = [];
  int _activeVerseIndex = -1;
  
  // Feature 3: Coordinate mapping from JSON
  Map<String, Map<String, VerseHighlightBox>> _coordinateMap = {}; // {"pageNumber": {"verseNumber": box}}
  bool _isCoordinateMapLoaded = false;

  // PDF viewer data
  int _displayedPageNumber = 1;
  PdfController? _pdfController;
  int _pdfPageCount = 0;
  bool _isPdfLoaded = false; // Track if PDF is fully loaded

  // Image dimensions for responsive scaling
  Size? _pdfPageSize; // PDF page size (will be calculated)
  Rect? _pdfRenderedRect; // Actual rendered PDF rect on screen

  // Golden highlight animation
  late AnimationController _pulseController;
  late Animation<double> _pulseEffect;
  
  // Smooth interpolation for highlight transitions
  late AnimationController _interpolationController;
  late Animation<double> _highlightOpacity;
  VerseHighlightBox? _previousHighlightBox;
  VerseHighlightBox? _currentHighlightBox;
  VerseHighlightBox? _displayedHighlightBox; // For smooth transitions

  // Time sync & header configuration
  static const double syncDelay = -5.0;
  static const double bismillahDuration = 10.0;
  bool _isInBismillahPhase = true;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseEffect = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Initialize smooth interpolation controller
    _interpolationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // Smooth transition duration
    );
    _highlightOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _interpolationController, curve: Curves.easeInOut),
    );
    
    _interpolationController.forward(from: 0.0);
    
    // Load coordinate mapping (Feature 3)
    _loadCoordinateMapping();

    _initializeEngine();
  }

  @override
  void didUpdateWidget(MushafEngine oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.surahId != widget.surahId ||
        oldWidget.lrcUrl != widget.lrcUrl) {
      _initializeEngine();
      setState(() {
        _activeVerseIndex = -1;
        _displayedPageNumber = 1;
        _pdfController = null;
        _lrcLoadFailed = false;
        _isInBismillahPhase = true;
      });
    }

    _syncWithPlayback();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _interpolationController.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  // ============================================================================
  // LRC LOADING & PARSING
  // ============================================================================
  
  /// Feature 3: Load coordinate mapping from JSON
  Future<void> _loadCoordinateMapping() async {
    try {
      final jsonString = await rootBundle.loadString('assets/json/verse_coordinates.json');
      final jsonData = jsonDecode(jsonString);
      
      final pages = jsonData['pages'] as Map<String, dynamic>;
      final Map<String, Map<String, VerseHighlightBox>> coordMap = {};
      
      for (var entry in pages.entries) {
        final pageNumber = entry.key;
        final pageData = entry.value;
        final verses = pageData['verses'] as Map<String, dynamic>;
        
        final Map<String, VerseHighlightBox> verseMap = {};
        for (var verseEntry in verses.entries) {
          final verseNumber = verseEntry.key;
          final verseData = verseEntry.value;
          
          // Feature 5: Load word-level mapping if available
          List<WordHighlightBox>? wordBoxes;
          if (jsonData['wordLevelMapping'] != null) {
            final wordKey = '${pageNumber}_$verseNumber';
            if (jsonData['wordLevelMapping'][wordKey] != null) {
              final wordData = jsonData['wordLevelMapping'][wordKey]['words'] as List;
              wordBoxes = wordData.map((w) => WordHighlightBox(
                wordIndex: w['wordIndex'] as int,
                text: w['text'] as String,
                x: (w['x'] as num).toDouble(),
                y: (w['y'] as num).toDouble(),
                width: (w['width'] as num).toDouble(),
                height: (w['height'] as num).toDouble(),
              )).toList();
            }
          }
          
          verseMap[verseNumber] = VerseHighlightBox(
            x: (verseData['x'] as num).toDouble(),
            y: (verseData['y'] as num).toDouble(),
            width: (verseData['width'] as num).toDouble(),
            height: (verseData['height'] as num).toDouble(),
            words: wordBoxes,
          );
        }
        
        coordMap[pageNumber] = verseMap;
      }
      
      setState(() {
        _coordinateMap = coordMap;
        _isCoordinateMapLoaded = true;
      });
      
      print('✅ Loaded coordinate mapping for ${coordMap.length} pages');
    } catch (e) {
      print('⚠️ Coordinate mapping load failed: $e');
      setState(() {
        _isCoordinateMapLoaded = false;
      });
    }
  }
  
  /// Feature 3: Get highlight box from coordinate mapping
  VerseHighlightBox? _getCoordinateFromMap(int pageNumber, int verseNumber) {
    if (!_isCoordinateMapLoaded) return null;
    
    final pageKey = pageNumber.toString();
    final verseKey = verseNumber.toString();
    
    if (_coordinateMap.containsKey(pageKey)) {
      return _coordinateMap[pageKey]?[verseKey];
    }
    
    return null;
  }

  Future<void> _initializeEngine() async {
    try {
      setState(() {
        _isLrcLoading = true;
        _errorDetails = null;
        _lrcLoadFailed = false;
      });

      String? lrcContent;
      
      if (widget.lrcUrl != null && widget.lrcUrl!.startsWith('http')) {
        lrcContent = await _loadLrcWithCaching(widget.lrcUrl!);
      } else {
        lrcContent = await _loadFromLocalAssets(widget.surahId);
      }

      if (lrcContent != null && lrcContent.isNotEmpty) {
        final parsedEntries = _convertLrcToPaper(lrcContent);
        
        setState(() {
          _lrcEntries = parsedEntries;
          _isLrcLoading = false;
          _lrcLoadFailed = false;
        });

        if (parsedEntries.isNotEmpty) {
          _navigateToPage(parsedEntries.first.pageNumber);
        }
      } else {
        setState(() {
          _isLrcLoading = false;
          _lrcLoadFailed = true;
          _lrcEntries = [];
        });
        
        final surahNumber = _parseSurahNumber();
        if (surahNumber != null) {
          const surahStartingPages = {
            1: 1, 2: 2, 3: 50, 4: 77, 5: 106, 6: 128, 7: 151, 8: 177, 9: 187,
            10: 208, 11: 221, 12: 235, 13: 249, 14: 255, 15: 262, 16: 267, 17: 282,
            18: 293, 19: 305, 20: 312, 21: 322, 22: 332, 23: 342, 24: 350, 25: 359,
            26: 367, 27: 377, 28: 385, 29: 396, 30: 404, 31: 411, 32: 415, 33: 418,
            34: 428, 35: 434, 36: 440, 37: 446, 38: 453, 39: 458, 40: 467, 41: 477,
            42: 483, 43: 489, 44: 496, 45: 499, 46: 502, 47: 507, 48: 511, 49: 515,
            50: 518, 51: 520, 52: 523, 53: 526, 54: 528, 55: 531, 56: 534, 57: 537,
            58: 542, 59: 545, 60: 549, 61: 551, 62: 553, 63: 554, 64: 556, 65: 558,
            66: 560, 67: 562, 68: 564, 69: 566, 70: 568, 71: 570, 72: 572, 73: 574,
            74: 575, 75: 577, 76: 578, 77: 580, 78: 582, 79: 583, 80: 585, 81: 586,
            82: 587, 83: 587, 84: 589, 85: 590, 86: 591, 87: 591, 88: 592, 89: 593,
            90: 594, 91: 595, 92: 595, 93: 596, 94: 596, 95: 597, 96: 597, 97: 598,
            98: 598, 99: 599, 100: 599, 101: 600, 102: 600, 103: 601, 104: 601,
            105: 601, 106: 602, 107: 602, 108: 602, 109: 603, 110: 603, 111: 603,
            112: 604, 113: 604, 114: 604,
          };
          final startPage = surahStartingPages[surahNumber] ?? 1;
          _navigateToPage(startPage);
        }
      }

    } catch (e) {
      setState(() {
        _isLrcLoading = false;
        _lrcLoadFailed = true;
        _errorDetails = 'Failed to initialize: $e';
      });
    }
  }

  // ============================================================================
  // PDF NAVIGATION
  // ============================================================================

  Future<void> _navigateToPage(int pageNum) async {
    try {
      print('📖 PDF: Navigating to page $pageNum');
      
      // Initialize PDF controller if not already done
      if (_pdfController == null) {
        print('📦 PDF: Initializing controller from assets/pdf/quran.pdf');
        
        final pdfDocument = await PdfDocument.openAsset('assets/pdf/quran.pdf');
        
        _pdfController = PdfController(
          document: Future.value(pdfDocument),
        );
        
        _pdfPageCount = pdfDocument.pagesCount;
        _isPdfLoaded = true;
        
        print('✅ PDF: Loaded with $_pdfPageCount pages');
      }
      
      // Wait for PDF to be loaded before navigating
      if (!_isPdfLoaded) {
        print('⏳ PDF: Waiting for PDF to load...');
        return;
      }
      
      setState(() {
        _displayedPageNumber = pageNum;
        _pdfPageSize = null;
        _pdfRenderedRect = null;
      });
      
      // Safe navigation - controller is guaranteed to be non-null here
      final controller = _pdfController;
      if (controller != null) {
        controller.animateToPage(
          pageNum,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        
        print('🎯 PDF: Navigated to page $pageNum');
      }
      
    } catch (e) {
      print('❌ PDF ERROR: Failed to load page $pageNum: $e');
      setState(() {
        _errorDetails = 'Failed to load PDF: $e';
      });
    }
  }

  // ============================================================================
  // SYNC ENGINE
  // ============================================================================

  void _syncWithPlayback() {
    if (_lrcEntries.isEmpty) return;

    // Apply user-defined offset from settings (Feature 2: Live Offset Adjustment)
    final adjustedPosition = widget.position + Duration(seconds: syncDelay.toInt());
    
    if (adjustedPosition.inSeconds < bismillahDuration) {
      if (!_isInBismillahPhase) {
        setState(() {
          _isInBismillahPhase = true;
          _activeVerseIndex = -1;
        });
      }
      return;
    } else {
      if (_isInBismillahPhase) {
        setState(() {
          _isInBismillahPhase = false;
        });
      }
    }

    int newIndex = -1;
    for (int i = 0; i < _lrcEntries.length; i++) {
      if (_lrcEntries[i].timestamp <= adjustedPosition) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _activeVerseIndex) {
      // Feature 1: Smooth Interpolation - Store previous position
      _previousHighlightBox = _computeHighlightBox();
      
      setState(() {
        _activeVerseIndex = newIndex;
      });
      
      _pulseController.forward(from: 0.0);
      
      // Trigger smooth interpolation
      _currentHighlightBox = _computeHighlightBox();
      _interpolationController.forward(from: 0.0);

      if (newIndex >= 0 && newIndex < _lrcEntries.length) {
        final targetPage = _lrcEntries[newIndex].pageNumber;
        if (targetPage != _displayedPageNumber) {
          _navigateToPage(targetPage);
        }
      }
    }
  }

  VerseHighlightBox? _computeHighlightBox() {
    if (_isInBismillahPhase) {
      return VerseHighlightBox(
        x: 0.25,
        y: 0.05,
        width: 0.50,
        height: 0.04,
      );
    }
    
    if (_activeVerseIndex < 0 || _activeVerseIndex >= _lrcEntries.length) {
      return null;
    }

    final activeVerse = _lrcEntries[_activeVerseIndex];
    
    // Feature 3: Try to get coordinates from JSON mapping first
    final mappedCoords = _getCoordinateFromMap(activeVerse.pageNumber, activeVerse.verseNumber);
    if (mappedCoords != null) {
      return mappedCoords;
    }
    
    // Fallback to calculated coordinates
    final verseIndexOnPage = _lrcEntries
        .where((e) => e.pageNumber == activeVerse.pageNumber)
        .toList()
        .indexWhere((e) => e.verseNumber == activeVerse.verseNumber);
    
    if (verseIndexOnPage < 0) return null;
    
    const textAreaStartY = 0.10;
    const textAreaEndY = 0.90;
    const textAreaHeight = textAreaEndY - textAreaStartY;
    
    const totalLinesPerPage = 15;
    
    final lineIndex = (verseIndexOnPage / 2).floor() % totalLinesPerPage;
    final linePositionRatio = lineIndex / totalLinesPerPage;
    final relativeY = textAreaStartY + (linePositionRatio * textAreaHeight);
    
    final isRightColumn = verseIndexOnPage % 2 == 0;
    const lineWidth = 0.42;
    final relativeX = isRightColumn ? 0.52 : 0.06;
    
    final lineHeight = (textAreaHeight / totalLinesPerPage) * 0.70;

    return VerseHighlightBox(
      x: relativeX,
      y: relativeY,
      width: lineWidth,
      height: lineHeight,
    );
  }
  
  /// Feature 1: Get interpolated highlight box for smooth transitions
  VerseHighlightBox? _getInterpolatedHighlightBox() {
    if (_previousHighlightBox == null || _currentHighlightBox == null) {
      return _currentHighlightBox ?? _previousHighlightBox;
    }
    
    final t = _highlightOpacity.value; // Interpolation factor (0.0 to 1.0)
    
    return VerseHighlightBox(
      x: _previousHighlightBox!.x + (_currentHighlightBox!.x - _previousHighlightBox!.x) * t,
      y: _previousHighlightBox!.y + (_currentHighlightBox!.y - _previousHighlightBox!.y) * t,
      width: _previousHighlightBox!.width + (_currentHighlightBox!.width - _previousHighlightBox!.width) * t,
      height: _previousHighlightBox!.height + (_currentHighlightBox!.height - _previousHighlightBox!.height) * t,
    );
  }

  String _getCurrentVerseText() {
    if (_activeVerseIndex < 0 || _activeVerseIndex >= _lrcEntries.length) {
      return '';
    }
    return _lrcEntries[_activeVerseIndex].verseText;
  }

  // ============================================================================
  // UI RENDERING
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        if (_isLrcLoading) {
          return _buildLoadingScreen();
        }

        if (_errorDetails != null && !_lrcLoadFailed) {
          return _buildErrorScreen();
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Stack(
            children: [
              _buildPdfViewer(),

              if (_activeVerseIndex >= 0 && !_lrcLoadFailed)
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        painter: GoldenSyncPainter(
                          highlightBox: _computeHighlightBox(),
                          pulseAnimation: _pulseEffect,
                          pdfPageSize: _pdfPageSize,
                          containerSize: Size(constraints.maxWidth, constraints.maxHeight),
                        ),
                      );
                    },
                  ),
                ),

              if (_activeVerseIndex >= 0 && _lrcEntries.isNotEmpty && !_lrcLoadFailed)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildLyricsOverlay(ref),
                ),
              
              if (_lrcLoadFailed && _lrcEntries.isEmpty)
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildFallbackIndicator(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB8860B)),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'جاري تحميل المصحف...',
              style: TextStyle(
                color: Color(0xFFB8860B),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, color: Color(0xFFB8860B), size: 64),
              const SizedBox(height: 16),
              Text(
                _errorDetails!,
                style: const TextStyle(color: Color(0xFFB8860B), fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB8860B).withOpacity(0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_bolt, color: Color(0xFFB8860B), size: 16),
          SizedBox(width: 8),
          Text(
            'وضع القراءة اليدوية',
            style: TextStyle(
              color: Color(0xFFB8860B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    // Safe check - don't use ! operator
    final controller = _pdfController;
    
    if (controller == null || !_isPdfLoaded) {
      // Show loading indicator while PDF is loading
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
              ),
              SizedBox(height: 16),
              Text(
                'جاري تحميل صفحة المصحف...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // PDF is loaded - display it full screen with white background
    return Container(
      color: Colors.white,
      child: PdfView(
        controller: controller, // Safe - already checked above
        scrollDirection: Axis.vertical,
        onPageChanged: (page) {
          setState(() {
            _displayedPageNumber = page;
          });
        },
      ),
    );
  }

  Widget _buildLyricsOverlay(WidgetRef ref) {
    final currentVerseText = _getCurrentVerseText();
    if (currentVerseText.isEmpty) return const SizedBox.shrink();

    final settings = ref.watch(advancedSettingsProvider);
    final fontColor = _hexToColor(settings.syncFontColorHex);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.85),
            Colors.black.withOpacity(0.95),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentVerseText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 26,
                height: 1.8,
                color: fontColor,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ).copyWith(
                fontFamilyFallback: const ['Noto Sans Arabic', 'Arial'],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'صفحة $_displayedPageNumber',
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  int? _parseSurahNumber() {
    final match = RegExp(r'(\d+)').firstMatch(widget.surahId);
    return match != null ? int.parse(match.group(1)!) : null;
  }

  // ============================================================================
  // LRC PARSING & LOADING (Keep existing implementation)
  // ============================================================================

  Future<String?> _loadLrcWithCaching(String githubUrl) async {
    try {
      final cachedContent = await _loadLrcFromCache(widget.surahId);
      if (cachedContent != null && cachedContent.isNotEmpty) {
        return cachedContent;
      }

      final rawUrl = _convertToRawGitHubUrl(githubUrl);

      final response = await http.get(
        Uri.parse(rawUrl),
        headers: {
          'User-Agent': 'Medbouh-Quran-App/1.0',
          'Accept': 'text/plain, */*',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        if (content.isNotEmpty) {
          await _saveLrcToCache(widget.surahId, content);
          return content;
        }
      }
    } catch (e) {
      print('⚠️ LRC download failed: $e');
    }

    return await _loadFromLocalAssets(widget.surahId);
  }

  Future<String?> _loadFromLocalAssets(String surahId) async {
    try {
      final byteData = await rootBundle.load('assets/lyrics/$surahId.lrc');
      return utf8.decode(byteData.buffer.asUint8List());
    } catch (e) {
      try {
        final match = RegExp(r'surah_(\d+)').firstMatch(surahId);
        if (match != null) {
          final surahNum = match.group(1);
          final byteData = await rootBundle.load('assets/lyrics/surah_$surahNum.lrc');
          return utf8.decode(byteData.buffer.asUint8List());
        }
      } catch (_) {}
      return null;
    }
  }

  Future<String?> _loadLrcFromCache(String surahId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'lrc_cache_$surahId';
      final cachedJson = prefs.getString(key);
      
      if (cachedJson != null) {
        final data = json.decode(cachedJson);
        final content = data['content'] as String;
        final timestamp = data['timestamp'] as int;
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        
        if (age < 7 * 24 * 60 * 60 * 1000) {
          return content;
        }
      }
    } catch (e) {}
    return null;
  }

  Future<void> _saveLrcToCache(String surahId, String content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'lrc_cache_$surahId';
      final data = {
        'content': content,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(key, json.encode(data));
    } catch (e) {}
  }

  String _convertToRawGitHubUrl(String url) {
    if (url.contains('github.com') && url.contains('/blob/')) {
      return url
          .replaceFirst('github.com', 'raw.githubusercontent.com')
          .replaceFirst('/blob/', '/');
    }
    return url;
  }

  List<LrcEntry> _convertLrcToPaper(String lrcContent) {
    final entries = <LrcEntry>[];
    final lines = lrcContent.split('\n');

    for (final line in lines) {
      final match = RegExp(r'\[(\d{2}):(\d{2}\.\d{2})\](.*)').firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final text = match.group(3)!.trim();

        if (text.isNotEmpty) {
          final timestamp = Duration(
            minutes: minutes,
            seconds: seconds.floor(),
            milliseconds: ((seconds - seconds.floor()) * 1000).round(),
          );

          final verseMatch = RegExp(r'﴿.*?﴾|(\d+)').firstMatch(text);
          final verseNumber = verseMatch != null && verseMatch.group(1) != null
              ? int.parse(verseMatch.group(1)!)
              : entries.length + 1;

          final pageNumber = _calculatePageNumber(verseNumber);

          entries.add(LrcEntry(
            timestamp: timestamp,
            verseNumber: verseNumber,
            verseText: text,
            pageNumber: pageNumber,
          ));
        }
      }
    }

    return entries;
  }

  int _calculatePageNumber(int verseNum) {
    final surahNumber = _parseSurahNumber();
    if (surahNumber == null) return 1;

    const surahStartingPages = {
      1: 1, 2: 2, 3: 50, 4: 77, 5: 106, 6: 128, 7: 151, 8: 177, 9: 187,
      10: 208, 11: 221, 12: 235, 13: 249, 14: 255, 15: 262, 16: 267, 17: 282,
      18: 293, 19: 305, 20: 312, 21: 322, 22: 332, 23: 342, 24: 350, 25: 359,
      26: 367, 27: 377, 28: 385, 29: 396, 30: 404, 31: 411, 32: 415, 33: 418,
      34: 428, 35: 434, 36: 440, 37: 446, 38: 453, 39: 458, 40: 467, 41: 477,
      42: 483, 43: 489, 44: 496, 45: 499, 46: 502, 47: 507, 48: 511, 49: 515,
      50: 518, 51: 520, 52: 523, 53: 526, 54: 528, 55: 531, 56: 534, 57: 537,
      58: 542, 59: 545, 60: 549, 61: 551, 62: 553, 63: 554, 64: 556, 65: 558,
      66: 560, 67: 562, 68: 564, 69: 566, 70: 568, 71: 570, 72: 572, 73: 574,
      74: 575, 75: 577, 76: 578, 77: 580, 78: 582, 79: 583, 80: 585, 81: 586,
      82: 587, 83: 587, 84: 589, 85: 590, 86: 591, 87: 591, 88: 592, 89: 593,
      90: 594, 91: 595, 92: 595, 93: 596, 94: 596, 95: 597, 96: 597, 97: 598,
      98: 598, 99: 599, 100: 599, 101: 600, 102: 600, 103: 601, 104: 601,
      105: 601, 106: 602, 107: 602, 108: 602, 109: 603, 110: 603, 111: 603,
      112: 604, 113: 604, 114: 604,
    };

    final basePage = surahStartingPages[surahNumber] ?? 1;
    const averageVersesPerPage = 15.0;
    final extraPages = (verseNum / averageVersesPerPage).floor();
    return (basePage + extraPages).clamp(1, 604);
  }
}

// ============================================================================
// GOLDEN SYNC PAINTER
// ============================================================================

class GoldenSyncPainter extends CustomPainter {
  final VerseHighlightBox? highlightBox;
  final Animation<double> pulseAnimation;
  final Size? pdfPageSize;
  final Size containerSize;

  GoldenSyncPainter({
    required this.highlightBox,
    required this.pulseAnimation,
    this.pdfPageSize,
    required this.containerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (highlightBox == null) return;

    final pulseValue = pulseAnimation.value;

    Rect pdfRect;
    
    if (pdfPageSize != null && pdfPageSize!.width > 0 && pdfPageSize!.height > 0) {
      final pdfAspectRatio = pdfPageSize!.width / pdfPageSize!.height;
      final containerAspectRatio = containerSize.width / containerSize.height;
      
      double scale;
      if (pdfAspectRatio > containerAspectRatio) {
        scale = containerSize.width / pdfPageSize!.width;
      } else {
        scale = containerSize.height / pdfPageSize!.height;
      }
      
      final scaledWidth = pdfPageSize!.width * scale;
      final scaledHeight = pdfPageSize!.height * scale;
      
      final offsetX = (containerSize.width - scaledWidth) / 2;
      final offsetY = (containerSize.height - scaledHeight) / 2;
      
      pdfRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
    } else {
      pdfRect = Rect.fromLTWH(0, 0, containerSize.width, containerSize.height);
    }

    final highlightRect = Rect.fromLTWH(
      pdfRect.left + (highlightBox!.x * pdfRect.width),
      pdfRect.top + (highlightBox!.y * pdfRect.height),
      highlightBox!.width * pdfRect.width,
      highlightBox!.height * pdfRect.height,
    );

    final roundedRect = RRect.fromRectAndRadius(
      highlightRect,
      const Radius.circular(6),
    );

    final baseLayer = Paint()
      ..color = Colors.amber.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(roundedRect, baseLayer);

    final gradientLayer = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFFFFD700).withAlpha((40 * pulseValue).round()),
          const Color(0xFFFFEC8B).withAlpha((70 * pulseValue).round()),
          const Color(0xFFFFD700).withAlpha((40 * pulseValue).round()),
        ],
      ).createShader(highlightRect);

    canvas.drawRRect(roundedRect, gradientLayer);

    final shineLayer = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withAlpha((30 * pulseValue).round()),
          Colors.transparent,
        ],
      ).createShader(highlightRect);

    canvas.drawRRect(roundedRect, shineLayer);

    final borderLayer = Paint()
      ..color = const Color(0xFFFFD700).withAlpha((150 * pulseValue).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(roundedRect, borderLayer);

    final shadowLayer = Paint()
      ..color = const Color(0xFFFFD700).withAlpha((50 * pulseValue).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawRRect(roundedRect.inflate(2), shadowLayer);
  }

  @override
  bool shouldRepaint(covariant GoldenSyncPainter oldDelegate) {
    return oldDelegate.highlightBox != highlightBox ||
        oldDelegate.pulseAnimation.value != pulseAnimation.value ||
        oldDelegate.pdfPageSize != pdfPageSize ||
        oldDelegate.containerSize != containerSize;
  }
}
