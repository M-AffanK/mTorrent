import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppFonts {
  static const String? mainFamily = null; // Use default system font for now

  static TextStyle splashTitle1 = TextStyle(
    fontSize: 40,
    fontFamily: GoogleFonts.ptSerif().fontFamily,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlue,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle splashTitle2 = TextStyle(
    fontSize: 38,
    fontFamily: mainFamily,
    // fontWeight: FontWeight.bold,
    color: AppColors.primaryBlue,
  );

  static const TextStyle connectedStatus = TextStyle(
    fontSize: 12,
    color: AppColors.grey,
    fontFamily: mainFamily,
  );

  static const TextStyle statusText = TextStyle(
    fontSize: 14,
    fontFamily: mainFamily,
  );

  static const TextStyle hintText = TextStyle(
    color: AppColors.grey,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlue,
    letterSpacing: 1.2,
    fontFamily: mainFamily,
  );
}
