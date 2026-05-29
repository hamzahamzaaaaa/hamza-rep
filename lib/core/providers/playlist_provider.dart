import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Playlist {
  final String id;
  final String name;
  final List<String> surahIds;

  Playlist({
    required this.id,
    required this.name,
    required this.surahIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'surahIds': surahIds,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      name: map['name'],
      surahIds: List<String>.from(map['surahIds']),
    );
  }
}

class PlaylistNotifier extends StateNotifier<List<Playlist>> {
  static const _key = '@quran_playlists';

  PlaylistNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      final List decoded = jsonDecode(data);
      state = decoded.map((e) => Playlist.fromMap(e)).toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(state.map((e) => e.toMap()).toList());
    await prefs.setString(_key, data);
  }

  void createPlaylist(String name) {
    final pl = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      surahIds: [],
    );
    state = [...state, pl];
    _save();
  }

  void deletePlaylist(String id) {
    state = state.where((p) => p.id != id).toList();
    _save();
  }

  void addToPlaylist(String playlistId, String surahId) {
    state = state.map((p) {
      if (p.id == playlistId && !p.surahIds.contains(surahId)) {
        return Playlist(
          id: p.id,
          name: p.name,
          surahIds: [...p.surahIds, surahId],
        );
      }
      return p;
    }).toList();
    _save();
  }

  void removeFromPlaylist(String playlistId, String surahId) {
    state = state.map((p) {
      if (p.id == playlistId) {
        return Playlist(
          id: p.id,
          name: p.name,
          surahIds: p.surahIds.where((id) => id != surahId).toList(),
        );
      }
      return p;
    }).toList();
    _save();
  }

  void reorderSurah(String playlistId, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    state = state.map((p) {
      if (p.id == playlistId) {
        final List<String> newIds = List.from(p.surahIds);
        final item = newIds.removeAt(oldIndex);
        newIds.insert(newIndex, item);
        return Playlist(id: p.id, name: p.name, surahIds: newIds);
      }
      return p;
    }).toList();
    _save();
  }
}

final playlistProvider = StateNotifierProvider<PlaylistNotifier, List<Playlist>>((ref) {
  return PlaylistNotifier();
});
