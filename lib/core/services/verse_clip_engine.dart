import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/verse_clip.dart';
import '../models/surah.dart';

/// ============================================================================
/// SMART VERSE CLIPPING ENGINE
/// ============================================================================
/// 
/// Features:
/// - Intelligent audio clipping with metadata extraction
/// - LRC parsing and word-level timing generation
/// - Standalone JSON/LRC sync file creation
/// - Auto-save to "My Selected Verses" collection
/// - Integration with download provider

class VerseClipEngine {
  static const String _collectionFileName = 'verse_clips_collection.json';
  static const String _clipsFolderName = 'verse_clips';
  static const String _syncFolderName = 'verse_sync';

  /// Clip a single verse from a surah with full synchronization
  static Future<VerseClip> clipVerse({
    required Surah surah,
    required int verseNumber,
    required String fullAudioPath, // Path to complete surah audio
    required String lrcContent, // LRC content for the surah
  }) async {
    // Step 1: Parse LRC to find verse timing
    final verseTiming = _findVerseInLRC(lrcContent, verseNumber);
    if (verseTiming == null) {
      throw Exception('لم يتم العثور على توقيت الآية في ملف المزامنة');
    }

    // Step 2: Extract verse text from LRC
    final verseText = _extractVerseText(lrcContent, verseNumber);

    // Step 3: Generate word-level timings
    final wordTimings = _generateWordTimings(
      verseText,
      verseTiming.startTime,
      verseTiming.endTime,
    );

    // Step 4: Create clip directory
    final clipDir = await _getClipsDirectory();
    final clipId = '${surah.id}_verse_$verseNumber';
    final audioFileName = '$clipId.mp3';
    final audioPath = '${clipDir.path}/$audioFileName';

    // Step 5: Extract audio segment (create clipped file)
    await _extractAudioSegment(
      sourcePath: fullAudioPath,
      outputPath: audioPath,
      startTime: verseTiming.startTime,
      endTime: verseTiming.endTime,
    );

    // Step 6: Generate standalone LRC for this verse
    final standaloneLRC = _generateStandaloneLRC(
      surahName: surah.name,
      verseNumber: verseNumber,
      verseText: verseText,
      wordTimings: wordTimings,
    );

    // Step 7: Save standalone LRC file
    final lrcPath = await _saveSyncFile(
      clipId: clipId,
      content: standaloneLRC,
      extension: '.lrc',
    );

    // Step 8: Generate and save JSON sync file
    final jsonSyncPath = await _saveJSONSync(
      clipId: clipId,
      surahName: surah.name,
      surahNumber: surah.mushafIndex,
      verseNumber: verseNumber,
      verseText: verseText,
      wordTimings: wordTimings,
      clipDuration: verseTiming.endTime - verseTiming.startTime,
    );

    // Step 9: Create VerseClip object
    final clip = VerseClip(
      id: clipId,
      surahName: surah.name,
      surahNumber: surah.mushafIndex,
      verseNumber: verseNumber,
      verseText: verseText,
      audioPath: audioPath,
      clipStartTime: verseTiming.startTime,
      clipEndTime: verseTiming.endTime,
      clipDuration: verseTiming.endTime - verseTiming.startTime,
      wordTimings: wordTimings,
      lrcContent: standaloneLRC,
      jsonSyncPath: jsonSyncPath,
      createdAt: DateTime.now(),
    );

    // Step 10: Add to collection
    await addToCollection(clip);

    return clip;
  }

  /// Find verse timing in LRC content
  static ({Duration startTime, Duration endTime})? _findVerseInLRC(
    String lrcContent,
    int verseNumber,
  ) {
    final lines = lrcContent.split('\n');
    final RegExp timeRegex = RegExp(r'\[(\d{1,2}):(\d{1,2})[.:](\d{1,3})\](.*)');

    Duration? verseStartTime;
    Duration? nextVerseStartTime;

    for (int i = 0; i < lines.length; i++) {
      final match = timeRegex.firstMatch(lines[i]);
      if (match != null) {
        final text = match.group(4)!.trim();
        
        // Check if this line contains the verse we're looking for
        if (_containsVerseNumber(text, verseNumber)) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final millisText = match.group(3)!;
          
          int milliseconds = int.parse(millisText);
          if (millisText.length == 1) milliseconds *= 100;
          if (millisText.length == 2) milliseconds *= 10;

          verseStartTime = Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          );

          // Find next verse start time (end of current verse)
          for (int j = i + 1; j < lines.length; j++) {
            final nextMatch = timeRegex.firstMatch(lines[j]);
            if (nextMatch != null && nextMatch.group(4)!.trim().isNotEmpty) {
              final nextMinutes = int.parse(nextMatch.group(1)!);
              final nextSeconds = int.parse(nextMatch.group(2)!);
              final nextMillisText = nextMatch.group(3)!;
              
              int nextMilliseconds = int.parse(nextMillisText);
              if (nextMillisText.length == 1) nextMilliseconds *= 100;
              if (nextMillisText.length == 2) nextMilliseconds *= 10;

              nextVerseStartTime = Duration(
                minutes: nextMinutes,
                seconds: nextSeconds,
                milliseconds: nextMilliseconds,
              );
              break;
            }
          }

          // If no next verse found, add 3 seconds as default
          nextVerseStartTime ??= verseStartTime + const Duration(seconds: 3);
          break;
        }
      }
    }

    if (verseStartTime == null) return null;

    return (
      startTime: verseStartTime,
      endTime: nextVerseStartTime!,
    );
  }

  /// Check if text contains verse number marker
  static bool _containsVerseNumber(String text, int verseNumber) {
    // Common verse markers in Arabic LRC files
    final markers = [
      '﴾$verseNumber﴿',
      '($verseNumber)',
      '[$verseNumber]',
      '{$verseNumber}',
      '٭$verseNumber٭',
    ];

    return markers.any((marker) => text.contains(marker)) ||
        text.endsWith(' $verseNumber') ||
        text.contains(' $verseNumber ');
  }

  /// Extract verse text from LRC
  static String _extractVerseText(String lrcContent, int verseNumber) {
    final lines = lrcContent.split('\n');
    final RegExp timeRegex = RegExp(r'\[(\d{1,2}):(\d{1,2})[.:](\d{1,3})\](.*)');

    for (final line in lines) {
      final match = timeRegex.firstMatch(line);
      if (match != null) {
        final text = match.group(4)!.trim();
        if (_containsVerseNumber(text, verseNumber)) {
          // Remove verse number markers
          return text
              .replaceAll(RegExp(r'﴾\d+﴿'), '')
              .replaceAll(RegExp(r'\(\d+\)'), '')
              .replaceAll(RegExp(r'\[\d+\]'), '')
              .replaceAll(RegExp(r'\{\d+\}'), '')
              .replaceAll(RegExp(r'٭\d+٭'), '')
              .trim();
        }
      }
    }

    return 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ';
  }

  /// Generate word-level timings (intelligent distribution)
  /// CRITICAL: Uses offset reset to start from 00:00
  static List<WordTiming> _generateWordTimings(
    String verseText,
    Duration startTime,
    Duration endTime,
  ) {
    final words = verseText.split(RegExp(r'\s+'));
    final totalDuration = endTime - startTime;
    final wordDuration = totalDuration ~/ words.length;

    final timings = <WordTiming>[];
    for (int i = 0; i < words.length; i++) {
      // CRITICAL: Calculate original timing first
      final originalStart = startTime + (wordDuration * i);
      final originalEnd = originalStart + wordDuration;
      
      // CRITICAL: Use factory with offset reset to start from 00:00
      timings.add(WordTiming.withOffsetReset(
        word: words[i],
        originalStartTime: originalStart,
        originalEndTime: originalEnd,
        clipStartTime: startTime, // This will be subtracted
      ));
    }

    return timings;
  }

  /// Extract audio segment (placeholder - requires FFmpeg integration)
  static Future<void> _extractAudioSegment({
    required String sourcePath,
    required String outputPath,
    required Duration startTime,
    required Duration endTime,
  }) async {
    // TODO: Implement actual audio extraction using FFmpeg
    // For now, copy the full file (in production, use flutter_ffmpeg)
    final sourceFile = File(sourcePath);
    final outputFile = File(outputPath);
    
    // In production: Use FFmpeg command:
    // ffmpeg -i source.mp3 -ss startTime -to endTime -c copy outputPath.mp3
    await sourceFile.copy(outputPath);
  }

  /// Generate standalone LRC for the verse
  static String _generateStandaloneLRC({
    required String surahName,
    required int verseNumber,
    required String verseText,
    required List<WordTiming> wordTimings,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('[ti:$surahName - الآية $verseNumber]');
    buffer.writeln('[ar:حمزة مدبوح]');
    buffer.writeln('[length:${wordTimings.last.endTime.inMilliseconds}]');
    buffer.writeln('');
    buffer.writeln('[00:00.00]$verseText');
    buffer.writeln('');
    
    // Add word-by-word timestamps
    for (final wordTiming in wordTimings) {
      final minutes = wordTiming.startTime.inMinutes.toString().padLeft(2, '0');
      final seconds = wordTiming.startTime.inSeconds.remainder(60).toString().padLeft(2, '0');
      final milliseconds = (wordTiming.startTime.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
      buffer.writeln('[$minutes:$seconds.$milliseconds]${wordTiming.word}');
    }
    
    return buffer.toString();
  }

  /// Save sync file (LRC or JSON)
  static Future<String> _saveSyncFile({
    required String clipId,
    required String content,
    required String extension,
  }) async {
    final syncDir = await _getSyncDirectory();
    final filePath = '${syncDir.path}/$clipId$extension';
    final file = File(filePath);
    await file.writeAsString(content, flush: true);
    return filePath;
  }

  /// Save JSON sync file
  static Future<String> _saveJSONSync({
    required String clipId,
    required String surahName,
    required int surahNumber,
    required int verseNumber,
    required String verseText,
    required List<WordTiming> wordTimings,
    required Duration clipDuration,
  }) async {
    final syncData = {
      'version': '1.0',
      'clipId': clipId,
      'surahName': surahName,
      'surahNumber': surahNumber,
      'verseNumber': verseNumber,
      'verseText': verseText,
      'clipDurationMs': clipDuration.inMilliseconds,
      'wordTimings': wordTimings.map((w) => w.toJson()).toList(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    final syncDir = await _getSyncDirectory();
    final filePath = '${syncDir.path}/$clipId.json';
    final file = File(filePath);
    await file.writeAsString(jsonEncode(syncData), flush: true);
    return filePath;
  }

  /// Add clip to collection
  static Future<void> addToCollection(VerseClip clip) async {
    final collection = await loadCollection();
    final updatedClips = [...collection.clips];
    
    // Remove existing clip with same ID if exists
    updatedClips.removeWhere((c) => c.id == clip.id);
    updatedClips.add(clip);

    final newCollection = VerseClipCollection(
      clips: updatedClips,
      lastUpdated: DateTime.now(),
    );

    await saveCollection(newCollection);
  }

  /// Load verse clips collection
  static Future<VerseClipCollection> loadCollection() async {
    try {
      final dir = await _getClipsDirectory();
      final filePath = '${dir.path}/$_collectionFileName';
      final file = File(filePath);

      if (!await file.exists()) {
        return VerseClipCollection(
          clips: [],
          lastUpdated: DateTime.now(),
        );
      }

      final content = await file.readAsString();
      final json = jsonDecode(content);
      return VerseClipCollection.fromJson(json);
    } catch (e) {
      print('Error loading verse clips collection: $e');
      return VerseClipCollection(
        clips: [],
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Save verse clips collection
  static Future<void> saveCollection(VerseClipCollection collection) async {
    final dir = await _getClipsDirectory();
    final filePath = '${dir.path}/$_collectionFileName';
    final file = File(filePath);
    await file.writeAsString(jsonEncode(collection.toJson()), flush: true);
  }

  /// Remove clip from collection
  static Future<void> removeFromCollection(String clipId) async {
    final collection = await loadCollection();
    final updatedClips = collection.clips.where((c) => c.id != clipId).toList();

    final newCollection = VerseClipCollection(
      clips: updatedClips,
      lastUpdated: DateTime.now(),
    );

    await saveCollection(newCollection);

    // Delete associated files
    await _deleteClipFiles(clipId);
  }

  /// Delete clip files (audio + sync)
  static Future<void> _deleteClipFiles(String clipId) async {
    try {
      final clipsDir = await _getClipsDirectory();
      final syncDir = await _getSyncDirectory();

      // Delete audio file
      final audioFile = File('${clipsDir.path}/$clipId.mp3');
      if (await audioFile.exists()) {
        await audioFile.delete();
      }

      // Delete LRC sync file
      final lrcFile = File('${syncDir.path}/$clipId.lrc');
      if (await lrcFile.exists()) {
        await lrcFile.delete();
      }

      // Delete JSON sync file
      final jsonFile = File('${syncDir.path}/$clipId.json');
      if (await jsonFile.exists()) {
        await jsonFile.delete();
      }
    } catch (e) {
      print('Error deleting clip files: $e');
    }
  }

  /// Get clips directory
  static Future<Directory> _getClipsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final clipsDir = Directory('${appDir.path}/Hamza_Medbouh/$_clipsFolderName');
    
    if (!await clipsDir.exists()) {
      await clipsDir.create(recursive: true);
    }

    return clipsDir;
  }

  /// Get sync files directory
  static Future<Directory> _getSyncDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final syncDir = Directory('${appDir.path}/Hamza_Medbouh/$_syncFolderName');
    
    if (!await syncDir.exists()) {
      await syncDir.create(recursive: true);
    }

    return syncDir;
  }
}
