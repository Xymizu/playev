class RepostModel {
  final String id;
  final String userId;
  final String songId;
  final DateTime createdAt;

  RepostModel({
    required this.id,
    required this.userId,
    required this.songId,
    required this.createdAt,
  });

  factory RepostModel.fromJson(Map<String, dynamic> json) {
    return RepostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      songId: json['song_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'song_id': songId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
