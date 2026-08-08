// lib/utils/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor

  // Primary Theme Colors
  static const Color vintageInk = Color(
    0xFF4A0E00,
  ); // Deep reddish-brown for text
  static const Color templeGold = Color(
    0xFFD4AF37,
  ); // For ornamental borders or highlights
  static const Color parchmentBase = Color(
    0xFFF3E5AB,
  ); // Backup background color
  static const Color palmLeafGreen = Color(
    0xFF4C5D41,
  ); // For secondary text or accents

  // UI Elements
  static const Color dividerBrown = Color(0xFF8B5A2B); // For list separators
  static const Color dividerBrown1 = Color.fromARGB(
    255,
    94,
    57,
    22,
  ); // For list separators
  static const Color shadowColor = Color(
    0x33000000,
  ); // 20% opacity black for drop shadows

  // Standard UI Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
}
