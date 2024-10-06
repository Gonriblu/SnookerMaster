class GeneralStatistics {
  final double? totalPlays;
  final double? successRate;
  final double? angleMean;
  final double? angleMin;
  final double? angleMax;
  final double? angleStdev;
  final double? distanceMean;
  final double? distanceMin;
  final double? distanceMax;
  final double? distanceStdev;
  final double? successCount;
  final double? failCount;
  final double? angleMeanSuccess;
  final double? distanceMeanSuccess;

  GeneralStatistics({
    required this.totalPlays,
    required this.successRate,
    required this.angleMean,
    required this.angleMin,
    required this.angleMax,
    required this.angleStdev,
    required this.distanceMean,
    required this.distanceMin,
    required this.distanceMax,
    required this.distanceStdev,
    required this.successCount,
    required this.failCount,
    required this.angleMeanSuccess,
    required this.distanceMeanSuccess,
  });
}