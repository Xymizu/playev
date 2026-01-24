import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/song_model.dart';

class UploadService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // Upload audio file ke Supabase Storage
  Future<String> uploadAudioFile(File file) async {
    try {
      print('📤 Starting audio upload...');
      final fileName = '${_uuid.v4()}.mp3';
      final path = 'audio/$fileName';
      print('📁 Audio path: $path');

      final bytes = await file.readAsBytes();
      print('📦 File size: ${bytes.length} bytes');

      await _supabase.storage
          .from('songs')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'audio/mpeg'),
          );

      final url = _supabase.storage.from('songs').getPublicUrl(path);
      print('✅ Audio uploaded: $url');
      return url;
    } catch (e) {
      print('❌ Audio upload error: $e');
      throw Exception('Failed to upload audio: $e');
    }
  }

  // Upload cover image ke Supabase Storage
  Future<String?> uploadCoverImage(File? file) async {
    if (file == null) return null;

    try {
      print('📤 Starting cover upload...');
      final fileName = '${_uuid.v4()}.jpg';
      final path = 'covers/$fileName';
      print('📁 Cover path: $path');

      final bytes = await file.readAsBytes();
      print('📦 Image size: ${bytes.length} bytes');

      await _supabase.storage
          .from('songs')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final url = _supabase.storage.from('songs').getPublicUrl(path);
      print('✅ Cover uploaded: $url');
      return url;
    } catch (e) {
      print('❌ Cover upload error: $e');
      throw Exception('Failed to upload cover: $e');
    }
  }

  // Submit song dengan status pending
  Future<SongModel> submitSong({
    required String title,
    required String artist,
    String? album,
    required String audioUrl,
    String? coverUrl,
    required int duration,
  }) async {
    try {
      print('📝 Submitting song to database...');
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      print('👤 User ID: $userId');
      print('🎵 Title: $title');
      print('🎤 Artist: $artist');

      final data = await _supabase
          .from('songs')
          .insert({
            'title': title,
            'artist': artist,
            'album': album,
            'audio_url': audioUrl,
            'cover_url': coverUrl,
            'duration': duration,
            'uploaded_by': userId,
            'status': 'pending', // Admin harus approve dulu
          })
          .select()
          .single();

      print('✅ Song submitted successfully!');
      return SongModel.fromJson(data);
    } catch (e) {
      print('❌ Song submission error: $e');
      throw Exception('Failed to submit song: $e');
    }
  }

  // Admin: Approve song
  Future<void> approveSong(String songId) async {
    try {
      await _supabase
          .from('songs')
          .update({'status': 'approved', 'rejection_reason': null})
          .eq('id', songId);
    } catch (e) {
      throw Exception('Failed to approve song: $e');
    }
  }

  // Admin: Reject song with reason
  Future<void> rejectSong(String songId, {String? reason}) async {
    try {
      await _supabase
          .from('songs')
          .update({'status': 'rejected', 'rejection_reason': reason})
          .eq('id', songId);
    } catch (e) {
      throw Exception('Failed to reject song: $e');
    }
  }

  // Admin: Get pending songs
  Future<List<SongModel>> getPendingSongs() async {
    try {
      final response = await _supabase
          .from('songs')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SongModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending songs: $e');
    }
  }

  // User: Get my uploads (all statuses)
  Future<List<SongModel>> getMyUploads() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await _supabase
          .from('songs')
          .select()
          .eq('uploaded_by', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SongModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get uploads: $e');
    }
  }
}
