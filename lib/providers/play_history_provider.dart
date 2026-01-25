import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/song_model.dart';
import '../data/services/play_history_service.dart';
import 'auth_providers.dart';

final playHistoryServiceProvider = Provider<PlayHistoryService>(
  (ref) => PlayHistoryService(),
);

final recentlyPlayedProvider = FutureProvider<List<SongModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final service = ref.watch(playHistoryServiceProvider);
  return await service.getRecentlyPlayed(user.id, limit: 20);
});
