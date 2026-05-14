/// A record of a single completed game run.
class RunRecord {
  final int score;
  final DateTime playedAt;
  final String skinId;       // which skin was active
  final int durationSeconds; // how long the run lasted

  RunRecord({
    required this.score,
    required this.playedAt,
    required this.skinId,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
    'score':           score,
    'playedAt':        playedAt.toIso8601String(),
    'skinId':          skinId,
    'durationSeconds': durationSeconds,
  };

  factory RunRecord.fromJson(Map<String, dynamic> json) => RunRecord(
        score:           json['score'] as int,
        playedAt:        DateTime.parse(json['playedAt'] as String),
        skinId:          json['skinId'] as String? ?? 'classic',
        durationSeconds: json['durationSeconds'] as int? ?? 0,
      );
}