import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';

class AppColors {
  // Common Colors
  static const Color primary = Color(0xFFF96A46); // Warm Orange-Red
  static const Color primaryLight = Color(0xFFFF8C64); // Lighter Orange-Red
  static const Color primaryDark = Color(0xFFDC5032); // Darker Orange-Red
  static const Color secondary = Color(0xFF60A5FA); // Soft Blue
  static const Color secondaryLight = Color(0xFF93C5FD); // Lighter Soft Blue

  // Dark Theme - Backgrounds
  static const Color backgroundDark = Color(0xFF0B1220); // Deep Navy Blue
  static const Color surfaceDark = Color(0xFF1C2433); // Dark Slate Gray (Cards)
  static const Color surfaceVariantDark = Color(0xFF2A3446); // Dividers/Borders
  static const Color cardBackgroundDark = Color(0xFF1C2433);

  // Light Theme - Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF); // White
  static const Color surfaceVariantLight = Color(0xFFE2E8F0); // Slate 200
  static const Color cardBackgroundLight = Color(0xFFFFFFFF);

  // Text colors - Dark
  static const Color textPrimaryDark = Color(0xFFE5E7EB); // Off White
  static const Color textSecondaryDark = Color(0xFF9CA3AF); // Cool Gray
  static const Color textMutedDark = Color(0xFF6B7280); // Muted Gray

  // Text colors - Light
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400

  // Semantic colors
  static const Color income = Color(0xFF2563EB); // Blue for Income
  static const Color expense = Color(0xFFF97316); // Warm Orange for Expense
  static const Color balanceDark = Color(0xFFE5E7EB);
  static const Color balanceLight = Color(0xFF0F172A);
  static const Color transfer = Color(0xFF60A5FA);
  static const Color success = Color(0xFF2563EB);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFF97316);

  // Category colors - Vibrant multi-color palette for graphs & charts
  static const List<Color> categoryColors = [
    Color(0xFF2563EB), // Royal Blue
    Color(0xFFF97316), // Warm Orange
    Color(0xFFF59E0B), // Amber/Gold
    Color(0xFF8B5CF6), // Purple/Violet
    Color(0xFFEC4899), // Pink/Magenta
    Color(0xFF06B6D4), // Cyan/Teal
    Color(0xFF6366F1), // Indigo
    Color(0xFFD946EF), // Fuchsia
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFFA855F7), // Light Purple
    Color(0xFF14B8A6), // Teal
    Color(0xFFE879F9), // Light Pink
  ];

  // Additional chart colors for more variety
  static const List<Color> chartColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFF6366F1), // Indigo
    Color(0xFFD946EF), // Fuchsia
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFFE879F9), // Light Pink
    Color(0xFF38BDF8), // Light Sky
  ];

  // Navigation
  static const Color navUnselected = Color(0xFF6B7280);

  // Shimmer
  static const Color shimmerBaseDark = Color(0xFF1C2433);
  static const Color shimmerHighlightDark = Color(0xFF2A3446);
  static const Color shimmerBaseLight = Color(0xFFE2E8F0);
  static const Color shimmerHighlightLight = Color(0xFFF1F5F9);

  // Dynamic Getters for Backward Compatibility
  static Color get background => ThemeService().isDarkMode ? backgroundDark : backgroundLight;
  static Color get surface => ThemeService().isDarkMode ? surfaceDark : surfaceLight;
  static Color get surfaceVariant => ThemeService().isDarkMode ? surfaceVariantDark : surfaceVariantLight;
  static Color get cardBackground => ThemeService().isDarkMode ? cardBackgroundDark : cardBackgroundLight;
  static Color get textPrimary => ThemeService().isDarkMode ? textPrimaryDark : textPrimaryLight;
  static Color get textSecondary => ThemeService().isDarkMode ? textSecondaryDark : textSecondaryLight;
  static Color get textMuted => ThemeService().isDarkMode ? textMutedDark : textMutedLight;
  static Color get balance => ThemeService().isDarkMode ? balanceDark : balanceLight;
  
  static Color get shimmerBase => ThemeService().isDarkMode ? shimmerBaseDark : shimmerBaseLight;
  static Color get shimmerHighlight => ThemeService().isDarkMode ? shimmerHighlightDark : shimmerHighlightLight;

  static Color get fab => primary;
  static Color get incomeColor => income;
  static Color get expenseColor => expense;
  static Color get errorColor => error;

  // Static Getters for functional use
  static Color getBackground(Brightness brightness) =>
      brightness == Brightness.dark ? backgroundDark : backgroundLight;
  static Color getSurface(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceDark : surfaceLight;
  static Color getSurfaceVariant(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceVariantDark : surfaceVariantLight;
  static Color getTextPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;
  static Color getTextSecondary(Brightness brightness) =>
      brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;
  static Color getTextMuted(Brightness brightness) =>
      brightness == Brightness.dark ? textMutedDark : textMutedLight;
}


class AppTheme {
  static const double _cardRadius = 10.0;
  static const double _buttonRadius = 8.0;
  static const double _inputRadius = 8.0;

  static TextTheme _getTextTheme(Brightness brightness) {
    final color = AppColors.getTextPrimary(brightness);
    final secondaryColor = AppColors.getTextSecondary(brightness);
    final mutedColor = AppColors.getTextMuted(brightness);

    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: color,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: secondaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: mutedColor,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondaryColor,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: mutedColor,
        ),
      ),
    );
  }

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final backgroundColor = AppColors.getBackground(brightness);
    final surfaceColor = AppColors.getSurface(brightness);
    final surfaceVariantColor = AppColors.getSurfaceVariant(brightness);
    final textPrimaryColor = AppColors.getTextPrimary(brightness);
    final textSecondaryColor = AppColors.getTextSecondary(brightness);
    final textMutedColor = AppColors.getTextMuted(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: _getTextTheme(brightness),
      colorScheme: isDark
          ? ColorScheme.dark(
              surface: surfaceColor,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              error: AppColors.error,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              tertiary: AppColors.secondaryLight,
            )
          : ColorScheme.light(
              surface: surfaceColor,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              error: AppColors.error,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              tertiary: AppColors.secondaryLight,
            ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimaryColor),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: surfaceVariantColor,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: surfaceVariantColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: surfaceVariantColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: isDark ? surfaceColor : Colors.grey[50],
        labelStyle: GoogleFonts.inter(color: textSecondaryColor),
        hintStyle: GoogleFonts.inter(color: textMutedColor),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius + 4),
        ),
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.navUnselected,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.navUnselected, size: 24);
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius + 4),
        ),
        elevation: 8,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        elevation: 8,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariantColor,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(
          color: textPrimaryColor,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? surfaceColor : Colors.grey[900],
        contentTextStyle: GoogleFonts.inter(
          color: isDark ? textPrimaryColor : Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: textMutedColor,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return textMutedColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.3);
          }
          return surfaceVariantColor;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: surfaceVariantColor,
      ),
    );
  }
}

