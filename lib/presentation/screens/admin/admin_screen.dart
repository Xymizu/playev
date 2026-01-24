import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/upload_provider.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/songs_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../data/models/song_model.dart';
import '../../../data/services/audio_service.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(allSongsProvider);
    final pendingSongsAsync = ref.watch(pendingSongsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allSongsProvider);
              ref.invalidate(pendingSongsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allSongsProvider);
          ref.invalidate(pendingSongsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Text(
                'Welcome, Admin',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Here\'s what\'s happening with your music platform',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              songsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: $err'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(allSongsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (songs) {
                  final approved = songs
                      .where((s) => s.status == 'approved')
                      .length;
                  final rejected = songs
                      .where((s) => s.status == 'rejected')
                      .length;
                  final total = songs.length;

                  return Column(
                    children: [
                      // Main stats row
                      Row(
                        children: [
                          Expanded(
                            child: _BigStatCard(
                              icon: Icons.library_music,
                              title: 'Total Songs',
                              value: total.toString(),
                              subtitle: 'All time',
                              color: Colors.blue,
                              trend: total > 0 ? '+${total}' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: pendingSongsAsync.when(
                              data: (pending) => _BigStatCard(
                                icon: Icons.pending_actions,
                                title: 'Pending Review',
                                value: pending.length.toString(),
                                subtitle: 'Needs attention',
                                color: Colors.orange,
                                trend: pending.isNotEmpty
                                    ? '+${pending.length}'
                                    : null,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ReviewScreen(),
                                    ),
                                  );
                                },
                              ),
                              loading: () => const _BigStatCard(
                                icon: Icons.pending_actions,
                                title: 'Pending Review',
                                value: '...',
                                subtitle: 'Loading',
                                color: Colors.orange,
                              ),
                              error: (_, __) => const _BigStatCard(
                                icon: Icons.pending_actions,
                                title: 'Pending Review',
                                value: 'Error',
                                subtitle: 'Failed to load',
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Secondary stats row
                      Row(
                        children: [
                          Expanded(
                            child: _SmallStatCard(
                              icon: Icons.check_circle,
                              title: 'Approved',
                              value: approved.toString(),
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SmallStatCard(
                              icon: Icons.cancel,
                              title: 'Rejected',
                              value: rejected.toString(),
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SmallStatCard(
                              icon: Icons.trending_up,
                              title: 'Approval Rate',
                              value: total > 0
                                  ? '${((approved / total) * 100).toStringAsFixed(0)}%'
                                  : '0%',
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions
                      _SectionHeader(title: 'Quick Actions'),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.rate_review,
                        title: 'Review Pending Songs',
                        subtitle: pendingSongsAsync.when(
                          data: (p) => '${p.length} songs waiting for review',
                          loading: () => 'Loading...',
                          error: (_, __) => 'Error loading',
                        ),
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReviewScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.library_music,
                        title: 'Manage Songs',
                        subtitle: '$approved approved songs',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageSongsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Big stat card for main metrics
class _BigStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final String? trend;
  final VoidCallback? onTap;

  const _BigStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trend!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small stat card for secondary metrics
class _SmallStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _SmallStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Action card for quick actions
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// Section header
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

// Review Screen (moved from tab)
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingSongsAsync = ref.watch(pendingSongsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Pending Songs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pendingSongsProvider),
          ),
        ],
      ),
      body: pendingSongsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.refresh(pendingSongsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text('No pending songs', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'All caught up! 🎉',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return PendingSongTile(song: songs[index]);
            },
          );
        },
      ),
    );
  }
}

// Manage Songs Screen (moved from tab)
class ManageSongsScreen extends ConsumerWidget {
  const ManageSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(approvedSongsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Songs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(approvedSongsProvider),
          ),
        ],
      ),
      body: songsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(child: Text('No approved songs yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
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
                    : const Icon(Icons.music_note),
                title: Text(song.title),
                subtitle: Text(song.artist),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      // TODO: Implement delete
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Delete feature coming soon'),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PendingSongTile extends ConsumerWidget {
  final SongModel song;

  const PendingSongTile({super.key, required this.song});

  // Template pesan penolakan
  static const rejectionTemplates = [
    'Audio quality is too low. Please upload higher quality audio.',
    'Copyright issue detected. Please only upload original content or content you have rights to.',
    'Inappropriate content. Please follow our community guidelines.',
    'Incomplete metadata. Please provide complete song information.',
    'File format not supported. Please upload MP3 format.',
    'Audio file is corrupted or unplayable.',
  ];

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    String? selectedTemplate;
    String customMessage = '';
    bool useCustomMessage = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reject Song'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Song info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (song.coverUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              song.coverUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          const Icon(Icons.music_note, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                song.artist,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Rejection Reason:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Toggle antara template dan custom
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Template'),
                        icon: Icon(Icons.list),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Custom'),
                        icon: Icon(Icons.edit),
                      ),
                    ],
                    selected: {useCustomMessage},
                    onSelectionChanged: (Set<bool> selected) {
                      setState(() {
                        useCustomMessage = selected.first;
                        if (!useCustomMessage) customMessage = '';
                        if (useCustomMessage) selectedTemplate = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Template dropdown atau custom text field
                  if (!useCustomMessage)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Template',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedTemplate,
                      items: rejectionTemplates.map((template) {
                        return DropdownMenuItem(
                          value: template,
                          child: Text(
                            template,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedTemplate = value);
                      },
                    )
                  else
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Custom Rejection Message',
                        border: OutlineInputBorder(),
                        hintText: 'Enter your reason here...',
                      ),
                      maxLines: 4,
                      onChanged: (value) {
                        customMessage = value;
                      },
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final reason = useCustomMessage
                    ? customMessage
                    : selectedTemplate;

                if (reason == null || reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a rejection reason'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                try {
                  final uploadService = ref.read(uploadServiceProvider);
                  await uploadService.rejectSong(song.id, reason: reason);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Song rejected'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    // Refresh all relevant providers
                    ref.invalidate(pendingSongsProvider);
                    ref.invalidate(approvedSongsProvider);
                    ref.invalidate(allSongsProvider);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Send & Reject'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadService = ref.watch(uploadServiceProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (song.coverUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      song.coverUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, size: 30),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, size: 30),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (song.album != null)
                        Text(
                          song.album!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Preview button
            OutlinedButton.icon(
              onPressed: () async {
                final audioService = AudioPlayerService();
                if (audioService.isPlaying &&
                    audioService.player?.audioSource?.toString().contains(
                          song.audioUrl,
                        ) ==
                        true) {
                  await audioService.pause();
                } else {
                  await audioService.play(song.audioUrl, song: song);
                }
              },
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text(
                'Preview Audio',
                style: TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context, ref),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await uploadService.approveSong(song.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Song approved! ✅'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Refresh all relevant providers for real-time update
                        ref.invalidate(pendingSongsProvider);
                        ref.invalidate(approvedSongsProvider);
                        ref.invalidate(allSongsProvider);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
