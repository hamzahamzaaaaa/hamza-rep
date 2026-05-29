import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/advanced_settings_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/download_provider_stub.dart'
    if (dart.library.io) '../../core/providers/download_provider_io.dart';

class LrcLine {
  final Duration time;
  final String text;

  LrcLine(this.time, this.text);
}

class SyncedLyricsWidget extends ConsumerStatefulWidget {
  final String surahId;
  final Duration position;
  final String? lrcUrl;

  final bool isZoomed;

  const SyncedLyricsWidget({
    super.key,
    required this.surahId,
    required this.position,
    this.lrcUrl,
    this.isZoomed = false,
  });

  @override
  ConsumerState<SyncedLyricsWidget> createState() => _SyncedLyricsWidgetState();
}

class _SyncedLyricsWidgetState extends ConsumerState<SyncedLyricsWidget> {
  List<LrcLine> _lyrics = [];
  bool _isLoading = true;
  String _currentSource = '';
  late FixedExtentScrollController _scrollController;
  int _lastIndex = -1;
  bool _showControls = true; // Local toggle for immersive controls
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
    _loadLyrics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SyncedLyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahId != widget.surahId || oldWidget.lrcUrl != widget.lrcUrl) {
      _loadLyrics();
    }
    _updateScrollPosition();
  }

  void _updateScrollPosition() {
    if (_lyrics.isEmpty) return;

    int currentIndex = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_lyrics[i].time <= widget.position) {
        currentIndex = i;
      } else {
        break;
      }
    }

    if (currentIndex != -1 && currentIndex != _lastIndex) {
      _lastIndex = currentIndex;
      if (_scrollController.hasClients) {
        // Offset by +1 to make the active line appear at the 2nd position (since center is 3rd in 5-line view)
        _scrollController.animateToItem(
          currentIndex + 1,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
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
        
        // Save to local file for future offline use
        if (localLrcPath != null && fileContent.trim().isNotEmpty) {
          final file = File(localLrcPath);
          await file.parent.create(recursive: true);
          await file.writeAsString(fileContent);
        }
      } else if (fileContent == null) {
        // Try exact match first, then fuzzy match
        final List<String> possibleNames = [
          widget.surahId,
          widget.surahId.replaceAll('surah_', 'surah_'),
          // Extract "سورة_..." part
          if (widget.surahId.contains('سورة_'))
            'surah_${widget.surahId.split('سورة_')[1].split('_')[0]}_سورة_${widget.surahId.split('سورة_')[1].split('_')[0]}'
        ];

        // Specific mapping for known files
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
          String text = match.group(4)!.trim();

          // Feature 2: تنظيف النصوص من الأرقام الزائدة
          text = text
              .replaceAll(RegExp(r'\(\d+\)'), '') // Remove (40), (1), etc.
              .replaceAll(RegExp(r'\[\d+\]'), '') // Remove [40], [1], etc.
              .replaceAll(RegExp(r'﴾\d+﴿'), '') // Remove ﴾40﴿
              .replaceAll(RegExp(r'\{\d+\}'), '') // Remove {40}
              .replaceAll(RegExp(r'٭\d+٭'), '') // Remove ٭40٭
              .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
              .trim();

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

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  double _calculateFontScale(String text) {
    final length = text.length;
    if (length > 150) return 0.5;
    if (length > 100) return 0.65;
    if (length > 60) return 0.85;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final isZoomed = playerState.isLyricsZoomed;
    final settings = ref.watch(advancedSettingsProvider);

    final activeColor = Color(int.parse(settings.syncFontColorHex.replaceFirst('#', '0xFF')));
    final inactiveColor = activeColor.withOpacity(0.6);

    if (_isLoading || _lyrics.isEmpty) {
      return const SizedBox.shrink();
    }

    if (isZoomed) {
      if (settings.lyricsDisplayMode == LyricsDisplayMode.onlyCurrent) {
        return _buildSingleVerseView(settings, activeColor);
      }
      return GestureDetector(
        onTap: _toggleControls,
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.transparent, // Reverted: Allow background to show
          child: Stack(
            children: [
              // 60% dark overlay behind sync texts for eye comfort
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              // Immersive Lyrics Area - Full Width/Height Edge-to-Edge
              Positioned.fill(
                child: ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 110,
                    perspective: 0.003,
                    diameterRatio: 2.0,
                    physics: const FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index >= _lyrics.length) return null;
                        final isCurrent = index == _lastIndex;
                        final baseSize = settings.lyricsFontSize;
                        final text = _lyrics[index].text;
                        final fontScale = _calculateFontScale(text);

                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          opacity: isCurrent ? 1.0 : 0.7,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            style: GoogleFonts.getFont(
                              settings.syncFontFamily,
                              textStyle: TextStyle(
                                color: isCurrent ? activeColor : Colors.white.withOpacity(0.8),
                                fontSize: (isCurrent ? baseSize * 1.5 : baseSize) * fontScale,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                height: 1.4,
                                shadows: isCurrent ? [
                                  Shadow(color: activeColor.withOpacity(0.8), blurRadius: 40)
                                ] : [],
                              ),
                            ),
                            textAlign: TextAlign.center,
                            child: Center(child: Text(_lyrics[index].text)),
                          ),
                        );
                      },
                      childCount: _lyrics.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Normal view (3 lines, active at center)
    return GestureDetector(
      onDoubleTap: () => ref.read(playerProvider.notifier).toggleLyricsZoom(),
      onTap: () => ref.read(playerProvider.notifier).toggleLyricsZoom(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 160, // Exactly 4 lines (itemExtent 40 * 4)
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: activeColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            ListWheelScrollView.useDelegate(
              controller: _scrollController,
              itemExtent: 40, // Reduced from 50
              perspective: 0.003, // Less distortion
              diameterRatio: 2.0, // Flatter appearance
              physics: const FixedExtentScrollPhysics(),
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  if (index < 0 || index >= _lyrics.length) return null;
                  final isCurrent = index == _lastIndex;
                  final text = _lyrics[index].text;
                  final fontScale = _calculateFontScale(text);

                  return AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: GoogleFonts.amiri(
                      color: isCurrent ? activeColor : inactiveColor,
                      fontSize: (isCurrent ? 28 : 18) * fontScale,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      height: 1.2,
                      shadows: isCurrent ? [
                        Shadow(color: activeColor.withOpacity(0.8), blurRadius: 12)
                      ] : [],
                    ),
                    textAlign: TextAlign.center,
                    child: Center(child: Text(_lyrics[index].text)),
                  );
                },
                childCount: _lyrics.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleVerseView(AdvancedSettings settings, Color activeColor) {
    if (_lastIndex == -1 || _lastIndex >= _lyrics.length) return const SizedBox.shrink();

    final text = _lyrics[_lastIndex].text;
    final fontScale = _calculateFontScale(text);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
        },
        child: Text(
          text,
          key: ValueKey(_lastIndex),
          textAlign: TextAlign.center,
          style: GoogleFonts.amiri(
            color: activeColor,
            fontSize: (settings.lyricsFontSize * 1.5) * fontScale,
            fontWeight: FontWeight.bold,
            height: 1.5,
            shadows: [
              Shadow(color: activeColor.withOpacity(0.8), blurRadius: 40)
            ],
          ),
        ),
      ),
    );
  }
}
