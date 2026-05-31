import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import '../../core/providers/advanced_settings_provider.dart';
import '../../core/constants/colors.dart';
import 'dart:async';

/// Optimized Engine for PDF-Based Mushaf with Real-Time Synchronization
class MushafPdfEngine extends ConsumerStatefulWidget {
  final int surahNumber;
  final Duration position;
  final List<dynamic> lrcLines;

  const MushafPdfEngine({
    super.key,
    required this.surahNumber,
    required this.position,
    required this.lrcLines,
  });

  @override
  ConsumerState<MushafPdfEngine> createState() => _MushafPdfEngineState();
}

class _MushafPdfEngineState extends ConsumerState<MushafPdfEngine> {
  PdfController? _pdfController;
  int _currentPageNumber = 1;
  bool _isPdfLoading = true;
  
  // Madinah Mushaf Page Offset
  // Adjust this based on your PDF (e.g., if page 1 of Mushaf is page 3 of PDF)
  static const int PDF_OFFSET = 0; 

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  @override
  void didUpdateWidget(MushafPdfEngine oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWithPlayback();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _initPdf() async {
    try {
      _pdfController = PdfController(
        document: PdfDocument.openAsset('assets/quran/quran.pdf'),
      );
      
      setState(() => _isPdfLoading = false);
      _syncWithPlayback();
    } catch (e) {
      debugPrint('Error loading local PDF: $e');
    }
  }

  void _syncWithPlayback() {
    if (widget.lrcLines.isEmpty || _pdfController == null) return;

    final foundIndex = widget.lrcLines.lastIndexWhere((line) => line.startTime <= widget.position);
    
    if (foundIndex != -1) {
      final entry = widget.lrcLines[foundIndex];
      final int apiVerseNum = entry.apiVerseIndex + 1;
      
      final int targetPage = _calculatePage(widget.surahNumber, apiVerseNum) + PDF_OFFSET;
      
      if (targetPage != _currentPageNumber) {
        _currentPageNumber = targetPage;
        _pdfController!.animateToPage(
          targetPage - 1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  int _calculatePage(int surah, int verse) {
    // Madinah Mushaf Mapping
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
    return surahStartPages[surah] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_isPdfLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          PdfView(
            controller: _pdfController!,
            scrollDirection: Axis.horizontal, // Paper-like flipping
            builders: PdfViewBuilders<DefaultBuilderOptions>(
              options: const DefaultBuilderOptions(),
              documentLoaderBuilder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
              pageLoaderBuilder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
            ),
          ),
          
          // Transparent Highlight Layer (Full-page subtle overlay for now)
          IgnorePointer(
            child: Container(
              color: Colors.black.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }
}
