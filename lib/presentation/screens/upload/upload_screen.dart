import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import '../../../data/services/upload_service.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  final _uploadService = UploadService();

  File? _audioFile;
  File? _coverFile;
  int? _audioDuration;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      print('🎵 Picking audio file...');
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        print('✅ Audio file selected: ${file.path}');
        setState(() => _audioFile = file);

        // Get duration
        final player = AudioPlayer();
        try {
          await player.setFilePath(file.path);
          final duration = player.duration;
          if (duration != null) {
            setState(() => _audioDuration = duration.inSeconds);
            print('⏱️ Duration: ${duration.inSeconds} seconds');
          }
        } finally {
          await player.dispose();
        }
      } else {
        print('❌ No audio file selected');
      }
    } catch (e) {
      print('❌ Error picking audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting audio: $e')));
      }
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      print('🖼️ Picking cover image...');
      final picker = ImagePicker();
      final result = await picker.pickImage(source: ImageSource.gallery);

      if (result != null) {
        print('✅ Image selected: ${result.path}');
        setState(() => _coverFile = File(result.path));
      } else {
        print('❌ No image selected');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an audio file')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      print('🚀 Starting upload process...');

      // Upload files
      print('⬆️ Uploading audio file...');
      final audioUrl = await _uploadService.uploadAudioFile(_audioFile!);
      print('✅ Audio uploaded: $audioUrl');

      String? coverUrl;
      if (_coverFile != null) {
        print('⬆️ Uploading cover image...');
        coverUrl = await _uploadService.uploadCoverImage(_coverFile);
        print('✅ Cover uploaded: $coverUrl');
      }

      // Submit song
      print('⬆️ Submitting song metadata...');
      await _uploadService.submitSong(
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        album: _albumController.text.trim().isEmpty
            ? null
            : _albumController.text.trim(),
        audioUrl: audioUrl,
        coverUrl: coverUrl,
        duration: _audioDuration ?? 0,
      );

      if (mounted) {
        print('🎉 Upload complete!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song submitted! Waiting for admin approval.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Music')),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cover Image
                    GestureDetector(
                      onTap: _pickCoverImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _coverFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _coverFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, size: 64),
                                  SizedBox(height: 8),
                                  Text('Tap to select cover image'),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Song Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Artist
                    TextFormField(
                      controller: _artistController,
                      decoration: const InputDecoration(
                        labelText: 'Artist *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Artist is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Album
                    TextFormField(
                      controller: _albumController,
                      decoration: const InputDecoration(
                        labelText: 'Album (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Audio File
                    OutlinedButton.icon(
                      onPressed: _pickAudioFile,
                      icon: const Icon(Icons.audiotrack),
                      label: Text(
                        _audioFile != null
                            ? 'Audio: ${_audioFile!.path.split('/').last}'
                            : 'Select Audio File *',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    if (_audioDuration != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Duration: ${_audioDuration! ~/ 60}:${(_audioDuration! % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Submit Button
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('Submit for Approval'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
