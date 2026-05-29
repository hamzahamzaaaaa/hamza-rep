import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/advanced_settings_provider.dart';
import 'mushaf_engine.dart';

/// ============================================================================
/// REUSABLE MUSHAF OVERLAY WITH FROSTED GLASS LYRICS
/// ============================================================================
/// 
/// This widget provides a globally reusable mushaf overlay that can be injected
/// into any player screen. It features:
/// - Full-screen MushafEngine as base layer
/// - Frosted glass lyrics overlay at the bottom
/// - Automatic LRC synchronization
/// - Golden highlighting on both paper and text
/// - Clean separation from player controls

class MushafOverlay extends ConsumerWidget {
  /// Surah identifier for LRC loading
  final String surahId;
  
  /// Current playback position from audio stream
  final Duration position;
  
  /// LRC file URL (HTTP or local asset)
  final String? lrcUrl;
  
  /// Surah display name
  final String surahName;
  
  /// Whether to show frosted glass lyrics overlay
  final bool showLyricsOverlay;

  const MushafOverlay({
    super.key,
    required this.surahId,
    required this.position,
    this.lrcUrl,
    required this.surahName,
    this.showLyricsOverlay = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(advancedSettingsProvider);
    
    // Don't render if mushaf view is disabled
    if (!settings.showMushafView) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Layer 1: Full-screen MushafEngine (base layer)
        Positioned.fill(
          child: MushafEngine(
            surahId: surahId,
            position: position,
            lrcUrl: lrcUrl,
            surahName: surahName,
          ),
        ),

        // Layer 2: Frosted glass lyrics overlay (optional)
        if (showLyricsOverlay)
          Positioned.fill(
            child: Stack(
              children: [
                // Transparent area at top (allows seeing mushaf)
                const SizedBox.expand(),
                
                // Frosted glass panel at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildFrostedGlassLyrics(ref),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build frosted glass lyrics overlay
  Widget _buildFrostedGlassLyrics(WidgetRef ref) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.85),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFFFD700).withOpacity(0.4),
                width: 2,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current verse indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الآية الحالية',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: const Color(0xFFFFD700).withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Current verse text with golden glow
                Consumer(
                  builder: (context, ref, child) {
                    // This will be updated by MushafEngine's internal sync
                    // For now, we show a placeholder that matches the style
                    final settings = ref.watch(advancedSettingsProvider);
                    final fontColor = _hexToColor(settings.syncFontColorHex);
                    
                    return Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 24,
                        height: 1.8,
                        color: fontColor,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
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
