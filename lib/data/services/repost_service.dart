import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song_model.dart';

class RepostService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Check if user reposted
  Future<bool> isReposted({
    required String userId,
    required String songId,
  }) async {
    try {
      final response = await _supabase
          .from('reposts')
          .select()
          .eq('user_id', userId)
          .eq('song_id', songId);

      return (response as List).isNotEmpty;
    } catch (e) {
      print('Check repost error: $e');
      return false;
    }
  }

  // Toggle repost
  Future<bool> toggleRepost({
    required String userId,
    required String songId,
  }) async {
    try {
      final isReposted = await this.isReposted(userId: userId, songId: songId);

      if (isReposted) {
        await _supabase
            .from('reposts')
            .delete()
            .eq('user_id', userId)
            .eq('song_id', songId);
        return false;
      } else {
        await _supabase.from('reposts').insert({
          'user_id': userId,
          'song_id': songId,
          'created_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
    } catch (e) {
      print('Toggle repost error: $e');
      rethrow;
    }
  }

  // Get user reposts
  Future<List<SongModel>> getUserReposts(String userId) async {
    try {
      final response = await _supabase
          .from('reposts')
          .select('song_id, songs(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => SongModel.fromJson(item['songs']))
          .toList();
    } catch (e) {
      print('Get user reposts error: $e');
      return [];
    }
  }

  // Get repost count for song
  Future<int> getRepostCount(String songId) async {
    try {
      final response = await _supabase
          .from('reposts')
          .select()
          .eq('song_id', songId);

      return (response as List).length;
    } catch (e) {
      print('Get repost count error: $e');
      return 0;
    }
  }
}
