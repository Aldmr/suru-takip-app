import 'package:flutter/material.dart';

class AppColors {
  static const soil = Color(0xFF2C1A0E);
  static const bark = Color(0xFF5C3D1E);
  static const straw = Color(0xFFE8C97A);
  static const sage = Color(0xFF7BAF7A);
  static const sageLight = Color(0xFFA8D4A7);
  static const cream = Color(0xFFFAF4E8);
  static const mist = Color(0xFFF0E9D8);
  static const rust = Color(0xFFC0522A);
  static const sky = Color(0xFF7BAFC0);
  static const wool = Color(0xFFF5EFE0);
  static const mutedText = Color(0xFF9A8060);
  static const shadow = Color(0x262C1A0E);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.wool,
        colorScheme: const ColorScheme.light(
          primary: AppColors.soil,
          secondary: AppColors.straw,
          surface: AppColors.cream,
        ),
        fontFamily: 'DMSans',
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.soil,
          unselectedItemColor: AppColors.mutedText,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );
}
