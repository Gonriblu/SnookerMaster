import 'package:snooker_flutter/entities/match.dart';
import 'package:snooker_flutter/services/mappers/user_mapper.dart';

// Función para formatear la fecha
String formatDateTime(String dateTime) {
  final parsedDate = DateTime.parse(dateTime);
  
  // Extraer los componentes de la fecha y hora
  String day = parsedDate.day.toString().padLeft(2, '0'); // Día con dos dígitos
  String month = parsedDate.month.toString().padLeft(2, '0'); // Mes con dos dígitos
  String year = parsedDate.year.toString();
  String hour = parsedDate.hour.toString().padLeft(2, '0'); // Hora con dos dígitos
  String minute = parsedDate.minute.toString().padLeft(2, '0'); // Minuto con dos dígitos
  
  // Retornar en el formato deseado: "dd-MM-yyyy HH:mm"
  return "$day/$month/$year $hour:$minute";
}

List<Match> mapMatches(List<dynamic> response) {
  if (response.isEmpty || response[0] is! List) {
    // Si la respuesta no contiene la lista esperada, devolvemos una lista vacía
    return [];
  }

  List<dynamic> matchesData = response[0]; // Obtenemos la lista de partidos

  return matchesData.map((json) {
    return Match(
      id: json['id'],
      matchDatetime: formatDateTime(json['match_datetime']), // Formatea la fecha
      cancelled: json['cancelled'],
      public: json['public'],
      location: json['formatted_location'],
      frames: json['frames'],
      localFrames: json['local_frames'] ?? 0,  
      visitorFrames: json['visitor_frames'] ?? 0,  
      localStartElo: json['local_start_match_elo'] ?? 0,
      visitorStartElo: json['visitor_start_match_elo'] ?? 0, 
      localEndElo: json['local_end_match_elo'] ?? 0,
      visitorEndElo: json['visitor_end_match_elo'] ?? 0, 
      distance: json['distance'], 
      localResultAgreed: json['local_result_agreed'], 
      visitorResultAgreed: json['visitor_result_agreed'], 
      visitor: json['visitor'] != null ? mapUser(json['visitor']) : null,  
      local: mapUser(json['local']),
    );
  }).toList();
}

Match mapMatch(Map<String, dynamic> data) {

  // Mapea los datos del proyecto principal
  Match match = Match(
      id: data['id'],
      matchDatetime: formatDateTime(data['match_datetime']), // Formatea la fecha
      cancelled: data['cancelled'],
      public: data['public'],
      location: data['formatted_location'],
      frames: data['frames'],
      localFrames: data['local_frames'] ?? 0,
      visitorFrames: data['visitor_frames'] ?? 0,
      localStartElo: data['local_start_match_elo'] ?? 0,
      visitorStartElo: data['visitor_start_match_elo'] ?? 0, 
      localEndElo: data['local_end_match_elo'] ?? 0,
      visitorEndElo: data['visitor_end_match_elo'] ?? 0, 
      localResultAgreed: data['local_result_agreed'], 
      visitorResultAgreed: data['visitor_result_agreed'], 
      distance: data['distance'],
      visitor: data['visitor'] != null ? mapUser(data['visitor']) : null,
      local: mapUser(data['local']));
  return match;
}
