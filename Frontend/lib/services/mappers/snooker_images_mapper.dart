import 'package:snooker_flutter/entities/snooker_image.dart';

List<SnookerImage> mapSnookerImages(List<dynamic> data) {
  return data.map((json) {
    return SnookerImage(
      id: json['photo'],
      photo: json['photo'],
    );
  }).toList();
}