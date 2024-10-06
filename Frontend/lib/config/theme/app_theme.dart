
import 'package:flutter/material.dart';

List<Color> _myColors = [
const Color.fromARGB(255, 233, 26, 26),
const Color.fromARGB(255, 238, 219, 8),
const Color(0xFF0E0E0E),
const Color(0xFF49F222),
Colors.white,
];
class AppTheme{
  final int selectedColor;

  AppTheme({this.selectedColor = 0})
  : assert(selectedColor >=0 && selectedColor < _myColors.length , 
          'Colors must be between 0 and ${_myColors.length - 1}');

  ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _myColors[selectedColor]
    );
  }
}
class AppColor {
  static const Color purple = Color(0xFF514EB6);
  static const Color clearPurple = Color.fromARGB(255, 115, 112, 181);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0E0E0E);
  static const Color green = Color.fromARGB(255, 45, 139, 95);
  static const Color grayBackground = Color(0xFFE9EDEE);
}
