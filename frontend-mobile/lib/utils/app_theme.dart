import 'package:flutter/material.dart';

/// Color scheme profesional untuk aplikasi
class AppColors {
  // Primary Colors - Teal
  static const Color primary = Color(0xFF0D7377);
  static const Color primaryLight = Color(0xFF14919B);
  static const Color primaryDark = Color(0xFF084C54);

  // Secondary Colors - Navy
  static const Color secondary = Color(0xFF2C3E50);
  static const Color secondaryLight = Color(0xFF34495E);

  // Accent
  static const Color accent = Color(0xFF0FA3B1);

  // Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Neutral Colors
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color bgLight = Color(0xFFF9FAFB);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryLight],
  );

  static const LinearGradient primaryGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, primaryLight],
  );
}

/// Text styles yang responsif
class AppTextStyles {
  static TextStyle heading1(BuildContext context, {Color? color}) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return TextStyle(
      fontSize: isSmall ? 24 : 28,
      fontWeight: FontWeight.bold,
      color: color ?? AppColors.textDark,
      height: 1.2,
    );
  }

  static TextStyle heading2(BuildContext context, {Color? color}) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return TextStyle(
      fontSize: isSmall ? 20 : 24,
      fontWeight: FontWeight.bold,
      color: color ?? AppColors.textDark,
      height: 1.2,
    );
  }

  static TextStyle heading3(BuildContext context, {Color? color}) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return TextStyle(
      fontSize: isSmall ? 16 : 18,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textDark,
    );
  }

  static TextStyle body(BuildContext context, {Color? color}) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return TextStyle(
      fontSize: isSmall ? 14 : 16,
      color: color ?? AppColors.textLight,
      height: 1.5,
    );
  }

  static TextStyle bodySmall(BuildContext context, {Color? color}) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return TextStyle(
      fontSize: isSmall ? 12 : 14,
      color: color ?? AppColors.textHint,
    );
  }

  static TextStyle button(BuildContext context, {Color? color}) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return TextStyle(
      fontSize: isSmall ? 14 : 16,
      fontWeight: FontWeight.bold,
      color: color ?? AppColors.bgWhite,
    );
  }

  static TextStyle label(BuildContext context, {Color? color}) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return TextStyle(
      fontSize: isSmall ? 12 : 14,
      color: color ?? AppColors.textLight,
    );
  }
}
