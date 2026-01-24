import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/songs_provider.dart';
import '../../../providers/audio_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/queue_provider.dart';
import '../../../providers/auth_providers.dart';

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
  @override
  void initState() {
    super.initState();

    // Setup auto-play next song saat selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioService = ref.read(audioServiceProvider);
      audioService.setOnSongCompleteCallback(() {
        _playNextSong();
      });
    });
  }

  void _playNextSong() {
    final queue = ref.read(queueProvider);
    if (queue.hasNext) {
      final nextIndex = ref.read(queueProvider.notifier).next();
      if (nextIndex != null) {
        final nextSong = queue.songs[nextIndex];
        ref.read(currentSongProvider.notifier).state = nextSong;
        ref.read(audioServiceProvider).play(nextSong.audioUrl, song: nextSong);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider);
    final audioService = ref.watch(audioServiceProvider);
    final isPlayingAsync = ref.watch(isPlayingProvider);
    final positionAsync = ref.watch(positionProvider);
    final durationAsync = ref.watch(durationProvider);
    final queue = ref.watch(queueProvider);
    final isFavoriteAsync = currentSong != null
        ? ref.watch(isFavoriteSongProvider(currentSong.id))
        : const AsyncValue.data(false);

    if (currentSong == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No song selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          // Favorite button
          isFavoriteAsync.when(
            data: (isFavorite) => IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: () async {
                final favService = ref.read(favoritesServiceProvider);
                final user = ref.read(currentUserProvider);
                if (user == null) return;

                if (isFavorite) {
                  await favService.removeFromFavorites(
                    userId: user.id,
                    songId: currentSong.id,
                  );
                } else {
                  await favService.addToFavorites(
                    userId: user.id,
                    songId: currentSong.id,
                  );
                }
                // Invalidate both providers for real-time update
                ref.invalidate(isFavoriteSongProvider(currentSong.id));
                ref.invalidate(userFavoritesProvider);
              },
            ),
            loading: () => const IconButton(
              icon: Icon(Icons.favorite_border),
              onPressed: null,
            ),
            error: (_, __) => const IconButton(
              icon: Icon(Icons.favorite_border),
              onPressed: null,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (currentSong.coverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  currentSong.coverUrl!,
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.music_note, size: 100),
              ),
            const SizedBox(height: 40),
            Text(
              currentSong.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              currentSong.artist,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            positionAsync.when(
              data: (position) {
                final duration = durationAsync.value ?? Duration.zero;
                final progress = duration.inSeconds > 0
                    ? position.inSeconds / duration.inSeconds
                    : 0.0;
                return Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    final newPosition = Duration(
                      seconds: (value * duration.inSeconds).toInt(),
                    );
                    audioService.seek(newPosition);
                  },
                );
              },
              loading: () => Slider(value: 0, onChanged: null),
              error: (_, __) => Slider(value: 0, onChanged: null),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  positionAsync.when(
                    data: (position) =>
                        Text(_formatDuration(position.inSeconds)),
                    loading: () => Text('0:00'),
                    error: (_, __) => Text('0:00'),
                  ),
                  Text(_formatDuration(currentSong.duration ?? 0)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Shuffle button
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: queue.isShuffled
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  iconSize: 32,
                  onPressed: () {
                    ref.read(queueProvider.notifier).toggleShuffle();
                  },
                ),
                // Previous button
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 48,
                  onPressed: queue.hasPrevious
                      ? () async {
                          final prevIndex = ref
                              .read(queueProvider.notifier)
                              .previous();
                          if (prevIndex != null) {
                            final prevSong = queue.songs[prevIndex];
                            ref.read(currentSongProvider.notifier).state =
                                prevSong;
                            await audioService.play(
                              prevSong.audioUrl,
                              song: prevSong,
                            );
                          }
                        }
                      : null,
                ),
                isPlayingAsync.when(
                  data: (isPlaying) => IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                    ),
                    iconSize: 72,
                    onPressed: () async {
                      if (isPlaying) {
                        await audioService.pause();
                      } else {
                        if (!audioService.hasAudioSource) {
                          await audioService.play(
                            currentSong.audioUrl,
                            song: currentSong,
                          );
                        } else {
                          await audioService.resume();
                        }
                      }
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => IconButton(
                    icon: const Icon(Icons.play_circle_filled),
                    iconSize: 72,
                    onPressed: () async {
                      await audioService.play(
                        currentSong.audioUrl,
                        song: currentSong,
                      );
                    },
                  ),
                ),
                // Next button
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 48,
                  onPressed: queue.hasNext
                      ? () async {
                          final nextIndex = ref
                              .read(queueProvider.notifier)
                              .next();
                          if (nextIndex != null) {
                            final nextSong = queue.songs[nextIndex];
                            ref.read(currentSongProvider.notifier).state =
                                nextSong;
                            await audioService.play(
                              nextSong.audioUrl,
                              song: nextSong,
                            );
                          }
                        }
                      : null,
                ),
                // Repeat button
                IconButton(
                  icon: Icon(
                    queue.repeatMode == RepeatMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: queue.repeatMode != RepeatMode.off
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  iconSize: 32,
                  onPressed: () {
                    ref.read(queueProvider.notifier).toggleRepeat();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
