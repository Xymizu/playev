import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/song_model.dart';

// Queue untuk playlist
class QueueState {
  final List<SongModel> songs;
  final int currentIndex;
  final bool isShuffled;
  final RepeatMode repeatMode;
  final List<int>? shuffledIndices; // For shuffle mode

  QueueState({
    required this.songs,
    required this.currentIndex,
    this.isShuffled = false,
    this.repeatMode = RepeatMode.off,
    this.shuffledIndices,
  });

  QueueState copyWith({
    List<SongModel>? songs,
    int? currentIndex,
    bool? isShuffled,
    RepeatMode? repeatMode,
    List<int>? shuffledIndices,
  }) {
    return QueueState(
      songs: songs ?? this.songs,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffledIndices: shuffledIndices ?? this.shuffledIndices,
    );
  }

  SongModel? get currentSong =>
      songs.isEmpty ? null : songs[currentIndex.clamp(0, songs.length - 1)];

  bool get hasNext {
    if (repeatMode == RepeatMode.one) return true;
    if (repeatMode == RepeatMode.all) return true;
    return currentIndex < songs.length - 1;
  }

  bool get hasPrevious {
    if (repeatMode == RepeatMode.all) return true;
    return currentIndex > 0;
  }
}

enum RepeatMode { off, one, all }

class QueueNotifier extends StateNotifier<QueueState> {
  QueueNotifier() : super(QueueState(songs: [], currentIndex: 0));

  // Set queue dari list songs
  void setQueue(List<SongModel> songs, {int startIndex = 0}) {
    state = QueueState(
      songs: songs,
      currentIndex: startIndex,
      isShuffled: false,
      repeatMode: state.repeatMode,
    );
  }

  // Set current song by index
  void setCurrentIndex(int index) {
    if (index >= 0 && index < state.songs.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  // Play next song
  int? next() {
    if (state.songs.isEmpty) return null;

    if (state.repeatMode == RepeatMode.one) {
      return state.currentIndex; // Repeat current song
    }

    int nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.songs.length) {
      if (state.repeatMode == RepeatMode.all) {
        nextIndex = 0; // Loop to start
      } else {
        return null; // No next song
      }
    }

    state = state.copyWith(currentIndex: nextIndex);
    return nextIndex;
  }

  // Play previous song
  int? previous() {
    if (state.songs.isEmpty) return null;

    int prevIndex = state.currentIndex - 1;

    if (prevIndex < 0) {
      if (state.repeatMode == RepeatMode.all) {
        prevIndex = state.songs.length - 1; // Loop to end
      } else {
        return null; // No previous song
      }
    }

    state = state.copyWith(currentIndex: prevIndex);
    return prevIndex;
  }

  // Toggle shuffle
  void toggleShuffle() {
    if (state.isShuffled) {
      // Turn off shuffle
      state = state.copyWith(isShuffled: false, shuffledIndices: null);
    } else {
      // Turn on shuffle
      final indices = List<int>.generate(state.songs.length, (i) => i);
      final currentSong = state.currentSong;
      indices.shuffle();

      // Make sure current song stays at current position
      if (currentSong != null) {
        final currentSongIndex = indices.indexOf(state.currentIndex);
        if (currentSongIndex != -1) {
          indices.removeAt(currentSongIndex);
          indices.insert(0, state.currentIndex);
        }
      }

      state = state.copyWith(
        isShuffled: true,
        shuffledIndices: indices,
        currentIndex: 0,
      );
    }
  }

  // Toggle repeat mode
  void toggleRepeat() {
    RepeatMode newMode;
    switch (state.repeatMode) {
      case RepeatMode.off:
        newMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        newMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        newMode = RepeatMode.off;
        break;
    }
    state = state.copyWith(repeatMode: newMode);
  }
}

final queueProvider = StateNotifierProvider<QueueNotifier, QueueState>((ref) {
  return QueueNotifier();
});
