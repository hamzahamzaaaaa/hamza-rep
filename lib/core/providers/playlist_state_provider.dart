import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/surah.dart';

/// Provider to manage the current playlist for SmartMushafPage
class PlaylistState {
  final List<Surah> playlist;
  final int currentIndex;

  PlaylistState({
    this.playlist = const [],
    this.currentIndex = 0,
  });

  PlaylistState copyWith({
    List<Surah>? playlist,
    int? currentIndex,
  }) {
    return PlaylistState(
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

final playlistProvider = StateNotifierProvider<PlaylistNotifier, PlaylistState>((ref) {
  return PlaylistNotifier();
});

class PlaylistNotifier extends StateNotifier<PlaylistState> {
  PlaylistNotifier() : super(PlaylistState());

  void setPlaylist(List<Surah> playlist, {int initialIndex = 0}) {
    state = PlaylistState(
      playlist: playlist,
      currentIndex: initialIndex,
    );
  }

  void next() {
    if (state.currentIndex < state.playlist.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previous() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  Surah? getCurrentSurah() {
    if (state.playlist.isEmpty) return null;
    return state.playlist[state.currentIndex];
  }
}
