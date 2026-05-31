import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/advanced_settings_provider.dart';
import '../../core/constants/colors.dart';

/// Optimized Engine for Image-Based Mushaf with Precise Highlighting
class MushafImageEngine extends ConsumerStatefulWidget {
  final int surahNumber;
  final Duration position;
  final List<dynamic> lrcLines; // Raw LRC entries

  const MushafImageEngine({
    super.key,
    required this.surahNumber,
    required this.position,
    required this.lrcLines,
  });

  @override
  ConsumerState<MushafImageEngine> createState() => _MushafImageEngineState();
}

class _MushafImageEngineState extends ConsumerState<MushafImageEngine>
    with TickerProviderStateMixin {
  // Page state
  int _currentPageNumber = 1;
  bool _isLoadingCoords = true;

  // Coordinate Mapping
  Map<int, List<VerseCoordinate>> _coordsMap = {};
  
  // Highlighting
  int _currentVerseInPage = -1;
  
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _loadCoordinates();
  }

  @override
  void didUpdateWidget(MushafImageEngine oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.surahNumber != widget.surahNumber) {
      _loadCoordinates();
    }
    
    _updateSync();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadCoordinates() async {
    try {
      setState(() => _isLoadingCoords = true);
      
      // Load from local asset
      final String content = await DefaultAssetBundle.of(context)
          .loadString('assets/json/verse_coordinates.json');
      
      final Map<String, dynamic> data = jsonDecode(content);
      final Map<String, dynamic> pages = data['pages'];
      
      Map<int, List<VerseCoordinate>> localMap = {};
      
      pages.forEach((key, value) {
        int pageNum = int.parse(key);
        List<VerseCoordinate> pageCoords = [];
        Map<String, dynamic> verses = value['verses'];
        
        verses.forEach((vKey, vVal) {
          pageCoords.add(VerseCoordinate(
            verseNumber: int.parse(vKey),
            x: vVal['x'],
            y: vVal['y'],
            width: vVal['width'],
            height: vVal['height'],
          ));
        });
        
        localMap[pageNum] = pageCoords;
      });

      setState(() {
        _coordsMap = localMap;
        _isLoadingCoords = false;
      });
      
      _updateSync();
    } catch (e) {
      debugPrint('Error loading coords: $e');
      setState(() => _isLoadingCoords = false);
    }
  }

  void _updateSync() {
    if (widget.lrcLines.isEmpty) return;

    // Find current index based on time
    final foundIndex = widget.lrcLines.lastIndexWhere((line) => line.startTime <= widget.position);
    
    if (foundIndex != -1) {
      final entry = widget.lrcLines[foundIndex];
      final int apiVerseNum = entry.apiVerseIndex + 1;
      
      // Update page number based on surah-page mapping (Madinah Mushaf)
      final int newPage = _calculatePage(widget.surahNumber, apiVerseNum);
      
      if (newPage != _currentPageNumber) {
        setState(() {
          _currentPageNumber = newPage;
        });
        _preCache(newPage);
      }
      
      if (apiVerseNum != _currentVerseInPage) {
        setState(() {
          _currentVerseInPage = apiVerseNum;
        });
        _glowController.forward(from: 0.0);
      }
    }
  }

  int _calculatePage(int surah, int verse) {
    // Basic Madinah Mushaf mapping
    const surahStartPages = {
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
    
    // Average verses per page for rough estimation if exact mapping missing
    // In production, we'd use a verse-to-page JSON
    final startPage = surahStartPages[surah] ?? 1;
    if (surah == 1) return 1;
    if (surah == 2 && verse <= 5) return 2;
    
    return startPage; // Placeholder logic
  }

  void _preCache(int current) {
    for (int i = 1; i <= 3; i++) {
      if (current + i <= 604) {
        CachedNetworkImageProvider('https://image.qurancdn.com/v3/qdc-cms/images/${current + i}.png');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCoords) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    // Try a more reliable CDN if the primary fails
    final imageUrl = 'https://image.qurancdn.com/v3/qdc-cms/images/$_currentPageNumber.png';
    final fallbackUrl = 'https://quran.ksu.edu.sa/images/png/$_currentPageNumber.png';

    final pageCoords = _coordsMap[_currentPageNumber];
    VerseCoordinate? activeCoord;
    
    if (pageCoords != null) {
      activeCoord = pageCoords.firstWhere(
        (c) => c.verseNumber == _currentVerseInPage,
        orElse: () => pageCoords.isNotEmpty ? pageCoords.first : VerseCoordinate(verseNumber: 0, x: 0, y: 0, width: 0, height: 0),
      );
    }

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // The Real Page Image with retry logic and fallback URL
          Center(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              errorWidget: (context, url, error) {
                debugPrint('Primary image load failed, trying fallback: $fallbackUrl');
                return CachedNetworkImage(
                  imageUrl: fallbackUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                  errorWidget: (context, url, error) => const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.grey, size: 50),
                      SizedBox(height: 10),
                      Text('فشل تحميل صفحة المصحف', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // The Highlight Overlay
          if (activeCoord != null && activeCoord.width > 0)
            Positioned.fill(
              child: CustomPaint(
                painter: ImageMushafHighlightPainter(
                  coord: activeCoord,
                  animation: _glowAnimation,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class VerseCoordinate {
  final int verseNumber;
  final double x;
  final double y;
  final double width;
  final double height;

  VerseCoordinate({
    required this.verseNumber,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class ImageMushafHighlightPainter extends CustomPainter {
  final VerseCoordinate coord;
  final Animation<double> animation;

  ImageMushafHighlightPainter({
    required this.coord,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF808080).withOpacity(0.35 * animation.value) // Transparent Gray
      ..style = PaintingStyle.fill;

    // Convert normalized (0-1) coordinates to screen pixels
    final rect = Rect.fromLTWH(
      coord.x * size.width,
      coord.y * size.height,
      coord.width * size.width,
      coord.height * size.height,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );
    
    // Subtle border for definition
    final borderPaint = Paint()
      ..color = Colors.black12.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ImageMushafHighlightPainter oldDelegate) {
    return oldDelegate.coord != coord || oldDelegate.animation.value != animation.value;
  }
}
