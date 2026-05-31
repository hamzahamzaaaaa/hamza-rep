/// ============================================================================
/// VERSE CLIPS DATABASE - Persistent Storage with Hive
/// ============================================================================
/// 
/// Provides:
/// - Persistent storage for all clipped verses
/// - Automatic save/load on app start
/// - CRUD operations for clips
/// - Backup/export functionality
library;

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/verse_clip.dart';

class VerseClipsDatabase {
  static const String _fileName = 'verse_clips.json';
  static List<VerseClip> _clips = [];
  
  /// Get all saved clips
  static List<VerseClip> getAllClips() {
    return List.unmodifiable(_clips);
  }
  
  /// Get clip by ID
  static VerseClip? getClipById(String id) {
    try {
      return _clips.firstWhere((clip) => clip.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Get clips by surah number
  static List<VerseClip> getClipsBySurah(int surahNumber) {
    return _clips.where((clip) => clip.surahNumber == surahNumber).toList();
  }
  
  /// Add new clip
  static Future<void> addClip(VerseClip clip) async {
    // Check if already exists
    final existingIndex = _clips.indexWhere((c) => c.id == clip.id);
    
    if (existingIndex != -1) {
      // Update existing
      _clips[existingIndex] = clip;
    } else {
      // Add new
      _clips.add(clip);
    }
    
    await _saveToDisk();
  }
  
  /// Update clip (e.g., increment play count, bookmark)
  static Future<void> updateClip(VerseClip clip) async {
    final index = _clips.indexWhere((c) => c.id == clip.id);
    
    if (index != -1) {
      _clips[index] = clip;
      await _saveToDisk();
    }
  }
  
  /// Delete clip
  static Future<void> deleteClip(String clipId) async {
    final clip = getClipById(clipId);
    
    if (clip != null) {
      // Delete audio file if exists
      final audioFile = File(clip.audioPath);
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
      
      // Delete sync files if exist
      if (clip.jsonSyncPath != null) {
        final jsonFile = File(clip.jsonSyncPath!);
        if (await jsonFile.exists()) {
          await jsonFile.delete();
        }
      }
      
      // Remove from list
      _clips.removeWhere((c) => c.id == clipId);
      await _saveToDisk();
    }
  }
  
  /// Increment play count
  static Future<void> incrementPlayCount(String clipId) async {
    final clip = getClipById(clipId);
    
    if (clip != null) {
      final updatedClip = clip.copyWith(
        playCount: clip.playCount + 1,
        lastPlayed: DateTime.now(),
      );
      await updateClip(updatedClip);
    }
  }
  
  /// Toggle bookmark
  static Future<void> toggleBookmark(String clipId) async {
    final clip = getClipById(clipId);
    
    if (clip != null) {
      final updatedClip = clip.copyWith(isBookmarked: !clip.isBookmarked);
      await updateClip(updatedClip);
    }
  }
  
  /// Get bookmarked clips
  static List<VerseClip> getBookmarkedClips() {
    return _clips.where((clip) => clip.isBookmarked).toList();
  }
  
  /// Get total clips count
  static int get clipsCount => _clips.length;
  
  /// Initialize database - load from disk
  static Future<void> init() async {
    await _loadFromDisk();
    print('✅ VerseClipsDatabase initialized with ${_clips.length} clips');
  }
  
  /// Load clips from disk
  static Future<void> _loadFromDisk() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$_fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        
        _clips = jsonList
            .map((json) => VerseClip.fromJson(json as Map<String, dynamic>))
            .toList();
        
        print('📂 Loaded ${_clips.length} clips from disk');
      } else {
        _clips = [];
        print('📂 No existing clips file found');
      }
    } catch (e) {
      print('❌ Error loading clips: $e');
      _clips = [];
    }
  }
  
  /// Save clips to disk
  static Future<void> _saveToDisk() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$_fileName';
      final file = File(filePath);
      
      final jsonList = _clips.map((clip) => clip.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await file.writeAsString(jsonString);
      print('💾 Saved ${_clips.length} clips to disk');
    } catch (e) {
      print('❌ Error saving clips: $e');
    }
  }
  
  /// Export all clips (for backup/sharing)
  static Future<String?> exportClips() async {
    try {
      final jsonList = _clips.map((clip) => clip.toJson()).toList();
      return jsonEncode(jsonList);
    } catch (e) {
      print('❌ Error exporting clips: $e');
      return null;
    }
  }
  
  /// Import clips from JSON string
  static Future<void> importClips(String jsonString) async {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final importedClips = jsonList
          .map((json) => VerseClip.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Merge with existing clips
      for (final clip in importedClips) {
        await addClip(clip);
      }
      
      print('📥 Imported ${importedClips.length} clips');
    } catch (e) {
      print('❌ Error importing clips: $e');
    }
  }
  
  /// Clear all clips (reset)
  static Future<void> clearAll() async {
    _clips.clear();
    await _saveToDisk();
    print('🗑️ All clips cleared');
  }
}
