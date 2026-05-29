import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/download_provider_stub.dart'
    if (dart.library.io) '../../core/providers/download_provider_io.dart';
import '../../core/providers/advanced_settings_provider.dart';
import '../../core/constants/colors.dart';

class LrcLine {
  final Duration time;
  final String text;
  LrcLine(this.time, this.text);
}

class MushafViewWidget extends ConsumerStatefulWidget {
  final String surahId;
  final Duration position;
  final String? lrcUrl;
  final String surahName;

  const MushafViewWidget({
    super.key,
    required this.surahId,
    required this.position,
    this.lrcUrl,
    required this.surahName,
  });

  @override
  ConsumerState<MushafViewWidget> createState() => _MushafViewWidgetState();
}

class _MushafViewWidgetState extends ConsumerState<MushafViewWidget> {
  List<LrcLine> _lyrics = [];
  bool _isLoading = true;
  String _currentSource = '';

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void didUpdateWidget(MushafViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahId != widget.surahId || oldWidget.lrcUrl != widget.lrcUrl) {
      _loadLyrics();
    }
  }

  Future<void> _loadLyrics() async {
    final source = widget.lrcUrl ?? widget.surahId;
    if (_currentSource == source) return;

    setState(() {
      _isLoading = true;
      _currentSource = source;
      _lyrics = [];
    });

    try {
      String? fileContent;

      // 1. Try local file first (Offline-First)
      String? localLrcPath;
      if (!kIsWeb) {
        localLrcPath = await resolveLocalPath(widget.surahId, 'Lyrics', isLrc: true);
        final file = File(localLrcPath);
        if (await file.exists()) {
          fileContent = await file.readAsString();
        }
      }

      // 2. Try network fetch if local not found
      if (fileContent == null && widget.lrcUrl != null && widget.lrcUrl!.startsWith('http')) {
        final dio = Dio();
        final response = await dio.get(widget.lrcUrl!);
        fileContent = response.data.toString();
      } else if (fileContent == null) {
        final List<String> possibleNames = [
          widget.surahId,
          widget.surahId.replaceAll('surah_', 'surah_'),
          if (widget.surahId.contains('سورة_'))
            'surah_${widget.surahId.split('سورة_')[1].split('_')[0]}_سورة_${widget.surahId.split('سورة_')[1].split('_')[0]}'
        ];

        if (widget.surahId.contains('المائدة')) {
          possibleNames.add('surah_5_سورة_المائدة');
        } else if (widget.surahId.contains('الأحزاب')) {
          possibleNames.add('surah_33_سورة_الأحزاب');
        }

        for (var name in possibleNames) {
          try {
            fileContent = await rootBundle.loadString('assets/lyrics/$name.lrc');
            break;
          } catch (_) {
            continue;
          }
        }
      }

      if (fileContent == null) throw Exception('Lyrics not found');

      final RegExp timeRegex = RegExp(r'\[(\d{1,2}):(\d{1,2})[.:](\d{1,3})\](.*)');
      final List<LrcLine> parsedLines = [];

      for (var line in fileContent.split('\n')) {
        final match = timeRegex.firstMatch(line);
        if (match != null) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final millisText = match.group(3)!;
          final text = match.group(4)!.trim();

          if (text.isNotEmpty) {
            int milliseconds = int.parse(millisText);
            if (millisText.length == 1) milliseconds *= 100;
            if (millisText.length == 2) milliseconds *= 10;

            final duration = Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: milliseconds,
            );
            parsedLines.add(LrcLine(duration, text));
          }
        }
      }

      if (_currentSource == source && mounted) {
        setState(() {
          _lyrics = parsedLines;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_currentSource == source && mounted) {
        setState(() {
          _lyrics = [];
          _isLoading = false;
        });
      }
    }
  }

  String _getCurrentVerseText() {
    if (_lyrics.isEmpty) return '';
    int currentIndex = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_lyrics[i].time <= widget.position) {
        currentIndex = i;
      } else {
        break;
      }
    }
    if (currentIndex != -1) {
      return _lyrics[currentIndex].text;
    }
    return '';
  }

  String _getVerseNumber() {
    if (_lyrics.isEmpty) return '';
    int currentIndex = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_lyrics[i].time <= widget.position) {
        currentIndex = i;
      } else {
        break;
      }
    }
    if (currentIndex != -1) {
      return '${currentIndex + 1}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(advancedSettingsProvider);
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB8860B)),
      );
    }

    final verseText = _getCurrentVerseText();
    final verseNumber = _getVerseNumber();

    if (verseText.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get theme color based on settings
    Color themeColor = const Color(0xFFF5E6C8); // Default cream
    Color textColor = const Color(0xFF1A1A1A); // Default dark
    
    switch (settings.mushafTheme) {
      case MushafTheme.white:
        themeColor = Colors.white;
        textColor = Colors.black;
        break;
      case MushafTheme.sepia:
        themeColor = const Color(0xFFF4E4C1);
        textColor = const Color(0xFF1A1A1A);
        break;
      case MushafTheme.dark:
        themeColor = const Color(0xFF1A1A1A);
        textColor = Colors.white;
        break;
      case MushafTheme.smartDark:
        themeColor = const Color(0xFF0D1117);
        textColor = Colors.white;
        break;
    }

    // Apply font color from settings
    Color finalTextColor = textColor;
    switch (settings.fontColor) {
      case FontColor.black:
        finalTextColor = Colors.black;
        break;
      case FontColor.navy:
        finalTextColor = const Color(0xFF000080);
        break;
      case FontColor.darkRed:
        finalTextColor = const Color(0xFF8B0000);
        break;
      case FontColor.gold:
        finalTextColor = const Color(0xFFD4AF37);
        break;
    }

    return SafeArea(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFD4AF37),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                // Mushaf page content
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  decoration: BoxDecoration(
                    color: themeColor,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Decorative top ornament
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Surah name header
                      Text(
                        widget.surahName,
                        style: GoogleFonts.amiri(
                          color: finalTextColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Bismillah
                      Text(
                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        style: GoogleFonts.amiri(
                          color: finalTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Divider
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        color: const Color(0xFFD4AF37).withOpacity(0.5),
                      ),
                      const SizedBox(height: 24),
                      // Verse text with settings applied
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          verseText,
                          style: GoogleFonts.amiri(
                            color: finalTextColor,
                            fontSize: settings.lyricsFontSize * settings.mushafZoomLevel, // Apply both size and zoom
                            fontWeight: FontWeight.bold,
                            height: 1.8,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Verse end marker
                      if (verseNumber.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '۝',
                                style: GoogleFonts.amiri(
                                  color: const Color(0xFFB8860B),
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                verseNumber,
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFFB8860B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Decorative bottom ornament
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                // Screen dimming overlay for eye comfort
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: settings.dimLevel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
