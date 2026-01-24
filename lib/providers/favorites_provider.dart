import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/song_model.dart';
import '../data/services/favorite_service.dart';
import 'auth_providers.dart';

final favoritesServiceProvider = Provider<FavoriteService>(
  (ref) => FavoriteService(),
);

final userFavoritesProvider = FutureProvider<List<SongModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final favoriteService = ref.watch(favoritesServiceProvider);
  return await favoriteService.getUserFavorites(user.id);
});

final isFavoriteSongProvider = FutureProvider.family<bool, String>((
  ref,
  songId,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final favoriteService = ref.watch(favoritesServiceProvider);
  return await favoriteService.isFavorite(userId: user.id, songId: songId);
});
