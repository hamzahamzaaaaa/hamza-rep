/// ============================================================================
/// VERSE CLIP MODEL - Audio + Metadata Synchronization Object
/// ============================================================================
/// 
/// Represents a clipped verse with:
/// - Audio file path (clipped segment)
/// - Complete synchronization metadata
/// - Word-level timing for karaoke-style highlighting
/// - Standalone sync file support (JSON/LRC)

class VerseClip {
  final String id; // Unique identifier: "surah_2_verse_255"
  final String surahName;
  final int surahNumber;
  final int verseNumber;
  final String verseText; // Full verse text in Arabic
  
  // Audio data
  final String audioPath; // Local path to clipped audio file
  final Duration clipStartTime; // Original start time in full surah
  final Duration clipEndTime; // Original end time in full surah
  final Duration clipDuration; // Duration of the clipped segment
  
  // Synchronization metadata
  final List<WordTiming> wordTimings; // Word-level timing for gradient highlighting
  final String? lrcContent; // Standalone LRC content for this verse
  final String? jsonSyncPath; // Path to standalone JSON sync file
  
  // Display settings
  final bool isBookmarked;
  final int playCount;
  final DateTime createdAt;
  final DateTime? lastPlayed;

  VerseClip({
    required this.id,
    required this.surahName,
    required this.surahNumber,
    required this.verseNumber,
    required this.verseText,
    required this.audioPath,
    required this.clipStartTime,
    required this.clipEndTime,
    required this.clipDuration,
    required this.wordTimings,
    this.lrcContent,
    this.jsonSyncPath,
    this.isBookmarked = false,
    this.playCount = 0,
    required this.createdAt,
    this.lastPlayed,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surahName': surahName,
      'surahNumber': surahNumber,
      'verseNumber': verseNumber,
      'verseText': verseText,
      'audioPath': audioPath,
      'clipStartTimeMs': clipStartTime.inMilliseconds,
      'clipEndTimeMs': clipEndTime.inMilliseconds,
      'clipDurationMs': clipDuration.inMilliseconds,
      'wordTimings': wordTimings.map((w) => w.toJson()).toList(),
      'lrcContent': lrcContent,
      'jsonSyncPath': jsonSyncPath,
      'isBookmarked': isBookmarked,
      'playCount': playCount,
      'createdAt': createdAt.toIso8601String(),
      'lastPlayed': lastPlayed?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory VerseClip.fromJson(Map<String, dynamic> json) {
    return VerseClip(
      id: json['id'],
      surahName: json['surahName'],
      surahNumber: json['surahNumber'],
      verseNumber: json['verseNumber'],
      verseText: json['verseText'],
      audioPath: json['audioPath'],
      clipStartTime: Duration(milliseconds: json['clipStartTimeMs']),
      clipEndTime: Duration(milliseconds: json['clipEndTimeMs']),
      clipDuration: Duration(milliseconds: json['clipDurationMs']),
      wordTimings: (json['wordTimings'] as List)
          .map((w) => WordTiming.fromJson(w))
          .toList(),
      lrcContent: json['lrcContent'],
      jsonSyncPath: json['jsonSyncPath'],
      isBookmarked: json['isBookmarked'] ?? false,
      playCount: json['playCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      lastPlayed: json['lastPlayed'] != null 
          ? DateTime.parse(json['lastPlayed']) 
          : null,
    );
  }

  VerseClip copyWith({
    String? id,
    String? surahName,
    int? surahNumber,
    int? verseNumber,
    String? verseText,
    String? audioPath,
    Duration? clipStartTime,
    Duration? clipEndTime,
    Duration? clipDuration,
    List<WordTiming>? wordTimings,
    String? lrcContent,
    String? jsonSyncPath,
    bool? isBookmarked,
    int? playCount,
    DateTime? createdAt,
    DateTime? lastPlayed,
  }) {
    return VerseClip(
      id: id ?? this.id,
      surahName: surahName ?? this.surahName,
      surahNumber: surahNumber ?? this.surahNumber,
      verseNumber: verseNumber ?? this.verseNumber,
      verseText: verseText ?? this.verseText,
      audioPath: audioPath ?? this.audioPath,
      clipStartTime: clipStartTime ?? this.clipStartTime,
      clipEndTime: clipEndTime ?? this.clipEndTime,
      clipDuration: clipDuration ?? this.clipDuration,
      wordTimings: wordTimings ?? this.wordTimings,
      lrcContent: lrcContent ?? this.lrcContent,
      jsonSyncPath: jsonSyncPath ?? this.jsonSyncPath,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      playCount: playCount ?? this.playCount,
      createdAt: createdAt ?? this.createdAt,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  /// Generate standalone LRC content for this verse
  String generateLRC() {
    if (lrcContent != null) return lrcContent!;
    
    final buffer = StringBuffer();
    buffer.writeln('[ti:$surahName - الآية $verseNumber]');
    buffer.writeln('[ar:حمزة مدبوح]');
    buffer.writeln('');
    
    for (final wordTiming in wordTimings) {
      final minutes = wordTiming.startTime.inMinutes.toString().padLeft(2, '0');
      final seconds = wordTiming.startTime.inSeconds.remainder(60).toString().padLeft(2, '0');
      final milliseconds = (wordTiming.startTime.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
      buffer.writeln('[$minutes:$seconds.$milliseconds]${wordTiming.word}');
    }
    
    return buffer.toString();
  }

  /// Generate display name
  String get displayName => '$surahName - الآية $verseNumber';
  
  /// Check if this clip is shareable (has standalone sync)
  bool get isShareable => lrcContent != null || jsonSyncPath != null;
}

/// Word-level timing for karaoke-style gradient highlighting
class WordTiming {
  final String word; // The word text
  final Duration startTime; // Start time relative to clip start (00:00)
  final Duration endTime; // End time relative to clip start
  final double? x; // Optional: X coordinate for visual highlighting
  final double? y; // Optional: Y coordinate
  final double? width; // Optional: Width of highlight area
  final double? height; // Optional: Height of highlight area

  WordTiming({
    required this.word,
    required this.startTime,
    required this.endTime,
    this.x,
    this.y,
    this.width,
    this.height,
  });

  /// CRITICAL: Create word timing with offset reset
  /// Subtracts clipStartTime from original timestamps to start from 00:00
  factory WordTiming.withOffsetReset({
    required String word,
    required Duration originalStartTime,
    required Duration originalEndTime,
    required Duration clipStartTime,
  }) {
    return WordTiming(
      word: word,
      startTime: originalStartTime - clipStartTime, // Reset to 00:00
      endTime: originalEndTime - clipStartTime,     // Reset to 00:00
    );
  }

  Duration get duration => endTime - startTime;

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'startTimeMs': startTime.inMilliseconds,
      'endTimeMs': endTime.inMilliseconds,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  factory WordTiming.fromJson(Map<String, dynamic> json) {
    return WordTiming(
      word: json['word'],
      startTime: Duration(milliseconds: json['startTimeMs']),
      endTime: Duration(milliseconds: json['endTimeMs']),
      x: json['x']?.toDouble(),
      y: json['y']?.toDouble(),
      width: json['width']?.toDouble(),
      height: json['height']?.toDouble(),
    );
  }
}

/// Collection of verse clips
class VerseClipCollection {
  final List<VerseClip> clips;
  final DateTime lastUpdated;

  VerseClipCollection({
    required this.clips,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'clips': clips.map((c) => c.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory VerseClipCollection.fromJson(Map<String, dynamic> json) {
    return VerseClipCollection(
      clips: (json['clips'] as List)
          .map((c) => VerseClip.fromJson(c))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  VerseClipCollection copyWith({
    List<VerseClip>? clips,
    DateTime? lastUpdated,
  }) {
    return VerseClipCollection(
      clips: clips ?? this.clips,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
