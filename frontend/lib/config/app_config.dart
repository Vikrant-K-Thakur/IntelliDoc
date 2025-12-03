// config/app_config.dart
import 'package:flutter/material.dart';

class AppConfig {
  static const MaterialColor primaryColor = Colors.blue; 
  static const String fontFamily = 'Inter';
  
  static ThemeData get theme => ThemeData(
    primarySwatch: primaryColor,
    fontFamily: fontFamily,
  );
}
