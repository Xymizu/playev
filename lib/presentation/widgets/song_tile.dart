import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../providers/songs_provider.dart';
import '../../providers/queue_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/repost_provider.dart';
import '../../providers/auth_providers.dart';
import '../../providers/audio_provider.dart';

class SongTile extends ConsumerWidget {
  final SongModel song;
  final List<SongModel>? allSongs;

  const SongTile({super.key, required this.song, this.allSongs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isFavoriteAsync = ref.watch(isFavoriteSongProvider(song.id));
    final isRepostedAsync = ref.watch(isRepostedProvider(song.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[900],
      child: Column(
        children: [
          ListTile(
            leading: song.coverUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      song.coverUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
            title: Text(
              song.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.artist, style: TextStyle(color: Colors.grey[400])),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.play_arrow, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${song.playCount}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.favorite, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${song.likesCount}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              _formatDuration(song.duration ?? 0),
              style: TextStyle(color: Colors.grey[400]),
            ),
            onTap: () async {
              ref.read(currentSongProvider.notifier).state = song;

              if (allSongs != null) {
                final songIndex = allSongs!.indexOf(song);
                ref
                    .read(queueProvider.notifier)
                    .setQueue(
                      allSongs!,
                      startIndex: songIndex >= 0 ? songIndex : 0,
                    );
              }

              // Play the song without navigating
              final audioService = ref.read(audioServiceProvider);
              await audioService.play(song.audioUrl, song: song);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Like button
                isFavoriteAsync.when(
                  data: (isFav) => IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.grey[400],
                      size: 20,
                    ),
                    onPressed: user == null
                        ? null
                        : () async {
                            final favoriteService = ref.read(
                              favoritesServiceProvider,
                            );
                            await favoriteService.toggleFavorite(
                              userId: user.id,
                              songId: song.id,
                            );
                            ref.invalidate(isFavoriteSongProvider(song.id));
                            ref.invalidate(approvedSongsProvider);
                          },
                  ),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Icon(Icons.error, size: 20),
                ),

                // Repost button
                isRepostedAsync.when(
                  data: (isRepost) => IconButton(
                    icon: Icon(
                      Icons.repeat,
                      color: isRepost ? Colors.green : Colors.grey[400],
                      size: 20,
                    ),
                    onPressed: user == null
                        ? null
                        : () async {
                            final repostService = ref.read(
                              repostServiceProvider,
                            );
                            await repostService.toggleRepost(
                              userId: user.id,
                              songId: song.id,
                            );
                            ref.invalidate(isRepostedProvider(song.id));
                          },
                  ),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Icon(Icons.error, size: 20),
                ),

                // Share button placeholder
                IconButton(
                  icon: Icon(Icons.share, color: Colors.grey[400], size: 20),
                  onPressed: () {
                    // TODO: implement share
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
