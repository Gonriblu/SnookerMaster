import 'package:snooker_flutter/entities/request.dart';

class RequestsResponse {
  final List<Request> sentRequests;
  final List<Request> receivedRequests;

  RequestsResponse({
    required this.sentRequests,
    required this.receivedRequests,
  });
}