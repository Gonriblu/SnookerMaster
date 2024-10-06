import 'package:snooker_flutter/entities/play_statistics.dart';

List<Play> mapPlays(List<dynamic> data) {
  return data.map((json) {
    return Play(
      id: json['id'],
      distance: json['distance'],
      angle: json['angle'],
      photo: json['photo'],
      success: json['success'],
      firstColorBall: json['first_color_ball'],
      secondColorBall: json['second_color_ball'],
      video: json['processed_video'],
      pocket: _translatePocket(json['pocket']), // Traducir pocket
    );
  }).toList();
}

Play mapPlay(Map<String, dynamic> data) {
  // Mapea los datos del proyecto principal
  Play play = Play(
    id: data['id'],
    angle: data['angle'],
    distance: data['distance'],
    success: data['success'],
    firstColorBall: data['first_color_ball'],
    secondColorBall: data['second_color_ball'],
    photo: data['photo'],
    video: data['processed_video'],
    pocket: _translatePocket(data['pocket']), // Traducir pocket
  );

  return play;
}

// Función auxiliar para traducir el valor de pocket a español
String _translatePocket(String pocket) {
  switch (pocket) {
    case 'BottomLeft':
      return 'Inferior izquierda';
    case 'BottomRight':
      return 'Inferior derecha';
    case 'MediumLeft':
      return 'Medio izquierda';
    case 'MediumRight':
      return 'Medio derecha';
    case 'TopLeft':
      return 'Superior izquierda';
    case 'TopRight':
      return 'Superior derecha';
    default:
      return pocket; // En caso de que no se reconozca el valor, se retorna tal cual
  }
}
