/// ============================================================================
/// CLIP PLAYER - Verse Clip Playback with Text.rich + Golden Highlight
/// ============================================================================
/// 
/// Features:
/// - Text.rich with inline golden highlighting
/// - Word-by-word karaoke-style sync
/// - Timer reset to 00:00
/// - Loop functionality
/// - Glassmorphism UI

import 'package:flutter/material.dart';
import '../../core/models/verse_clip.dart';
import '../../core/constants/colors.dart';
import 'glassmorphism_theme.dart';

class ClipPlayer extends StatefulWidget {
  final VerseClip clip;

  const ClipPlayer({
    super.key,
    required this.clip,
  });

  @override
  State<ClipPlayer> createState() => _ClipPlayerState();
}

class _ClipPlayerState extends State<ClipPlayer> {
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  bool _isLooping = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1448),
              Color(0xFF2D1B69),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(),
              const SizedBox(height: 40),
              
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Glass container with verse text
                      GlassContainer(
                        blurX: 25,
                        blurY: 25,
                        opacity: 0.4,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            children: [
                              // Surah name
                              Text(
                                widget.clip.surahName,
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 28,
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Verse number
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.gold.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'الآية ${widget.clip.verseNumber}',
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              
                              // Verse text with golden highlight (Text.rich)
                              _buildHighlightedVerseText(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Timer display (reset to 00:00)
                      _buildTimerDisplay(),
                      const SizedBox(height: 30),
                      
                      // Progress bar
                      _buildProgressBar(),
                      const SizedBox(height: 40),
                      
                      // Controls
                      _buildControls(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'مشغل المقطع',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _toggleLoop,
            icon: Icon(
              _isLooping ? Icons.repeat_on : Icons.repeat,
              color: _isLooping ? AppColors.gold : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// CRITICAL: Text.rich with inline golden highlighting
  Widget _buildHighlightedVerseText() {
    final words = widget.clip.verseText.split(RegExp(r'\s+'));
    
    final textSpans = <InlineSpan>[];
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final wordTiming = widget.clip.wordTimings[i];
      
      // Check if this word is currently being recited
      final isCurrentWord = _currentPosition >= wordTiming.startTime &&
                           _currentPosition <= wordTiming.endTime;
      
      // Create text span with highlight
      textSpans.add(
        WidgetSpan(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isCurrentWord 
                  ? AppColors.gold.withOpacity(0.4) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              boxShadow: isCurrentWord ? [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ] : [],
            ),
            child: Text(
              word,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 32,
                height: 2.0,
                color: isCurrentWord ? Colors.white : Colors.white.withOpacity(0.85),
                fontWeight: isCurrentWord ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
      
      // Add space between words
      if (i < words.length - 1) {
        textSpans.add(const TextSpan(text: ' '));
      }
    }
    
    return Text.rich(
      TextSpan(
        children: textSpans,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }

  Widget _buildTimerDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Current time (starts from 00:00 - NOT original surah time!)
          Text(
            _formatDuration(_currentPosition),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 28,
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '/',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white54,
              ),
            ),
          ),
          // Total clip duration
          Text(
            _formatDuration(widget.clip.clipDuration),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 20,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: AppColors.gold,
        inactiveTrackColor: Colors.white.withOpacity(0.1),
        thumbColor: AppColors.gold,
        overlayColor: AppColors.gold.withOpacity(0.3),
      ),
      child: Slider(
        value: widget.clip.clipDuration.inMilliseconds > 0
            ? _currentPosition.inMilliseconds / widget.clip.clipDuration.inMilliseconds
            : 0.0,
        onChanged: (value) {
          setState(() {
            _currentPosition = Duration(
              milliseconds: (value * widget.clip.clipDuration.inMilliseconds).toInt(),
            );
          });
        },
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Skip back
        _buildControlButton(
          icon: Icons.replay_10,
          onPressed: _skipBack,
        ),
        const SizedBox(width: 20),
        
        // Play/Pause
        _buildControlButton(
          icon: _isPlaying ? Icons.pause : Icons.play_arrow,
          onPressed: _togglePlay,
          size: 70,
          isPrimary: true,
        ),
        const SizedBox(width: 20),
        
        // Skip forward
        _buildControlButton(
          icon: Icons.forward_10,
          onPressed: _skipForward,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 50,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPrimary 
              ? AppColors.gold 
              : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: isPrimary 
                ? AppColors.gold 
                : AppColors.gold.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.black : Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    
    // TODO: Integrate with actual audio player
    if (_isPlaying) {
      // Start playback
    } else {
      // Pause playback
    }
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });
  }

  void _skipBack() {
    setState(() {
      _currentPosition = Duration(
        milliseconds: (_currentPosition.inMilliseconds - 10000)
            .clamp(0, widget.clip.clipDuration.inMilliseconds),
      );
    });
  }

  void _skipForward() {
    setState(() {
      _currentPosition = Duration(
        milliseconds: (_currentPosition.inMilliseconds + 10000)
            .clamp(0, widget.clip.clipDuration.inMilliseconds),
      );
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
