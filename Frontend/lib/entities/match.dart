
import 'package:snooker_flutter/entities/user.dart';

class Match {
  final String? id;
  final String? matchDatetime;
  final bool? cancelled;
  final bool? public;
  final int? frames;
  final int? localFrames;
  final int? visitorFrames;
  final double? localStartElo;
  final double? visitorStartElo;
  final double? localEndElo;
  final double? visitorEndElo;
  final String? location;
  final String? distance;
  final bool? localResultAgreed;
  final bool? visitorResultAgreed;
  final User? local;
  final User? visitor;

  Match({
    required this.id,
    required this.matchDatetime,
    required this.cancelled,
    required this.public,
    required this.location,
    required this.frames,
    this.localFrames,
    this.visitorFrames,
    this.localStartElo, 
    this.visitorStartElo, 
    this.localEndElo, 
    this.visitorEndElo, 
    required this.localResultAgreed, 
    required this.visitorResultAgreed, 
    this.distance, 
    required this.local,
    this.visitor, 
  });
}
