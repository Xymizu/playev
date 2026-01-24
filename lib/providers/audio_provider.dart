import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/audio_service.dart';

// Provider untuk audio service
final audioServiceProvider = Provider((ref) => AudioPlayerService());

// Provider untuk status playing
final isPlayingProvider = StreamProvider<bool>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.playingStream;
});

// Provider untuk posisi musik
final positionProvider = StreamProvider<Duration>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.positionStream;
});

// Provider untuk durasi total
final durationProvider = StreamProvider<Duration?>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.durationStream;
});
