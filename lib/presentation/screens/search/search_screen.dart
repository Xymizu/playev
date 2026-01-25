import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/songs_provider.dart';
import '../../widgets/song_tile.dart';

final searchFilterProvider = StateProvider<String>((ref) => 'all');

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final filter = ref.watch(searchFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search songs...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
          autofocus: true,
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    value: 'all',
                    selected: filter == 'all',
                    onSelected: () {
                      ref.read(searchFilterProvider.notifier).state = 'all';
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Most Played',
                    value: 'plays',
                    selected: filter == 'plays',
                    onSelected: () {
                      ref.read(searchFilterProvider.notifier).state = 'plays';
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Most Liked',
                    value: 'likes',
                    selected: filter == 'likes',
                    onSelected: () {
                      ref.read(searchFilterProvider.notifier).state = 'likes';
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Recent',
                    value: 'recent',
                    selected: filter == 'recent',
                    onSelected: () {
                      ref.read(searchFilterProvider.notifier).state = 'recent';
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: query.isEmpty
                ? const Center(child: Text('Start typing to search'))
                : searchResults.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                    data: (songs) {
                      if (songs.isEmpty) {
                        return const Center(child: Text('No results found'));
                      }

                      // Apply filter
                      var filteredSongs = List.of(songs);
                      if (filter == 'plays') {
                        filteredSongs.sort(
                          (a, b) => b.playCount.compareTo(a.playCount),
                        );
                      } else if (filter == 'likes') {
                        filteredSongs.sort(
                          (a, b) => b.likesCount.compareTo(a.likesCount),
                        );
                      } else if (filter == 'recent') {
                        filteredSongs.sort(
                          (a, b) => b.createdAt.compareTo(a.createdAt),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredSongs.length,
                        itemBuilder: (context, index) {
                          return SongTile(
                            song: filteredSongs[index],
                            allSongs: filteredSongs,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}
