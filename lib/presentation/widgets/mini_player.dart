import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/songs_provider.dart';
import '../../providers/audio_provider.dart';
import '../screens/player/full_player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final audioService = ref.watch(audioServiceProvider);
    final isPlayingAsync = ref.watch(isPlayingProvider);

    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
        );
      },
      child: Container(
        height: 70,
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (currentSong.coverUrl != null)
              Image.network(
                currentSong.coverUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
            else
              const Icon(Icons.music_note, size: 50),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSong.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentSong.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            isPlayingAsync.when(
              data: (isPlaying) => IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
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
              error: (_, __) => const Icon(Icons.error),
            ),
          ],
        ),
      ),
    );
  }
}
