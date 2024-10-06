import 'package:snooker_flutter/entities/play_statistics.dart';

class Project {
  final String? id;
  final String? name;
  final String? photo;
  final String? description;
  final int? totalPlays;
  final String? date;
  List<Play>? plays;

  Project({
    required this.id,
    required this.name,
    required this.photo,
    this.description,
    this.totalPlays,
    this.date,
    this.plays,
  });
}
