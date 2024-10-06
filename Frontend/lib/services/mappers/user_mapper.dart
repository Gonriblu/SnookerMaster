import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/entities/user.dart';

List<User> mapUsers(List<dynamic> data) {
  return data.map((json) {
    return User(
      id: json['id'],
      profilePhoto: '${Environment.root}/${json['profile_photo']}',
      email: json['email'],
      name: json['name'],
      surname: json['surname'],
      genre: json['genre'],
      bornDate: json['born_date'],
      elo: double.parse(json['elo'].toStringAsFixed(2)),
    );
  }).toList();
}

User mapUser(Map<String, dynamic> data) {
  User project = User(
    id: data['id'],
    email: data['email'],
    profilePhoto: '${Environment.root}/${data['profile_photo']}',
    name: data['name'],
    surname: data['surname'],
    genre: data['genre'],
    bornDate: data['born_date'],
    elo: double.parse(data['elo'].toStringAsFixed(2)),
    lastMatchesInfo: (data['last_matches_info'] as Map<String, dynamic>?)
        ?.entries
        .map((entry) => Map<String, dynamic>.from(entry.value))
        .toList(),
  );

  return project;
}
