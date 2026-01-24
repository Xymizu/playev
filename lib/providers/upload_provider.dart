import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/upload_service.dart';
import '../data/models/song_model.dart';

final uploadServiceProvider = Provider((ref) => UploadService());

final pendingSongsProvider = FutureProvider<List<SongModel>>((ref) async {
  final uploadService = ref.watch(uploadServiceProvider);
  return uploadService.getPendingSongs();
});

// Provider untuk uploads user sendiri
final myUploadsProvider = FutureProvider<List<SongModel>>((ref) async {
  final uploadService = ref.watch(uploadServiceProvider);
  return uploadService.getMyUploads();
});
