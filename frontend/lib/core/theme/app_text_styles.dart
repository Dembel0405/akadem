import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle get _base => GoogleFonts.inter(color: AppColors.gray900);

  // Заголовки
  static TextStyle get h1 => _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle get h2 => _base.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);
  static TextStyle get h3 => _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);
  static TextStyle get h4 => _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);

  // Основной текст
  static TextStyle get bodyLarge =>
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get body =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyMedium =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5);

  // Вспомогательный текст
  static TextStyle get caption =>
      _base.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.gray500, height: 1.4);
  static TextStyle get captionMedium =>
      _base.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray500, height: 1.4);
  static TextStyle get label =>
      _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.gray500, height: 1.3);

  // Кнопки
  static TextStyle get buttonLarge =>
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get button =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get buttonSmall =>
      _base.copyWith(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.1);
}
