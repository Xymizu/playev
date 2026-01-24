import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song_model.dart';

class SongService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<SongModel>> getApprovedSongs() async {
    try {
      print('Fetching approved songs...');
      final response = await _supabase
          .from('songs')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      print('Response: $response');
      print('Response type: ${response.runtimeType}');

      final songs = (response as List).map((json) {
        print('Parsing song: $json');
        return SongModel.fromJson(json);
      }).toList();

      print('Total songs: ${songs.length}');
      return songs;
    } catch (e) {
      print('Get approved songs error: $e');
      rethrow;
    }
  }

  // Get all songs (for admin)
  Future<List<SongModel>> getAllSongs() async {
    try {
      final response = await _supabase
          .from('songs')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SongModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Get all songs error: $e');
      rethrow;
    }
  }

  Future<SongModel?> getSongById(String songId) async {
    try {
      final response = await _supabase
          .from('songs')
          .select()
          .eq('id', songId)
          .single();

      return SongModel.fromJson(response);
    } catch (e) {
      print('Get song by ID error: $e');
      return null;
    }
  }

  Future<List<SongModel>> getUserSongs(String userId) async {
    try {
      final response = await _supabase
          .from('songs')
          .select()
          .eq('uploaded_by', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SongModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Get user songs error: $e');
      return [];
    }
  }

  Future<SongModel?> uploadSong({
    required String title,
    required String artist,
    required String audioUrl,
    required String uploadedBy,
    String? album,
    String? genre,
    String? coverUrl,
    int? duration,
  }) async {
    try {
      final response = await _supabase
          .from('songs')
          .insert({
            'title': title,
            'artist': artist,
            'audio_url': audioUrl,
            'uploaded_by': uploadedBy,
            'album': album,
            'genre': genre,
            'cover_url': coverUrl,
            'duration': duration,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return SongModel.fromJson(response);
    } catch (e) {
      print('Upload song error: $e');
      return null;
    }
  }

  Future<List<SongModel>> searchSongs(String query) async {
    try {
      final response = await _supabase
          .from('songs')
          .select()
          .eq('status', 'approved')
          .or('title.ilike.%$query%,artist.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SongModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Search songs error: $e');
      return [];
    }
  }

  Future<List<SongModel>> getPendingSongs() async {
    try {
      final response = await _supabase
          .from('songs')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SongModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Get pending songs error: $e');
      return [];
    }
  }

  Future<bool> updateSongStatus(String songId, String status) async {
    try {
      await _supabase
          .from('songs')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', songId);

      return true;
    } catch (e) {
      print('Update song status error: $e');
      return false;
    }
  }

  Future<bool> deleteSong(String songId) async {
    try {
      await _supabase.from('songs').delete().eq('id', songId);
      return true;
    } catch (e) {
      print('Delete song error: $e');
      return false;
    }
  }
}
