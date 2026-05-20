import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2563EB);
  static const secondary = Color(0xFF7C3AED);
  static const accent = Color(0xFF06B6D4);

  static const income = Color(0xFF16A34A);
  static const expense = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);

  static const lightBackground = Color(0xFFF8FAFC);
  static const darkBackground = Color(0xFF020617);

  static const lightCard = Colors.white;
  static const darkCard = Color(0xFF0F172A);

  static const textDark = Color(0xFF0F172A);
  static const textLight = Color(0xFFF8FAFC);

  static const gradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}