
import 'package:snooker_flutter/entities/match.dart';
import 'package:snooker_flutter/entities/user.dart';

class Request {
  final String? id;
  final String? requestDatetime;
  final Match? match;
  final User? receiver;
  final User? inviter;
  final String? status;

  Request({
    required this.id,
    required this.requestDatetime,
    required this.match,
    required this.receiver,
    required this.inviter,
    required this.status,
  });
}
