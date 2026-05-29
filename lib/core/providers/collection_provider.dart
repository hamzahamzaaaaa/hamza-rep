import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionState {
  final List<String> favorites;
  final List<String> listenLater;

  CollectionState({
    this.favorites = const [],
    this.listenLater = const [],
  });

  CollectionState copyWith({
    List<String>? favorites,
    List<String>? listenLater,
  }) {
    return CollectionState(
      favorites: favorites ?? this.favorites,
      listenLater: listenLater ?? this.listenLater,
    );
  }
}

class CollectionNotifier extends StateNotifier<CollectionState> {
  CollectionNotifier() : super(CollectionState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorites') ?? [];
    final later = prefs.getStringList('listen_later') ?? [];
    state = CollectionState(favorites: favs, listenLater: later);
  }

  Future<void> toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = [...state.favorites];
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    await prefs.setStringList('favorites', current);
    state = state.copyWith(favorites: current);
  }

  Future<void> toggleListenLater(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = [...state.listenLater];
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    await prefs.setStringList('listen_later', current);
    state = state.copyWith(listenLater: current);
  }

  Future<void> addAllToFavorites(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = Set<String>.from(state.favorites);
    current.addAll(ids);
    final newList = current.toList();
    await prefs.setStringList('favorites', newList);
    state = state.copyWith(favorites: newList);
  }

  Future<void> addAllToListenLater(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = Set<String>.from(state.listenLater);
    current.addAll(ids);
    final newList = current.toList();
    await prefs.setStringList('listen_later', newList);
    state = state.copyWith(listenLater: newList);
  }

  bool isFavorite(String id) => state.favorites.contains(id);
  bool isListenLater(String id) => state.listenLater.contains(id);
}

final collectionProvider = StateNotifierProvider<CollectionNotifier, CollectionState>((ref) {
  return CollectionNotifier();
});
