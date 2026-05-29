import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:pdfx/pdfx.dart';
import '../../core/providers/advanced_settings_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// ============================================================================
// MUSHAF PDF ENGINE - Online PDF Viewer with LRC Synchronization
// ============================================================================
// 
// ARCHITECTURE:
// - Loads Quran PDF directly from archive.org URL
// - Uses pdfx library for online viewing (no full download needed)
// - LRC synchronization with page offset adjustment
// - Golden highlight overlay on PDF pages
// - Linear progress indicator for loading state
//
// PDF SOURCE:
// - URL: https://ia801506.us.archive.org/3/items/arabic-568335686835685363568q3an1/arabic-quran2.pdf
// - High-quality scanned Mushaf from archive.org
// - Pages include intro pages (offset adjustment needed)
//
// PAGE OFFSET:
// - PDF includes cover + intro pages before actual Mushaf
// - LRC page 1 = PDF page 3 (example: offset = 2)
// - Configurable via PDF_PAGE_OFFSET constant
// - Adjust based on where actual Mushaf starts in PDF
//
// LIBRARY:
// - Uses pdfx: ^2.8.0 (lightweight, no conflicts)
// - PdfView for rendering
// - PdfController for navigation
// - 0-based page indexing (convert to 1-based for LRC)
//
// LOADING STATES:
// - Loading: Golden LinearProgressIndicator at top
// - Error: Golden cloud_off + "تحقق من الاتصال" message
// - Retry: Re-initializes PDF loading
//
// NETWORK REQUIREMENTS:
// - Internet required for first load
// - PDF streams progressively (no full download)
// - Offline: PDF not cached by default (streams each time)
//
// ============================================================================

/// Page offset to align LRC pages with PDF pages
/// Adjust this value based on where the actual Mushaf starts in the PDF
const int PDF_PAGE_OFFSET = 2; // Example: LRC page 1 = PDF page 3

class MushafPdfEngine extends ConsumerStatefulWidget {
  /// Surah identifier for LRC loading
  final String surahId;
  
  /// Current playback position from audio stream
  final Duration position;
  
  /// LRC file URL (HTTP or local asset)
  final String? lrcUrl;
  
  /// Surah display name
  final String surahName;

  const MushafPdfEngine({
    super.key,
    required this.surahId,
    required this.position,
    this.lrcUrl,
    required this.surahName,
  });

  @override
  ConsumerState<MushafPdfEngine> createState() => _MushafPdfEngineState();
}

class _MushafPdfEngineState extends ConsumerState<MushafPdfEngine> with SingleTickerProviderStateMixin {
  // ============================================================================
  // STATE MANAGEMENT
  // ============================================================================
  
  // Loading states
  bool _isPdfLoading = true;
  bool _isLrcLoading = true;
  String? _errorDetails;
  double? _loadProgress; // 0.0 to 1.0

  // PDF Viewer controller
  PdfController? _pdfController;

  // LRC synchronization data
  List<LrcEntry> _lrcEntries = [];
  int _activeVerseIndex = -1;
  int _currentPageNumber = 1;

  // Golden highlight animation
  late AnimationController _pulseController;
  late Animation<double> _pulseEffect;

  // PDF URL
  final String _pdfUrl = 'https://ia801506.us.archive.org/3/items/arabic-568335686835685363568q3an1/arabic-quran2.pdf';

  // Dio instance for LRC downloads
  late final Dio _dio;

  // ============================================================================
  // PDF DOWNLOAD AND CACHING
  // ============================================================================

  /// Download PDF to local cache for pdfx library
  Future<File> _downloadPdfToCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final pdfFile = File('${tempDir.path}/quran_mushaf.pdf');
      
      // Download if not exists
      if (!await pdfFile.exists()) {
        await _dio.download(
          _pdfUrl,
          pdfFile.path,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              setState(() {
                _loadProgress = received / total;
              });
            }
          },
        );
      }
      
      return pdfFile;
    } catch (e) {
      throw Exception('Failed to download PDF: $e');
    }
  }

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void initState() {
    super.initState();
    
    // Initialize Dio for LRC downloads
    _dio = Dio(BaseOptions(
      headers: {
        'User-Agent': 'Medbouh-Quran-App/1.0',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
    
    // Setup pulse animation for golden highlight
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseEffect = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize engine
    _initializeEngine();
  }

  @override
  void didUpdateWidget(MushafPdfEngine oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload when surah changes
    if (oldWidget.surahId != widget.surahId ||
        oldWidget.lrcUrl != widget.lrcUrl) {
      _initializeEngine();
      setState(() {
        _activeVerseIndex = -1;
        _currentPageNumber = 1;
      });
    }

    // Sync with playback position in real-time
    _syncWithPlayback();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  // ============================================================================
  // LRC LOADING AND PARSING
  // ============================================================================

  /// Initialize the Mushaf PDF Engine
  Future<void> _initializeEngine() async {
    try {
      setState(() {
        _isLrcLoading = true;
        _isPdfLoading = true;
        _errorDetails = null;
      });

      // Load LRC content
      String? lrcContent;

      if (widget.lrcUrl != null && widget.lrcUrl!.startsWith('http')) {
        lrcContent = await _downloadFromNetwork(widget.lrcUrl!);
      } else {
        lrcContent = await _loadFromLocalAssets(widget.surahId);
      }

      if (lrcContent == null || lrcContent.isEmpty) {
        throw Exception('LRC data is empty or unavailable');
      }

      // Parse LRC and convert to page mapping
      final parsedEntries = _convertLrcToPaper(lrcContent);

      setState(() {
        _lrcEntries = parsedEntries;
        _isLrcLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLrcLoading = false;
        _errorDetails = 'Failed to load LRC: $e';
      });
    }
  }

  /// Download LRC from network URL
  Future<String?> _downloadFromNetwork(String url) async {
    try {
      final response = await _dio.get(url);
      return response.data.toString();
    } catch (e) {
      throw Exception('Network download failed: $e');
    }
  }

  /// Load LRC from local Flutter assets
  Future<String?> _loadFromLocalAssets(String surahId) async {
    try {
      return await DefaultAssetBundle.of(context)
          .loadString('assets/lyrics/$surahId.lrc');
    } catch (e) {
      // Try alternative naming convention
      try {
        final match = RegExp(r'surah_(\d+)').firstMatch(surahId);
        if (match != null) {
          final surahNum = match.group(1);
          return await DefaultAssetBundle.of(context)
              .loadString('assets/lyrics/surah_$surahNum.lrc');
        }
      } catch (_) {}
      return null;
    }
  }

  /// Convert LRC timestamps to paper page mapping
  List<LrcEntry> _convertLrcToPaper(String content) {
    final RegExp timestampPattern = RegExp(
      r'\[(\d{1,2}):(\d{1,2})[.:](\d{1,3})\](.*)',
    );
    final List<LrcEntry> entries = [];
    int verseCounter = 1;

    final surahNumber = _parseSurahNumber();

    for (final line in content.split('\n')) {
      final match = timestampPattern.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisText = match.group(3)!;
        final verseText = match.group(4)!.trim();

        if (verseText.isNotEmpty) {
          int milliseconds = int.parse(millisText);
          if (millisText.length == 1) milliseconds *= 100;
          if (millisText.length == 2) milliseconds *= 10;

          final pageNum = _mapVerseToPaperPage(surahNumber, verseCounter);

          entries.add(LrcEntry(
            timestamp: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: milliseconds,
            ),
            verseText: verseText,
            verseNumber: verseCounter,
            pageNumber: pageNum,
          ));

          verseCounter++;
        }
      }
    }

    return entries;
  }

  /// Extract surah number from identifier
  int? _parseSurahNumber() {
    final match = RegExp(r'surah_(\d+)').firstMatch(widget.surahId);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  /// Map verse number to mushaf page
  int _mapVerseToPaperPage(int? surahNumber, int verseNum) {
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
    final calculatedPage = basePage + extraPages;
    
    return calculatedPage.clamp(1, 604);
  }

  // ============================================================================
  // REAL-TIME SYNC ENGINE
  // ============================================================================

  /// Synchronize golden highlight with audio playback
  void _syncWithPlayback() {
    if (_lrcEntries.isEmpty) return;

    int newIndex = -1;
    for (int i = 0; i < _lrcEntries.length; i++) {
      if (_lrcEntries[i].timestamp <= widget.position) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _activeVerseIndex) {
      setState(() {
        _activeVerseIndex = newIndex;
      });
      
      _pulseController.forward(from: 0.0);

      // Navigate to correct PDF page with offset
      if (newIndex >= 0 && newIndex < _lrcEntries.length) {
        final lrcPage = _lrcEntries[newIndex].pageNumber;
        final pdfPage = lrcPage + PDF_PAGE_OFFSET; // Apply offset
        
        if (pdfPage != _currentPageNumber) {
          _navigateToPdfPage(pdfPage);
        }
      }
    }
  }

  /// Navigate to specific PDF page
  Future<void> _navigateToPdfPage(int pageNumber) async {
    try {
      if (_pdfController != null) {
        await _pdfController!.animateToPage(
          pageNumber - 1, // pdfx uses 0-based index
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPageNumber = pageNumber;
        });
      }
    } catch (e) {
      // Navigation failed - non-critical
    }
  }

  /// Get current verse text
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
        // Error state
        if (_errorDetails != null) {
          return _buildErrorScreen();
        }

        // Full-screen PDF viewer with golden sync
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Stack(
            children: [
              // Layer 1: PDF Viewer using pdfx
              FutureBuilder<File>(
                future: _downloadPdfToCache(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFB8860B),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    setState(() {
                      _isPdfLoading = false;
                      _errorDetails = 'يرجى التحقق من الاتصال لعرض المصحف الورقي';
                    });
                    return const SizedBox.shrink();
                  }

                  if (snapshot.hasData) {
                    final pdfFile = snapshot.data!;
                    _pdfController = PdfController(
                      document: PdfDocument.openFile(pdfFile.path),
                    );

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _isPdfLoading = false;
                      });
                    });

                    return PdfView(
                      controller: _pdfController!,
                      onPageChanged: (page) {
                        setState(() {
                          _currentPageNumber = page + 1; // Convert 0-based to 1-based
                        });
                      },
                      scrollDirection: Axis.vertical,
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

              // Layer 2: Linear Progress Indicator (Golden)
              if (_isPdfLoading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _loadProgress,
                    backgroundColor: Colors.black,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB8860B)),
                    minHeight: 3,
                  ),
                ),

              // Layer 3: Golden highlight overlay on PDF
              if (_activeVerseIndex >= 0)
                Positioned.fill(
                  child: CustomPaint(
                    painter: PdfGoldenSyncPainter(
                      pulseAnimation: _pulseEffect,
                    ),
                  ),
                ),

              // Layer 4: Lyrics overlay at bottom
              if (_activeVerseIndex >= 0 && _lrcEntries.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildLyricsOverlay(ref),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Error screen with golden theme
  Widget _buildErrorScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: Color(0xFFB8860B),
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'يرجى التحقق من الاتصال لعرض المصحف الورقي',
                style: TextStyle(
                  color: Color(0xFFB8860B),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorDetails = null;
                    _isPdfLoading = true;
                  });
                  _initializeEngine();
                },
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8860B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build lyrics overlay with synchronized highlighting
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
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'صفحة PDF: ${_currentPageNumber - PDF_PAGE_OFFSET}',
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

  /// Convert hex color string to Color object
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

// ============================================================================
// DATA MODEL
// ============================================================================

class LrcEntry {
  final Duration timestamp;
  final String verseText;
  final int verseNumber;
  final int pageNumber;

  LrcEntry({
    required this.timestamp,
    required this.verseText,
    required this.verseNumber,
    required this.pageNumber,
  });
}

// ============================================================================
// CUSTOM PAINTER: PDF GOLDEN HIGHLIGHT
// ============================================================================

class PdfGoldenSyncPainter extends CustomPainter {
  final Animation<double> pulseAnimation;

  PdfGoldenSyncPainter({
    required this.pulseAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pulseValue = pulseAnimation.value;

    // Draw subtle golden overlay on entire page
    final overlay = Paint()
      ..color = Colors.amber.withOpacity(0.05 * pulseValue)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      overlay,
    );
  }

  @override
  bool shouldRepaint(covariant PdfGoldenSyncPainter oldDelegate) {
    return oldDelegate.pulseAnimation.value != pulseAnimation.value;
  }
}
