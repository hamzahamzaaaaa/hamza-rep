import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/models/verse_clip.dart';
import '../../core/constants/colors.dart';
import 'glassmorphism_theme.dart';

/// ============================================================================
/// CINEMATIC VERSE DISPLAY WITH GRADIENT HIGHLIGHTING
/// ============================================================================
/// 
/// Features:
/// - Full-screen cinematic verse display
/// - Karaoke-style gradient word highlighting
/// - Animated gradient background
/// - Glassmorphism overlay
/// - Large, luxurious Arabic typography
/// - Real-time word-by-word synchronization

class CinematicVerseDisplay extends StatefulWidget {
  final VerseClip clip;
  final Duration currentPosition;
  final bool isPlaying;
  final bool isLooping;
  final VoidCallback onLoopToggle;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onClose;

  const CinematicVerseDisplay({
    super.key,
    required this.clip,
    required this.currentPosition,
    this.isPlaying = false,
    this.isLooping = false,
    required this.onLoopToggle,
    required this.onBookmark,
    required this.onShare,
    required this.onClose,
  });

  @override
  State<CinematicVerseDisplay> createState() => _CinematicVerseDisplayState();
}

class _CinematicVerseDisplayState extends State<CinematicVerseDisplay>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animated gradient background
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Animated gradient background
          AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF1A237E),
                        const Color(0xFF0D47A1),
                        _gradientAnimation.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF4A148C),
                        const Color(0xFF311B92),
                        _gradientAnimation.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF880E4F),
                        const Color(0xFF1A237E),
                        _gradientAnimation.value,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),

          // Layer 2: Glassmorphism overlay
          const GlassOverlay(
            blurX: 30.0,
            blurY: 30.0,
            dimLevel: 0.4,
          ),

          // Layer 3: Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),
                
                const SizedBox(height: 40),

                // Verse display area
                Expanded(
                  child: Center(
                    child: _buildCinematicVerse(),
                  ),
                ),

                const SizedBox(height: 40),

                // Controls
                _buildControls(),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: widget.onClose,
          ),

          // Title
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.clip.surahName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'الآية ${widget.clip.verseNumber}',
                  style: TextStyle(
                    color: AppColors.gold.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Bookmark button
          IconButton(
            icon: Icon(
              widget.clip.isBookmarked
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: widget.clip.isBookmarked
                  ? AppColors.gold
                  : Colors.white,
              size: 28,
            ),
            onPressed: widget.onBookmark,
          ),
        ],
      ),
    );
  }

  Widget _buildCinematicVerse() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Verse text with gradient highlighting
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: _buildGradientHighlightedText(),
          ),

          const SizedBox(height: 30),

          // Time display (reset to 00:00)
          Text(
            _formatDuration(widget.currentPosition),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHighlightedText() {
    // Split verse into words for individual highlighting
    final words = widget.clip.verseText.split(RegExp(r'\s+'));
    
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 16,
      children: words.asMap().entries.map((entry) {
        final index = entry.key;
        final word = entry.value;
        
        // Find timing for this word
        final wordTiming = index < widget.clip.wordTimings.length
            ? widget.clip.wordTimings[index]
            : null;

        final isCurrentWord = wordTiming != null &&
            widget.currentPosition >= wordTiming.startTime &&
            widget.currentPosition <= wordTiming.endTime;

        return _buildWordSpan(
          word: word,
          isHighlighted: isCurrentWord,
          wordTiming: wordTiming,
        );
      }).toList(),
    );
  }

  Widget _buildWordSpan({
    required String word,
    required bool isHighlighted,
    WordTiming? wordTiming,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.gold.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ]
            : [],
      ),
      child: Text(
        word,
        style: TextStyle(
          color: isHighlighted ? Colors.white : Colors.white.withOpacity(0.8),
          fontSize: 36,
          fontWeight: FontWeight.w700,
          fontFamily: 'Amiri',
          shadows: isHighlighted
              ? [
                  Shadow(
                    color: AppColors.gold.withOpacity(0.8),
                    blurRadius: 20,
                    offset: const Offset(0, 0),
                  ),
                ]
              : [],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          // Loop and share buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Loop button
              GestureDetector(
                onTap: widget.onLoopToggle,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isLooping
                        ? AppColors.gold.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isLooping
                          ? AppColors.gold
                          : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    widget.isLooping
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: widget.isLooping
                        ? AppColors.gold
                        : Colors.white,
                    size: 32,
                  ),
                ),
              ),

              const SizedBox(width: 30),

              // Share button
              GestureDetector(
                onTap: widget.onShare,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.share,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
