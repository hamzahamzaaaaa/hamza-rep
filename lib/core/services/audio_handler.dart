import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/surah.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final String? artUriPath;

  MyAudioHandler({this.artUriPath}) {
    _init();
  }

  void _init() {
    // Broadcast player state changes
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    
    // Broadcast accurate duration changes to the system notification
    _player.durationStream.listen((duration) {
      final currentItem = mediaItem.value;
      if (currentItem != null && duration != null) {
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> skipToNext() async {
    customEvent.add('skipToNext');
  }

  @override
  Future<void> skipToPrevious() async {
    customEvent.add('skipToPrevious');
  }

  @override
  Future<void> fastForward() async {
    final newPosition = _player.position + const Duration(seconds: 10);
    if (newPosition < (_player.duration ?? Duration.zero)) {
      await _player.seek(newPosition);
    } else {
      await _player.seek(_player.duration ?? Duration.zero);
    }
  }

  @override
  Future<void> rewind() async {
    final newPosition = _player.position - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await _player.seek(newPosition);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> setSurah(Surah surah, String urlOrPath) async {
    final media = MediaItem(
      id: surah.id,
      album: "القارئ حمزة مدبوح",
      title: surah.name,
      artist: "حمزة مدبوح",
      duration: surah.actualDuration ?? surah.estimatedDuration,
      artUri: (artUriPath != null && artUriPath!.isNotEmpty) ? Uri.parse(artUriPath!) : null,
    );
    mediaItem.add(media);
    
    // Stop and clear before loading new source
    await _player.stop();
    
    final finalUrl = urlOrPath.startsWith('http') ? Uri.encodeFull(urlOrPath) : urlOrPath;
    
    try {
      if (urlOrPath.startsWith('http')) {
        await _player.setUrl(finalUrl);
      } else {
        await _player.setFilePath(finalUrl);
      }
      _player.play();
    } catch (e) {
      print("Error setting audio source: $e");
    }
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.fastForward,
        MediaAction.rewind,
        MediaAction.stop,
        MediaAction.play,
        MediaAction.pause,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [1, 2, 3], // Prev, Play/Pause, Next in compact
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  AudioPlayer get player => _player;
}
