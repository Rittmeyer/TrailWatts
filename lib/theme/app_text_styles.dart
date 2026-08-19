import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Fraunces for headings, Inter for body/UI, IBM Plex Mono for numbers -
/// the same three-typeface system as the HTML prototype.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get screenTitle => GoogleFonts.fraunces(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get screenSubtitle => GoogleFonts.inter(
        fontSize: 11,
        color: AppColors.inkSoft,
        height: 1.4,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.ink,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 10.5,
        color: AppColors.inkSoft,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get numeric => GoogleFonts.ibmPlexMono(
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get heroTitle => GoogleFonts.fraunces(
        fontSize: 38,
        fontWeight: FontWeight.w600,
        height: 1.16,
        color: AppColors.ink,
      );
}
