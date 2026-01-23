import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/playlist_model.dart';
import '../data/models/song_model.dart';
import '../data/services/playlist_service.dart';
import 'auth_providers.dart';

final playlistServiceProvider = Provider<PlaylistService>(
  (ref) => PlaylistService(),
);

final userPlaylistsProvider = FutureProvider<List<PlaylistModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final playlistService = ref.watch(playlistServiceProvider);
  return await playlistService.getUserPlaylists(user.id);
});

final playlistSongsProvider = FutureProvider.family<List<SongModel>, String>((
  ref,
  playlistId,
) async {
  final playlistService = ref.watch(playlistServiceProvider);
  return await playlistService.getPlaylistSongs(playlistId);
});
