import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import '../models/surah.dart';
import '../data/telawat_2018.dart';
import '../data/telawat_2019.dart';
import '../data/telawat_2022.dart';
import '../data/telawat_2020.dart';
import '../data/telawat_2023.dart';
import '../data/telawat_2024.dart';
import '../data/telawat_2025.dart';
import '../data/telawat_2026_local.dart';
import '../data/anashid_2018.dart';
import '../data/anashid_2019.dart';
import '../data/anashid_2020.dart';
import '../data/anashid_2022.dart';
import '../data/anashid_2023.dart';
import '../data/anashid_2024.dart';
import '../services/audio_handler.dart';
import 'download_provider.dart';
import 'statistics_provider.dart';
import '../../main.dart';

class PlayerState {
  final Surah? currentSurah;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double speed;
  final bool isRepeat;
  final bool isShuffle;
  final bool isLoading;
  final int? sleepTimerRemaining;
  final bool stopAfterCurrent;
  final bool isLyricsZoomed;
  final Duration? hifzStart;
  final Duration? hifzEnd;
  final Duration? abStart;
  final Duration? abEnd;
  final double volume;
  final bool showMiniPlayer;

  PlayerState({
    this.currentSurah,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.isRepeat = false,
    this.isShuffle = false,
    this.isLoading = false,
    this.sleepTimerRemaining,
    this.stopAfterCurrent = false,
    this.isLyricsZoomed = false,
    this.hifzStart,
    this.hifzEnd,
    this.abStart,
    this.abEnd,
    this.volume = 1.0,
    this.showMiniPlayer = true,
  });

  PlayerState copyWith({
    Surah? currentSurah,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? speed,
    bool? isRepeat,
    bool? isShuffle,
    bool? isLoading,
    int? Function()? sleepTimerRemaining,
    bool? stopAfterCurrent,
    bool? isLyricsZoomed,
    Duration? Function()? hifzStart,
    Duration? Function()? hifzEnd,
    Duration? Function()? abStart,
    Duration? Function()? abEnd,
    double? volume,
    bool? showMiniPlayer,
  }) {
    return PlayerState(
      currentSurah: currentSurah ?? this.currentSurah,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      isRepeat: isRepeat ?? this.isRepeat,
      isShuffle: isShuffle ?? this.isShuffle,
      isLoading: isLoading ?? this.isLoading,
      sleepTimerRemaining: sleepTimerRemaining != null ? sleepTimerRemaining() : this.sleepTimerRemaining,
      stopAfterCurrent: stopAfterCurrent ?? this.stopAfterCurrent,
      isLyricsZoomed: isLyricsZoomed ?? this.isLyricsZoomed,
      hifzStart: hifzStart != null ? hifzStart() : this.hifzStart,
      hifzEnd: hifzEnd != null ? hifzEnd() : this.hifzEnd,
      abStart: abStart != null ? abStart() : this.abStart,
      abEnd: abEnd != null ? abEnd() : this.abEnd,
      volume: volume ?? this.volume,
      showMiniPlayer: showMiniPlayer ?? this.showMiniPlayer,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  MyAudioHandler? _handler;
  final Ref _ref;
  final AudioPlayer _fallbackPlayer = AudioPlayer(); // Fallback player
  List<Surah> _queue = [];
  List<Surah> get currentQueue => _queue;
  Timer? _sleepTimer;
  Timer? _statsTimer;

  PlayerNotifier(this._handler, this._ref) : super(PlayerState()) {
    if (_handler != null) {
      _initHandler();
    } else {
      _initFallback();
    }
    _loadPersistedState();
    _initStatsTimer();
  }

  void _initStatsTimer() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isPlaying && !state.isLoading) {
        _ref.read(statisticsProvider.notifier).incrementListeningDuration(1);
      }
    });
  }

  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('last_surah_id');
      if (savedId != null) {
        final List<Surah> allSuggestions = [
          ...surahList,
          ...telawat2018List,
          ...telawat2019List,
          ...telawat2022List,
          ...telawat2020List,
          ...telawat2023List,
          ...telawat2024List,
          ...telawat2025List,
          ...telawat2026LocalList,
          ...anashid2018List,
          ...anashid2019List,
          ...anashid2020List,
          ...anashid2022List,
          ...anashid2023List,
          ...anashid2024List,
        ];
        final surah = allSuggestions.firstWhere((s) => s.id == savedId);
        _queue = allSuggestions;
        state = state.copyWith(currentSurah: surah);
        
        // Load but pause
        String path = surah.url;
        if (path.contains('youtu.be') || path.contains('youtube.com')) {
          final yt = YoutubeExplode();
          try {
            var manifest = await yt.videos.streamsClient.getManifest(path);
            var audioStreams = manifest.audioOnly;
            var streamInfo = audioStreams.where((s) => s.container.name == 'mp4').firstOrNull ?? audioStreams.withHighestBitrate();
            path = streamInfo.url.toString();
          } catch(e) {
            print("YT Error: $e");
          } finally {
            yt.close();
          }
        }
        
        if (_handler != null) {
          await _handler!.setSurah(surah, path);
          await _handler!.pause();
        } else {
          if (path.startsWith('http')) {
            await _fallbackPlayer.setUrl(path);
          } else {
            await _fallbackPlayer.setFilePath(path);
          }
          await _fallbackPlayer.pause();
        }
      }
    } catch (e) {
      print("Error loading state: $e");
    }
  }

  Future<void> setHandler(MyAudioHandler handler) async {
    if (_handler != null) return;
    _handler = handler;
    _initHandler();

    // Migrate from fallback to background handler
    if (state.currentSurah != null) {
      final currentPos = _fallbackPlayer.position;
      final wasPlaying = _fallbackPlayer.playing;
      
      await _fallbackPlayer.stop();

      try {
        final downloads = _ref.read(downloadProvider);
        final downloadItem = downloads.items[state.currentSurah!.id];
        String path = state.currentSurah!.url;
        
        if (downloadItem != null && downloadItem.isCompleted) {
          final file = File(downloadItem.localPath);
          if (await file.exists()) {
            path = downloadItem.localPath;
          }
        }
        
        await _handler!.setSurah(state.currentSurah!, path);
        await _handler!.seek(currentPos);
        if (wasPlaying) {
          await _handler!.play();
        }
      } catch (e) {
        print("Migration failed: $e");
      }
    }
  }

  void _initHandler() {
    _handler!.player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
      _checkHifzLoop(pos);
    });
    _handler!.player.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(duration: dur);
    });
    _handler!.playbackState.listen((ps) {
      state = state.copyWith(
        isPlaying: ps.playing,
        isLoading: ps.processingState == AudioProcessingState.loading ||
            ps.processingState == AudioProcessingState.buffering,
      );

      // Stop after current logic
      if (ps.processingState == AudioProcessingState.completed && state.stopAfterCurrent) {
        _handler!.pause();
        state = state.copyWith(stopAfterCurrent: false);
      }
    });

    _handler!.customEvent.listen((event) {
      if (event == 'skipToNext') {
        nextSurah();
      } else if (event == 'skipToPrevious') {
        prevSurah();
      }
    });
  }

  void _initFallback() {
    _fallbackPlayer.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
      _checkHifzLoop(pos);
    });
    _fallbackPlayer.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(duration: dur);
    });
    _fallbackPlayer.playerStateStream.listen((ps) {
      state = state.copyWith(
        isPlaying: ps.playing,
        isLoading: ps.processingState == ProcessingState.loading ||
            ps.processingState == ProcessingState.buffering,
      );
    });
  }

  void _checkHifzLoop(Duration pos) {
    if (state.hifzStart != null && state.hifzEnd != null) {
      if (pos >= state.hifzEnd!) {
        seek(state.hifzStart!);
      }
    }
    if (state.abStart != null && state.abEnd != null) {
      if (pos >= state.abEnd!) {
        seek(state.abStart!);
      }
    }
  }

  void toggleLyricsZoom([bool? force]) {
    state = state.copyWith(isLyricsZoomed: force ?? !state.isLyricsZoomed);
  }

  void setMiniPlayerVisibility(bool visible) {
    state = state.copyWith(showMiniPlayer: visible);
  }

  void setVolume(double vol) {
    state = state.copyWith(volume: vol);
    _handler != null ? _handler!.player.setVolume(vol) : _fallbackPlayer.setVolume(vol);
  }

  void toggleHifzMode() {
    if (state.hifzStart == null) {
      state = state.copyWith(hifzStart: () => state.position, hifzEnd: () => state.position + const Duration(seconds: 15));
    } else {
      state = state.copyWith(hifzStart: () => null, hifzEnd: () => null);
    }
  }

  void setABPoint() {
    if (state.abStart == null) {
      // Set point A
      state = state.copyWith(abStart: () => state.position);
    } else if (state.abEnd == null) {
      // Set point B
      if (state.position > state.abStart!) {
        state = state.copyWith(abEnd: () => state.position);
      } else {
        // Position is before A, reset A to current
        state = state.copyWith(abStart: () => state.position);
      }
    } else {
      // Reset both
      state = state.copyWith(abStart: () => null, abEnd: () => null);
    }
  }

  void updateHifzRange(Duration start, Duration end) {
    state = state.copyWith(hifzStart: () => start, hifzEnd: () => end);
  }

  Future<void> playSurah(Surah surah, List<Surah> queue, {bool openFullScreen = true}) async {
    try {
      if (state.currentSurah?.id == surah.id && state.currentSurah != null) {
        if (!state.isPlaying) {
            togglePlay();
        }
        if (openFullScreen && navigatorKey.currentContext != null) {
          state = state.copyWith(isLyricsZoomed: surah.hasLyrics);
          mainScreenKey.currentState?.switchToCurrentlyPage();
        }
        return;
      }

      _queue = queue;
      state = state.copyWith(currentSurah: surah, isLoading: true);
      _ref.read(statisticsProvider.notifier).incrementPlayCount(surah.id);
      
      final downloads = _ref.read(downloadProvider);
      final downloadItem = downloads.items[surah.id];
      String path = surah.url;
      
      if (downloadItem != null && downloadItem.isCompleted) {
        final file = File(downloadItem.localPath);
        if (await file.exists()) {
          path = downloadItem.localPath;
        }
      }

      if (path.contains('youtu.be') || path.contains('youtube.com')) {
        final yt = YoutubeExplode();
        try {
          var manifest = await yt.videos.streamsClient.getManifest(path);
          var audioStreams = manifest.audioOnly;
          var streamInfo = audioStreams.where((s) => s.container.name == 'mp4').firstOrNull ?? audioStreams.withHighestBitrate();
          path = streamInfo.url.toString();
        } catch(e) {
          print("YT Error: $e");
        } finally {
          yt.close();
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('last_surah_id', surah.id);
      
      if (_handler != null) {
        await _handler!.setSurah(surah, path);
        await _handler!.play(); // تشغيل فوري وبقوة
      } else {
        await _fallbackPlayer.stop();
        if (path.startsWith('http')) {
          await _fallbackPlayer.setUrl(Uri.encodeFull(path), preload: false);
        } else {
          await _fallbackPlayer.setFilePath(path, preload: false);
        }
        await _fallbackPlayer.play();
      }

      if (openFullScreen && navigatorKey.currentContext != null) {
        state = state.copyWith(isLyricsZoomed: true); // Always open in sync/full screen view
        mainScreenKey.currentState?.switchToCurrentlyPage();
      }
    } catch (e) {
      print("Error playing surah: $e");
    }
  }

  void togglePlay() {
    if (state.isPlaying) {
      _handler != null ? _handler!.pause() : _fallbackPlayer.pause();
    } else {
      _handler != null ? _handler!.play() : _fallbackPlayer.play();
    }
  }

  void seek(Duration pos) {
    _handler != null ? _handler!.seek(pos) : _fallbackPlayer.seek(pos);
  }

  void skipForward() {
    final newPos = state.position + const Duration(seconds: 10);
    final target = newPos > state.duration ? state.duration : newPos;
    _handler != null ? _handler!.seek(target) : _fallbackPlayer.seek(target);
  }

  void skipBackward() {
    final newPos = state.position - const Duration(seconds: 10);
    final target = newPos < Duration.zero ? Duration.zero : newPos;
    _handler != null ? _handler!.seek(target) : _fallbackPlayer.seek(target);
  }

  void setSpeed(double s) {
    state = state.copyWith(speed: s);
    _handler != null ? _handler!.player.setSpeed(s) : _fallbackPlayer.setSpeed(s);
  }

  void toggleRepeat() {
    final next = !state.isRepeat;
    state = state.copyWith(isRepeat: next);
    final mode = next ? LoopMode.one : LoopMode.off;
    _handler != null ? _handler!.player.setLoopMode(mode) : _fallbackPlayer.setLoopMode(mode);
  }

  void toggleShuffle() {
    final next = !state.isShuffle;
    state = state.copyWith(isShuffle: next);
    _handler != null ? _handler!.player.setShuffleModeEnabled(next) : _fallbackPlayer.setShuffleModeEnabled(next);
  }

  void playNextAt(Surah surah) {
    if (state.currentSurah == null) {
      playSurah(surah, [surah]);
      return;
    }
    int currentIdx = _queue.indexWhere((s) => s.id == state.currentSurah!.id);
    if (currentIdx != -1) {
      _queue.insert(currentIdx + 1, surah);
    } else {
      _queue.add(surah);
    }
  }
  void playPrevious() => prevSurah();

  void setSleepTimer(int? minutes, {bool stopAfterCurrent = false}) {
    _sleepTimer?.cancel();
    state = state.copyWith(stopAfterCurrent: stopAfterCurrent);

    if (minutes == null) {
      state = state.copyWith(sleepTimerRemaining: () => null);
      return;
    }

    state = state.copyWith(sleepTimerRemaining: () => minutes * 60);
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.sleepTimerRemaining ?? 0;
      if (remaining <= 0) {
        timer.cancel();
        _handler != null ? _handler!.pause() : _fallbackPlayer.pause();
        state = state.copyWith(sleepTimerRemaining: () => null);
      } else {
        state = state.copyWith(sleepTimerRemaining: () => remaining - 1);
      }
    });
  }

  void nextSurah() {
    if (_queue.isEmpty || state.currentSurah == null) return;
    int index = _queue.indexWhere((s) => s.id == state.currentSurah!.id);
    if (index != -1 && index + 1 < _queue.length) {
      playSurah(_queue[index + 1], _queue, openFullScreen: false);
    } else {
      // Fallback to Suggested Recitations queue
      final allSuggestions = [
        ...surahList,
        ...telawat2018List,
        ...telawat2022List,
        ...telawat2020List,
        ...telawat2023List,
        ...telawat2024List,
        ...telawat2025List,
        ...telawat2026LocalList,
      ];
      int allIndex = allSuggestions.indexWhere((s) => s.id == state.currentSurah!.id);
      if (allIndex != -1 && allIndex + 1 < allSuggestions.length) {
        playSurah(allSuggestions[allIndex + 1], allSuggestions, openFullScreen: false);
      } else if (allSuggestions.isNotEmpty) {
        playSurah(allSuggestions.first, allSuggestions, openFullScreen: false);
      }
    }
  }

  void prevSurah() {
    if (_queue.isEmpty || state.currentSurah == null) return;
    final idx = _queue.indexOf(state.currentSurah!);
    if (idx > 0) {
      playSurah(_queue[idx - 1], _queue, openFullScreen: false);
    }
  }

  void closePlayer() {
    if (_handler != null) {
      _handler!.stop();
    } else {
      _fallbackPlayer.stop();
    }
    state = PlayerState(); // Reset everything, hiding the mini player
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _sleepTimer?.cancel();
    _fallbackPlayer.dispose();
    super.dispose();
  }
}

// Global provider for the handler (will be initialized in main)
final audioHandlerProvider = Provider<MyAudioHandler?>((ref) => null);

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return PlayerNotifier(handler, ref);
});
