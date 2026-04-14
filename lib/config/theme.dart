import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_fonts/google_fonts.dart';

class UniVaultColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color sidebar = Color(0xFFF8F9FA);
  static const Color primaryAction = Color(0xFF1A73E8);
  static const Color divider = Color(0xFFDADCE0);
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color searchBackground = Color(0xFFF1F3F4);
  static const Color searchBorder = Color(0xFFDFE1E3);
  static const Color formBackground = Color(0xFFF8F9FA);
  static const Color formBorder = Color(0xFFE8EAED);
  static const Color hoverColor = Color(0xFFEFF3F8);
  static const Color successColor = Color(0xFF34A853);
  static const Color errorColor = Color(0xFFEA4335);
  static const Color warningColor = Color(0xFFFBBC04);
}

class UniVaultTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: UniVaultColors.background,
      colorScheme: const ColorScheme.light(
        primary: UniVaultColors.primaryAction,
        surface: UniVaultColors.background,
      ),
      dividerColor: UniVaultColors.divider,
      textTheme: TextTheme(
        headlineSmall: GoogleFonts.poppins(
          color: UniVaultColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.poppins(
          color: UniVaultColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: -0.2,
        ),
        titleSmall: GoogleFonts.openSans(
          color: UniVaultColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        bodyLarge: GoogleFonts.openSans(
          color: UniVaultColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.openSans(
          color: UniVaultColors.textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.openSans(
          color: UniVaultColors.textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 12,
          height: 1.3,
        ),
        // Labels
        labelLarge: GoogleFonts.openSans(
          color: UniVaultColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.openSans(
          color: UniVaultColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

class UniVaultIcons {
  static const IconData add = Feather.plus_circle;
  static const IconData close = Feather.x;
  static const IconData menu = Feather.menu;
  static const IconData more = Feather.more_horizontal;
  static const IconData search = Feather.search;
  static const IconData clear = Feather.x;
  
  static const IconData visibilityOn = Feather.eye;
  static const IconData visibilityOff = Feather.eye_off;
  static const IconData lock = Feather.lock;
  static const IconData lockOpen = Feather.unlock;
  static const IconData security = Feather.shield;
  static const IconData copy = Feather.copy;
  static const IconData check = Feather.check;

  static const IconData delete = Feather.trash_2;
  static const IconData edit = Feather.edit;
  static const IconData warning = Feather.alert_triangle;
  static const IconData error = Feather.alert_octagon;
  static const IconData info = Feather.info;
  static const IconData success = Feather.check_circle;
  
  static const IconData profile = Feather.user;
  static const IconData logout = Feather.log_out;
  static const IconData rfid = Feather.radio;
  static const IconData animation = Feather.circle;
  
  static const IconData verified = Feather.check_circle;
  static const IconData unverified = Feather.x_circle;
}
