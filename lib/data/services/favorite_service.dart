import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song_model.dart';

class FavoriteService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<SongModel>> getUserFavorites(String userId) async {
    try {
      final response = await _supabase
          .from('favorites')
          .select('song_id, songs(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => SongModel.fromJson(item['songs']))
          .toList();
    } catch (e) {
      print('Get user favorites error: $e');
      return [];
    }
  }

  Future<bool> isFavorite({
    required String userId,
    required String songId,
  }) async {
    try {
      final response = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', userId)
          .eq('song_id', songId);

      return (response as List).isNotEmpty;
    } catch (e) {
      print('Check favorite error: $e');
      return false;
    }
  }

  Future<bool> addToFavorites({
    required String userId,
    required String songId,
  }) async {
    try {
      await _supabase.from('favorites').insert({
        'user_id': userId,
        'song_id': songId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Add to favorites error: $e');
      return false;
    }
  }

  Future<bool> removeFromFavorites({
    required String userId,
    required String songId,
  }) async {
    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('song_id', songId);

      return true;
    } catch (e) {
      print('Remove from favorites error: $e');
      return false;
    }
  }

  Future<bool> toggleFavorite({
    required String userId,
    required String songId,
  }) async {
    try {
      final isFav = await isFavorite(userId: userId, songId: songId);

      if (isFav) {
        return await removeFromFavorites(userId: userId, songId: songId);
      } else {
        return await addToFavorites(userId: userId, songId: songId);
      }
    } catch (e) {
      print('Toggle favorite error: $e');
      return false;
    }
  }
}
