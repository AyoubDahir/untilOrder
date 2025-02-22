import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class FlutterFlowTheme {
  static FlutterFlowTheme of(BuildContext context) => LightModeTheme();

  Color get primaryBackground => const Color(0xFFFFFFFF);
  Color get primaryText => const Color(0xFF14181B);
  Color get secondaryText => const Color(0xFF57636C);
  Color get primary => const Color(0xFF4B39EF);
  Color get secondary => const Color(0xFF39D2C0);

  TextStyle get displayLarge => GoogleFonts.outfit(
        color: primaryText,
        fontSize: 64,
        fontWeight: FontWeight.w600,
      );
  TextStyle get displayMedium => GoogleFonts.outfit(
        color: primaryText,
        fontSize: 44,
        fontWeight: FontWeight.w600,
      );
  TextStyle get displaySmall => GoogleFonts.outfit(
        color: primaryText,
        fontSize: 36,
        fontWeight: FontWeight.w600,
      );
  TextStyle get headlineLarge => GoogleFonts.outfit(
        color: primaryText,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      );
  TextStyle get headlineMedium => GoogleFonts.outfit(
        color: primaryText,
        fontSize: 24,
        fontWeight: FontWeight.w500,
      );
  TextStyle get headlineSmall => GoogleFonts.outfit(
        color: primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      );
  TextStyle get titleLarge => GoogleFonts.outfit(
        color: primaryText,
        fontSize: 22,
        fontWeight: FontWeight.w500,
      );
  TextStyle get titleMedium => GoogleFonts.outfit(
        color: primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      );
  TextStyle get titleSmall => GoogleFonts.outfit(
        color: primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );
  TextStyle get labelLarge => GoogleFonts.outfit(
        color: secondaryText,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );
  TextStyle get labelMedium => GoogleFonts.outfit(
        color: secondaryText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );
  TextStyle get labelSmall => GoogleFonts.outfit(
        color: secondaryText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );
  TextStyle get bodyLarge => GoogleFonts.outfit(
        color: primaryText,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      );
  TextStyle get bodyMedium => GoogleFonts.outfit(
        color: primaryText,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );
  TextStyle get bodySmall => GoogleFonts.outfit(
        color: primaryText,
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );
}

class LightModeTheme extends FlutterFlowTheme {
  @override
  Color get primaryBackground => const Color(0xFFFFFFFF);
  @override
  Color get primaryText => const Color(0xFF14181B);
  @override
  Color get secondaryText => const Color(0xFF57636C);
  @override
  Color get primary => const Color(0xFF4B39EF);
  @override
  Color get secondary => const Color(0xFF39D2C0);
}
