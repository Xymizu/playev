import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song_model.dart';
import '../models/play_history_model.dart';

class PlayHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Record play
  Future<void> recordPlay({
    required String userId,
    required String songId,
  }) async {
    try {
      await _supabase.from('play_history').insert({
        'user_id': userId,
        'song_id': songId,
        'played_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Record play error: $e');
    }
  }

  // Get recently played songs
  Future<List<SongModel>> getRecentlyPlayed(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('play_history')
          .select('song_id, songs(*)')
          .eq('user_id', userId)
          .order('played_at', ascending: false)
          .limit(limit);

      final seen = <String>{};
      final uniqueSongs = <SongModel>[];

      for (final item in response as List) {
        final songId = item['song_id'] as String;
        if (!seen.contains(songId)) {
          seen.add(songId);
          uniqueSongs.add(SongModel.fromJson(item['songs']));
        }
      }

      return uniqueSongs;
    } catch (e) {
      print('Get recently played error: $e');
      return [];
    }
  }

  // Get play history with timestamps
  Future<List<PlayHistoryModel>> getPlayHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('play_history')
          .select()
          .eq('user_id', userId)
          .order('played_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => PlayHistoryModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Get play history error: $e');
      return [];
    }
  }

  // Clear history
  Future<bool> clearHistory(String userId) async {
    try {
      await _supabase.from('play_history').delete().eq('user_id', userId);
      return true;
    } catch (e) {
      print('Clear history error: $e');
      return false;
    }
  }
}
