class Play {
  final String? id;
  final int? angle;
  final double? distance;
  final bool? success;
  final String? firstColorBall;
  final String? secondColorBall;
  final String? photo;
  final String? video;
  final String? pocket;

  Play({
    required this.id,
    required this.angle,
    required this.distance,
    required this.success,
    required this.firstColorBall,
    required this.secondColorBall,
    required this.photo,
    required this.pocket,
    this.video,
  });
  factory Play.fromJson(Map<String, dynamic> json) {
    return Play(
      id: json['id'],
      angle: json['angle'],
      photo: json['photo'],
      firstColorBall: json['first_color_ball'],
      secondColorBall: json['second_color_ball'],
      distance: json['distance'],
      success: json['success'],
      video: json['processed_video'],
      pocket: json['pocket'],
    );
  }
}
class PlayStatistics {
  final int? angle;
  final int? distance;
  final int? success;
  final int? colorBall;

  PlayStatistics({
    required this.angle,
    required this.distance,
    required this.success,
    required this.colorBall,
  });
}