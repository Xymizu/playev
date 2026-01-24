import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/song_model.dart';
import '../data/services/song_service.dart';

final songServiceProvider = Provider<SongService>((ref) => SongService());

final approvedSongsProvider = FutureProvider<List<SongModel>>((ref) async {
  final songService = ref.watch(songServiceProvider);
  return await songService.getApprovedSongs();
});

// Provider for all songs (for admin stats)
final allSongsProvider = FutureProvider<List<SongModel>>((ref) async {
  final songService = ref.watch(songServiceProvider);
  return await songService.getAllSongs();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<SongModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];

  final songService = ref.watch(songServiceProvider);
  return await songService.searchSongs(query);
});

final currentSongProvider = StateProvider<SongModel?>((ref) => null);
