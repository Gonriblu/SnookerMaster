import 'package:snooker_flutter/entities/general_statistic.dart';
import 'package:snooker_flutter/entities/project_statistics.dart';

GeneralStatistics mapGeneralStatistics(dynamic data) {
  final json = data as Map<String, dynamic>;
  return GeneralStatistics(
    totalPlays: (json['total_plays'] as num?)?.toDouble(),
    successRate: (json['success_rate'] as num?)?.toDouble(),
    angleMean: (json['angle_mean'] as num?)?.toDouble(),
    angleMin: (json['angle_min'] as num?)?.toDouble(),
    angleMax: (json['angle_max']  as num?)?.toDouble(),
    angleStdev: (json['angle_stdev'] as num?)?.toDouble(),
    distanceMean: (json['distance_mean'] as num?)?.toDouble(),
    distanceMin: (json['distance_min'] as num?)?.toDouble(),
    distanceMax: (json['distance_max'] as num?)?.toDouble(),
    distanceStdev: (json['distance_stdev'] as num?)?.toDouble(),
    successCount: (json['success_count'] as num?)?.toDouble(),
    failCount: (json['fail_count'] as num?)?.toDouble(),
    angleMeanSuccess: (json['angle_mean_success'] as num?)?.toDouble(),
    distanceMeanSuccess: (json['distance_mean_success'] as num?)?.toDouble(),
  );
}
ProjectStatistics mapProjectStatistics(dynamic data) {
  final json = data as Map<String, dynamic>;
  return ProjectStatistics(
    totalPlays: (json['total_plays'] as num?)?.toDouble(),
    successRate: (json['success_rate'] as num?)?.toDouble(),
    angleMean: (json['angle_mean'] as num?)?.toDouble(),
    angleMin: (json['angle_min'] as num?)?.toDouble(),
    angleMax: (json['angle_max']  as num?)?.toDouble(),
    angleStdev: (json['angle_stdev'] as num?)?.toDouble(),
    distanceMean: (json['distance_mean'] as num?)?.toDouble(),
    distanceMin: (json['distance_min'] as num?)?.toDouble(),
    distanceMax: (json['distance_max'] as num?)?.toDouble(),
    distanceStdev: (json['distance_stdev'] as num?)?.toDouble(),
    successCount: (json['success_count'] as num?)?.toDouble(),
    failCount: (json['fail_count'] as num?)?.toDouble(),
    angleMeanSuccess: (json['angle_mean_success'] as num?)?.toDouble(),
    distanceMeanSuccess: (json['distance_mean_success'] as num?)?.toDouble(),
  );
}