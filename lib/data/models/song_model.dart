class SongModel {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? genre;
  final int? duration;
  final String? coverUrl;
  final String audioUrl;
  final String uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final String? rejectionReason;
  final int playCount;
  final int likesCount;
  final bool downloadEnabled;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.genre,
    this.duration,
    this.coverUrl,
    required this.audioUrl,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.rejectionReason,
    this.playCount = 0,
    this.likesCount = 0,
    this.downloadEnabled = false,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      genre: json['genre'] as String?,
      duration: json['duration'] as int?,
      coverUrl: json['cover_url'] as String?,
      audioUrl: json['audio_url'] as String,
      uploadedBy: json['uploaded_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      playCount: json['play_count'] as int? ?? 0,
      likesCount: json['likes_count'] as int? ?? 0,
      downloadEnabled: json['download_enabled'] as bool? ?? false,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'duration': duration,
      'cover_url': coverUrl,
      'audio_url': audioUrl,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
      'rejection_reason': rejectionReason,
      'play_count': playCount,
      'likes_count': likesCount,
      'download_enabled': downloadEnabled,
    };
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? duration,
    String? coverUrl,
    String? audioUrl,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? rejectionReason,
    int? playCount,
    int? likesCount,
    bool? downloadEnabled,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      duration: duration ?? this.duration,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      playCount: playCount ?? this.playCount,
      likesCount: likesCount ?? this.likesCount,
      downloadEnabled: downloadEnabled ?? this.downloadEnabled,
    );
  }
}
