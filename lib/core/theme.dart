import 'package:flutter/material.dart';

class EatzyTheme {
  static const Color primary = Color(0xFFEF6C00); // brand orange
  static final ThemeData light = ThemeData(
    primaryColor: primary,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.orange,
    ).copyWith(secondary: Colors.deepOrange),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(120, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
    ),
    textTheme: TextTheme(bodyMedium: TextStyle(fontSize: 16)),
  );
}
