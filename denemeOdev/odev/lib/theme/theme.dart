// lib/theme/theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Renk Paleti
  static const Color primaryColor = Color(0xFFF5F5F5); // Derin Lacivert
  static const Color primaryContainerColor = Color(0xFF334155); // Daha koyu bir lacivert varyant
  static const Color secondaryColor = Color(0xFFFF5722); // Canlı Turuncu
  static const Color secondaryContainerColor = Color(0xFF42A5F5); // Daha koyu turuncu varyant
  static const Color backgroundColor = Color(0xFFF5F5F5); // Çok Açık Gri
  static const Color textColor = Color(0xFF212121); // Koyu Gri Yazı
  static const Color textLightColor = Color(0xFF757575); // Açık Gri Yazı
  static const Color cardBackground = Colors.white; // Kart Arka Planı
  static const Color price = Color(0xFFF44336);

  // Font Ailesi
  static const String fontFamily = 'Montserrat';

  // TextStyle Tanımlamaları
  static TextStyle textStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color color = textColor,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // ThemeData Tanımı
  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardBackground,
      colorScheme: ColorScheme(
        primary: primaryColor,
        primaryContainer: primaryContainerColor,
        secondary: secondaryColor,
        secondaryContainer: secondaryContainerColor,
        surface: Colors.white,
        background: backgroundColor,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
        onBackground: textColor,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      textTheme: TextTheme(
        headlineLarge: textStyle(fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: textStyle(fontSize: 28, fontWeight: FontWeight.bold),
        headlineSmall: textStyle(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: textStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: textStyle(fontSize: 18, fontWeight: FontWeight.w500),
        titleSmall: textStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: textStyle(fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: textStyle(fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: textStyle(fontSize: 12, fontWeight: FontWeight.normal, color: textLightColor),
        labelLarge: textStyle(fontSize: 16, fontWeight: FontWeight.w400),
        labelMedium: textStyle(fontSize: 14, fontWeight: FontWeight.w400),
        labelSmall: textStyle(fontSize: 12, fontWeight: FontWeight.w400),
        // 'button' parametresi kaldırıldı
      ),
      appBarTheme: AppBarTheme(
        color: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: textStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        elevation: 0,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: secondaryColor,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor, // 'primary' yerine 'backgroundColor'
          foregroundColor: Colors.white, // 'onPrimary' yerine 'foregroundColor'
          textStyle: textStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor, // 'primary' yerine 'foregroundColor'
          textStyle: textStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor, // 'primary' yerine 'foregroundColor'
          side: BorderSide(color: primaryColor),
          textStyle: textStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: textStyle(color: textLightColor),
        labelStyle: textStyle(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: secondaryColor),
        ),
      ),
      iconTheme: IconThemeData(color: primaryColor),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
