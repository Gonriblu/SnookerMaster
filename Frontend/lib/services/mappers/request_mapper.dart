import 'package:snooker_flutter/entities/request.dart';
import 'package:snooker_flutter/entities/request_response.dart';
import 'package:snooker_flutter/services/mappers/user_mapper.dart';
import 'package:snooker_flutter/services/mappers/match_mapper.dart';

// Función para formatear la fecha
String formatDateTime(String dateTime) {
  final parsedDate = DateTime.parse(dateTime);
  
  // Extraer los componentes de la fecha y hora
  String day = parsedDate.day.toString().padLeft(2, '0'); // Día con dos dígitos
  String month = parsedDate.month.toString().padLeft(2, '0'); // Mes con dos dígitos
  String year = parsedDate.year.toString();
  String hour = parsedDate.hour.toString().padLeft(2, '0'); // Hora con dos dígitos
  String minute = parsedDate.minute.toString().padLeft(2, '0'); // Minuto con dos dígitos
  
  // Retornar en el formato deseado: "dd/MM/yyyy HH:mm"
  return "$day/$month/$year $hour:$minute";
}

Request mapRequest(Map<String, dynamic> json) {

  return Request(
    id: json['id'],
    requestDatetime: formatDateTime(json['request_datetime']),
    status: json['request_status'], 
    match: mapMatch(json['match']), 
    inviter: mapUser(json['inviter']),  
    receiver: mapUser(json['receiver']),
  );
}

RequestsResponse mapRequests(Map<String, dynamic> response) {
  List<Request> sentRequests = [];
  List<Request> receivedRequests = [];
  if (response['sent_requests'] is List) {
    sentRequests = (response['sent_requests'] as List)
        .map((json) => mapRequest(json))
        .toList();
  }

  if (response['received_requests'] is List) {
    receivedRequests = (response['received_requests'] as List)
        .map((json) => mapRequest(json))
        .toList();
  }

  return RequestsResponse(
    sentRequests: sentRequests,
    receivedRequests: receivedRequests,
  );
}