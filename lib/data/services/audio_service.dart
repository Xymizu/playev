import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'audio_handler.dart';
import '../models/song_model.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal();

  PlayevAudioHandler? _audioHandler;
  AudioPlayer? _fallbackPlayer; // Fallback jika audio_service gagal
  Function()? _onSongCompleteCallback;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Set callback untuk auto-play next
  void setOnSongCompleteCallback(Function() callback) {
    _onSongCompleteCallback = callback;
    if (_audioHandler != null) {
      _audioHandler!.onSongComplete = callback;
    }
  }

  // Initialize audio service (call this in main.dart)
  Future<void> init() async {
    try {
      _audioHandler = await AudioService.init(
        builder: () => PlayevAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.playev.audio',
          androidNotificationChannelName: 'Playev',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );

      // Set callback jika sudah ada
      if (_onSongCompleteCallback != null) {
        _audioHandler!.onSongComplete = _onSongCompleteCallback;
      }

      _isInitialized = true;
      print('✅ Audio service with background support initialized');
    } catch (e) {
      print('⚠️ Audio service init failed: $e');
      print('🔄 Using fallback player (no background support)');
      _fallbackPlayer = AudioPlayer();
      _isInitialized = true; // Still mark as initialized
    }
  }

  // Getter untuk akses player
  AudioPlayer? get player => _audioHandler?.player ?? _fallbackPlayer;

  // Check if audio is loaded
  bool get hasAudioSource {
    if (_audioHandler != null) {
      return _audioHandler!.player.audioSource != null;
    }
    return _fallbackPlayer?.audioSource != null;
  }

  // Getter untuk status playing
  bool get isPlaying {
    if (_audioHandler != null) {
      return _audioHandler!.player.playing;
    }
    return _fallbackPlayer?.playing ?? false;
  }

  // Stream untuk posisi playback
  Stream<Duration> get positionStream {
    if (_audioHandler != null) {
      return _audioHandler!.player.positionStream;
    }
    return _fallbackPlayer?.positionStream ?? Stream.value(Duration.zero);
  }

  // Stream untuk durasi total
  Stream<Duration?> get durationStream {
    if (_audioHandler != null) {
      return _audioHandler!.player.durationStream;
    }
    return _fallbackPlayer?.durationStream ?? Stream.value(null);
  }

  // Stream untuk status playing
  Stream<bool> get playingStream {
    if (_audioHandler != null) {
      return _audioHandler!.player.playingStream;
    }
    return _fallbackPlayer?.playingStream ?? Stream.value(false);
  }

  // Play audio dari URL dengan metadata
  Future<void> play(String url, {SongModel? song}) async {
    if (!_isInitialized) {
      print('⚠️ Audio service not ready');
      return;
    }

    try {
      if (_audioHandler != null) {
        // Use audio_service with notification
        if (song != null) {
          final mediaItem = MediaItem(
            id: song.id,
            album: song.album ?? 'Unknown Album',
            title: song.title,
            artist: song.artist,
            artUri: song.coverUrl != null ? Uri.parse(song.coverUrl!) : null,
            duration: Duration(seconds: song.duration ?? 0),
          );
          await _audioHandler!.setAudio(url, mediaItem);
        } else {
          await _audioHandler!.player.setUrl(url);
        }
        await _audioHandler!.play();
      } else if (_fallbackPlayer != null) {
        // Use fallback player (no notification)
        print('🎵 Playing with fallback player');
        await _fallbackPlayer!.setUrl(url);
        await _fallbackPlayer!.play();
      }
    } catch (e) {
      print('❌ Error playing audio: $e');
    }
  }

  // Pause audio
  Future<void> pause() async {
    if (_audioHandler != null) {
      await _audioHandler!.pause();
    } else {
      await _fallbackPlayer?.pause();
    }
  }

  // Resume audio
  Future<void> resume() async {
    if (_audioHandler != null) {
      await _audioHandler!.play();
    } else {
      await _fallbackPlayer?.play();
    }
  }

  // Stop audio
  Future<void> stop() async {
    if (_audioHandler != null) {
      await _audioHandler!.stop();
    } else {
      await _fallbackPlayer?.stop();
    }
  }

  // Seek ke posisi tertentu
  Future<void> seek(Duration position) async {
    if (_audioHandler != null) {
      await _audioHandler!.seek(position);
    } else {
      await _fallbackPlayer?.seek(position);
    }
  }

  // Dispose player
  void dispose() {
    _audioHandler?.dispose();
    _fallbackPlayer?.dispose();
  }
}
