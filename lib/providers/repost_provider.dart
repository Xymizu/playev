import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/song_model.dart';
import '../data/services/repost_service.dart';
import 'auth_providers.dart';

final repostServiceProvider = Provider<RepostService>((ref) => RepostService());

final userRepostsProvider = FutureProvider<List<SongModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final service = ref.watch(repostServiceProvider);
  return await service.getUserReposts(user.id);
});

final isRepostedProvider = FutureProvider.family<bool, String>((
  ref,
  songId,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final service = ref.watch(repostServiceProvider);
  return await service.isReposted(userId: user.id, songId: songId);
});
