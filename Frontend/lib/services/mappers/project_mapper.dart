import 'package:snooker_flutter/entities/play_statistics.dart';
import 'package:snooker_flutter/entities/project.dart';

List<Project> mapProjects(List<dynamic> data) {
  return data.map((json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      photo: json['photo'],
    );
  }).toList();
}

Project mapProject(Map<String, dynamic> data) {
  // Mapea los datos del proyecto principal
  Project project = Project(
    id: data['id'],
    name: data['name'],
    description: data['description'],
    date: data['creation_date'],
    photo: data['photo'],
    totalPlays: data['total_plays'],
    // Inicializa la lista de reproducción vacía
    plays: [],
  );

  // Mapea cada reproducción y agrégala a la lista de reproducción del proyecto
  if (data['plays'] != null) {
    List<dynamic> playsData = data['plays'];
    project.plays = playsData.map((play) => Play.fromJson(play)).toList();
  }

  return project;
}
