/// ============================================================================
/// SYNCED CLIPS SYSTEM - INTEGRATION EXAMPLE
/// ============================================================================
/// 
/// This file shows how to integrate the complete Synced Clips System
/// into your existing app workflow.
library;

import 'package:flutter/material.dart';
import '../core/services/verse_clip_engine.dart';
import '../core/services/verse_clips_database.dart';
import '../core/models/verse_clip.dart';
import '../core/models/surah.dart';
import '../presentation/pages/my_clips_page.dart';
import '../presentation/pages/clip_player_page.dart';
import '../presentation/widgets/waveform_trimmer.dart';

/// Example 1: How to clip a verse from the surah player
class VerseClipExample {
  
  /// Clip a single verse with full synchronization
  static Future<VerseClip> clipVerse({
    required BuildContext context,
    required Surah surah,
    required int verseNumber,
    required String fullAudioPath,
    required String lrcContent,
  }) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // CRITICAL: Engine automatically:
      // 1. Parses LRC to find verse timing
      // 2. Generates word-level timings with OFFSET RESET (starts from 00:00)
      // 3. Creates standalone LRC and JSON sync files
      // 4. Saves to persistent database
      final clip = await VerseClipEngine.clipVerse(
        surah: surah,
        verseNumber: verseNumber,
        fullAudioPath: fullAudioPath,
        lrcContent: lrcContent,
      );

      // Auto-save to database (persistent storage)
      await VerseClipsDatabase.addClip(clip);

      Navigator.pop(context); // Close loading

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم قص "${clip.displayName}" بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      return clip;
    } catch (e) {
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }
}

/// Example 2: How to show waveform trimmer UI
class WaveformTrimmerExample {
  
  static void showTrimmer({
    required BuildContext context,
    required Duration totalDuration,
    required String surahName,
    required int verseNumber,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WaveformTrimmer(
        totalDuration: totalDuration,
        surahName: surahName,
        verseNumber: verseNumber,
        onTrimComplete: (startTime, endTime) {
          print('✂️ Trimmed from $startTime to $endTime');
          // TODO: Pass these times to the clipping engine
        },
      ),
    );
  }
}

/// Example 3: How to navigate to "My Clips" page
class MyClipsNavigationExample {
  
  static void openMyClips(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyClipsPage(),
      ),
    );
  }
}

/// Example 4: How to play a clipped verse
class ClipPlaybackExample {
  
  static void playClip({
    required BuildContext context,
    required VerseClip clip,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClipPlayer(clip: clip),
      ),
    );
  }
}

/// Example 5: How to add "Clip" button to surah item
class SurahItemClipIntegration extends StatelessWidget {
  final Surah surah;
  final int verseNumber;
  final String audioPath;
  final String lrcContent;

  const SurahItemClipIntegration({
    super.key,
    required this.surah,
    required this.verseNumber,
    required this.audioPath,
    required this.lrcContent,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _clipVerse(context),
      icon: const Icon(Icons.cut, color: Colors.cyanAccent),
      tooltip: 'قص الآية',
    );
  }

  Future<void> _clipVerse(BuildContext context) async {
    await VerseClipExample.clipVerse(
      context: context,
      surah: surah,
      verseNumber: verseNumber,
      fullAudioPath: audioPath,
      lrcContent: lrcContent,
    );
  }
}

/// Example 6: How to access all clips programmatically
class ClipsDataAccessExample {
  
  /// Get all saved clips
  static List<VerseClip> getAllClips() {
    return VerseClipsDatabase.getAllClips();
  }
  
  /// Get clips count
  static int getClipsCount() {
    return VerseClipsDatabase.clipsCount;
  }
  
  /// Get bookmarked clips
  static List<VerseClip> getBookmarkedClips() {
    return VerseClipsDatabase.getBookmarkedClips();
  }
  
  /// Get clips by surah
  static List<VerseClip> getClipsBySurah(int surahNumber) {
    return VerseClipsDatabase.getClipsBySurah(surahNumber);
  }
  
  /// Increment play count
  static Future<void> onClipPlayed(String clipId) async {
    await VerseClipsDatabase.incrementPlayCount(clipId);
  }
  
  /// Toggle bookmark
  static Future<void> toggleBookmark(String clipId) async {
    await VerseClipsDatabase.toggleBookmark(clipId);
  }
  
  /// Delete clip
  static Future<void> deleteClip(String clipId) async {
    await VerseClipsDatabase.deleteClip(clipId);
  }
}

/// Example 7: How to export/import clips
class ClipsBackupExample {
  
  /// Export all clips to JSON string
  static Future<String?> exportClips() async {
    return await VerseClipsDatabase.exportClips();
  }
  
  /// Import clips from JSON string
  static Future<void> importClips(String jsonString) async {
    await VerseClipsDatabase.importClips(jsonString);
  }
}

/// Example 8: Complete workflow - Clip, Play, Bookmark
class CompleteWorkflowExample {
  
  static Future<void> completeWorkflow({
    required BuildContext context,
    required Surah surah,
    required int verseNumber,
    required String audioPath,
    required String lrcContent,
  }) async {
    // Step 1: Clip the verse
    final clip = await VerseClipExample.clipVerse(
      context: context,
      surah: surah,
      verseNumber: verseNumber,
      fullAudioPath: audioPath,
      lrcContent: lrcContent,
    );

    // Step 2: Play the clip
    ClipPlaybackExample.playClip(context: context, clip: clip);

    // Step 3: Increment play count
    await ClipsDataAccessExample.onClipPlayed(clip.id);

    // Step 4: Toggle bookmark
    await ClipsDataAccessExample.toggleBookmark(clip.id);

    print('✅ Complete workflow finished for: ${clip.displayName}');
  }
}

/// Example 9: How the OFFSET RESET works
class OffsetResetExplanation {
  
  /*
   * CRITICAL: Offset Reset Logic
   * 
   * ORIGINAL SURAH TIMING:
   * - Verse starts at: 00:01:00 (60 seconds)
   * - Verse ends at:   00:01:10 (70 seconds)
   * - Duration: 10 seconds
   * 
   * AFTER CLIPPING WITH OFFSET RESET:
   * - New start time:  00:00:00 (0 seconds) ← RESET!
   * - New end time:    00:00:10 (10 seconds)
   * - Duration: 10 seconds (same)
   * 
   * HOW IT WORKS:
   * 
   * 1. Original LRC timing:
   *    [01:00.500] word1
   *    [01:01.200] word2
   *    [01:02.800] word3
   * 
   * 2. Clip start time: 60 seconds (01:00)
   * 
   * 3. OFFSET RESET (subtract 60 from all timestamps):
   *    [00:00.500] word1  ← 60.5 - 60 = 0.5
   *    [00:01.200] word2  ← 61.2 - 60 = 1.2
   *    [00:02.800] word3  ← 62.8 - 60 = 2.8
   * 
   * 4. Result: Timer starts from 00:00 for the clip!
   * 
   * CODE:
   * WordTiming.withOffsetReset(
   *   word: "word1",
   *   originalStartTime: Duration(seconds: 60),    // Original: 01:00
   *   originalEndTime: Duration(seconds: 61),      // Original: 01:01
   *   clipStartTime: Duration(seconds: 60),        // Subtract this
   * )
   * 
   * Returns:
   * WordTiming(
   *   startTime: Duration(milliseconds: 500),      // Reset: 00:00.500
   *   endTime: Duration(milliseconds: 1500),       // Reset: 00:01.500
   * )
   */
}

/// Example 10: Text.rich with golden highlight (karaoke-style)
class TextRichHighlightExample {
  
  /*
   * The ClipPlayer uses Text.rich with inline WidgetSpans
   * to create karaoke-style word-by-word highlighting.
   * 
   * STRUCTURE:
   * 
   * Text.rich(
   *   TextSpan(
   *     children: [
   *       WidgetSpan(
   *         child: AnimatedContainer(
   *           decoration: BoxDecoration(
   *             color: isCurrentWord 
   *                 ? AppColors.gold.withOpacity(0.4) 
   *                 : Colors.transparent,
   *           ),
   *           child: Text("word1"),
   *         ),
   *       ),
   *       TextSpan(text: " "),
   *       WidgetSpan(...word2...),
   *       ...
   *     ],
   *   ),
   * )
   * 
   * SYNC LOGIC:
   * 
   * for (int i = 0; i < words.length; i++) {
   *   final wordTiming = clip.wordTimings[i];
   *   
   *   final isCurrentWord = 
   *     currentPosition >= wordTiming.startTime &&
   *     currentPosition <= wordTiming.endTime;
   *   
   *   // Apply golden highlight if isCurrentWord == true
   * }
   */
}
