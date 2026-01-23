import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

class PlaylistService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PlaylistModel>> getUserPlaylists(String userId) async {
    try {
      final response = await _supabase
          .from('playlists')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PlaylistModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Get user playlists error: $e');
      return [];
    }
  }

  Future<PlaylistModel?> createPlaylist({
    required String userId,
    required String name,
    String? coverUrl,
  }) async {
    try {
      final response = await _supabase
          .from('playlists')
          .insert({
            'user_id': userId,
            'name': name,
            'cover_url': coverUrl,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return PlaylistModel.fromJson(response);
    } catch (e) {
      print('Create playlist error: $e');
      return null;
    }
  }

  Future<bool> updatePlaylist({
    required String playlistId,
    String? name,
    String? coverUrl,
  }) async {
    try {
      await _supabase
          .from('playlists')
          .update({
            if (name != null) 'name': name,
            if (coverUrl != null) 'cover_url': coverUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', playlistId);

      return true;
    } catch (e) {
      print('Update playlist error: $e');
      return false;
    }
  }

  Future<bool> deletePlaylist(String playlistId) async {
    try {
      await _supabase.from('playlists').delete().eq('id', playlistId);
      return true;
    } catch (e) {
      print('Delete playlist error: $e');
      return false;
    }
  }

  Future<List<SongModel>> getPlaylistSongs(String playlistId) async {
    try {
      final response = await _supabase
          .from('playlist_songs')
          .select('song_id, songs(*)')
          .eq('playlist_id', playlistId)
          .order('position');

      return (response as List)
          .map((item) => SongModel.fromJson(item['songs']))
          .toList();
    } catch (e) {
      print('Get playlist songs error: $e');
      return [];
    }
  }

  Future<bool> addSongToPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    try {
      await _supabase.from('playlist_songs').insert({
        'playlist_id': playlistId,
        'song_id': songId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Add song to playlist error: $e');
      return false;
    }
  }

  Future<bool> removeSongFromPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    try {
      await _supabase
          .from('playlist_songs')
          .delete()
          .eq('playlist_id', playlistId)
          .eq('song_id', songId);

      return true;
    } catch (e) {
      print('Remove song from playlist error: $e');
      return false;
    }
  }
}
