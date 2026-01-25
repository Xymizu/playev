import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audio_handler.dart';
import '../models/song_model.dart';
import 'play_history_service.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal();

  PlayevAudioHandler? _audioHandler;
  AudioPlayer? _fallbackPlayer;
  Function()? _onSongCompleteCallback;
  bool _isInitialized = false;

  // Queue management
  List<SongModel> _queue = [];
  int _currentIndex = -1;

  final _playHistoryService = PlayHistoryService();

  bool get isInitialized => _isInitialized;
  List<SongModel> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  SongModel? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _queue.length
      ? _queue[_currentIndex]
      : null;

  // Auto-play next callback
  void setOnSongCompleteCallback(Function() callback) {
    _onSongCompleteCallback = callback;
    if (_audioHandler != null) {
      _audioHandler!.onSongComplete = callback;
    }
  }

  // Init audio service
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
      print('Audio service initialized with background support');
    } catch (e) {
      print('Audio service init failed: $e');
      print('Using fallback player without background support');
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

  // Position stream
  Stream<Duration> get positionStream {
    if (_audioHandler != null) {
      return _audioHandler!.player.positionStream;
    }
    return _fallbackPlayer?.positionStream ?? Stream.value(Duration.zero);
  }

  // Duration stream
  Stream<Duration?> get durationStream {
    if (_audioHandler != null) {
      return _audioHandler!.player.durationStream;
    }
    return _fallbackPlayer?.durationStream ?? Stream.value(null);
  }

  // Playing state stream
  Stream<bool> get playingStream {
    if (_audioHandler != null) {
      return _audioHandler!.player.playingStream;
    }
    return _fallbackPlayer?.playingStream ?? Stream.value(false);
  }

  // Play audio dari URL dengan metadata
  Future<void> play(String url, {SongModel? song}) async {
    if (!_isInitialized) {
      print('Audio service not ready');
      return;
    }

    try {
      if (_audioHandler != null) {
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

          // Record play history
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            await _playHistoryService.recordPlay(
              userId: userId,
              songId: song.id,
            );
          }
        } else {
          await _audioHandler!.player.setUrl(url);
        }
        await _audioHandler!.play();
      } else if (_fallbackPlayer != null) {
        print('Playing with fallback player');
        await _fallbackPlayer!.setUrl(url);
        await _fallbackPlayer!.play();

        // Record play history
        if (song != null) {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            await _playHistoryService.recordPlay(
              userId: userId,
              songId: song.id,
            );
          }
        }
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  // Queue methods
  void setQueue(List<SongModel> songs, {int startIndex = 0}) {
    _queue = songs;
    _currentIndex = startIndex;
  }

  void addToQueue(SongModel song) {
    _queue.add(song);
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (index < _currentIndex) {
        _currentIndex--;
      }
    }
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
  }

  Future<void> playNext() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      final song = _queue[_currentIndex];
      await play(song.audioUrl, song: song);
    }
  }

  Future<void> playPrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      final song = _queue[_currentIndex];
      await play(song.audioUrl, song: song);
    }
  }

  Future<void> playAtIndex(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      final song = _queue[index];
      await play(song.audioUrl, song: song);
    }
  }

  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

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
