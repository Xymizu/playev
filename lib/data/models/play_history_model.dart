class PlayHistoryModel {
  final String id;
  final String userId;
  final String songId;
  final DateTime playedAt;

  PlayHistoryModel({
    required this.id,
    required this.userId,
    required this.songId,
    required this.playedAt,
  });

  factory PlayHistoryModel.fromJson(Map<String, dynamic> json) {
    return PlayHistoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      songId: json['song_id'] as String,
      playedAt: DateTime.parse(json['played_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'song_id': songId,
      'played_at': playedAt.toIso8601String(),
    };
  }
}
