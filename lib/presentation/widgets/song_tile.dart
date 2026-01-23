import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../providers/songs_provider.dart';
import '../screens/player/full_player_screen.dart';

class SongTile extends ConsumerWidget {
  final SongModel song;

  const SongTile({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: song.coverUrl != null
          ? Image.network(
              song.coverUrl!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
          : const Icon(Icons.music_note, size: 50),
      title: Text(song.title),
      subtitle: Text(song.artist),
      trailing: Text(_formatDuration(song.duration ?? 0)),
      onTap: () {
        ref.read(currentSongProvider.notifier).state = song;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
