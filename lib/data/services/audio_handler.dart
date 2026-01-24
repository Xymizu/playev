import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class PlayevAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  Function()? onSongComplete; // Callback untuk auto-play next

  PlayevAudioHandler() {
    // Listen to player state changes
    _player.playbackEventStream.listen((event) {
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (_player.playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          systemActions: {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
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
          queueIndex: 0,
        ),
      );
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });

    // Listen to duration
    _player.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });

    // Listen to player completion
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        onSongComplete?.call();
      }
    });
  }

  AudioPlayer get player => _player;

  // Play from URL
  @override
  Future<void> play() => _player.play();

  // Pause
  @override
  Future<void> pause() => _player.pause();

  // Stop
  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  // Seek
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  // Skip to next (implement later with queue)
  @override
  Future<void> skipToNext() async {
    // TODO: Implement skip to next song
  }

  // Skip to previous (implement later with queue)
  @override
  Future<void> skipToPrevious() async {
    // TODO: Implement skip to previous song
  }

  // Set audio URL and metadata
  Future<void> setAudio(String url, MediaItem item) async {
    mediaItem.add(item);
    await _player.setUrl(url);
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
