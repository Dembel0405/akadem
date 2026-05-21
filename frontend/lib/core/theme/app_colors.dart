import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFFDBEAFE);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color gray50 = Color(0xFFF1F5F9);
  static const Color gray100 = Color(0xFFE2E8F0);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray700 = Color(0xFF334155);
  static const Color gray900 = Color(0xFF0F172A);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Attendance status colors
  static const Color present = success;
  static const Color absent = error;
  static const Color late = warning;
  static const Color excused = info;
}
