import 'package:flutter/material.dart';
import 'package:snooker_flutter/config/theme/app_theme.dart';

class TextStyles {
  final Color fontColor;

  const TextStyles({this.fontColor = Colors.black});

  static const TextStyle header = TextStyle(
      fontFamily: 'Montserrat',
      color: AppColor.white,
      fontWeight: FontWeight.bold,
      fontSize: 36.0);

  static const TextStyle form = TextStyle(
      fontFamily: 'Montserrat',
      color: AppColor.white,
      fontWeight: FontWeight.bold);
}