import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core palette
  static const Color bg = Color(0xFF0A0A14);
  static const Color surface = Color(0xFF141424);
  static const Color surfaceAlt = Color(0xFF1E1E32);
  static const Color surfaceHigh = Color(0xFF262640);
  static const Color border = Color(0xFF2A2A44);

  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color secondary = Color(0xFF06B6D4);

  static const Color income = Color(0xFF10B981);
  static const Color incomeLight = Color(0xFF34D399);
  static const Color expense = Color(0xFFEF4444);
  static const Color expenseLight = Color(0xFFF87171);
  static const Color savings = Color(0xFF3B82F6);
  static const Color savingsLight = Color(0xFF60A5FA);

  static const Color textPrimary = Color(0xFFF1F0FF);
  static const Color textSecondary = Color(0xFF9090B8);
  static const Color textMuted = Color(0xFF5A5A7A);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      outline: border,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.dmSans(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: GoogleFonts.dmSans(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      bodyLarge: GoogleFonts.dmSans(color: textPrimary, fontSize: 15),
      bodyMedium: GoogleFonts.dmSans(color: textSecondary, fontSize: 13),
      bodySmall: GoogleFonts.dmSans(color: textMuted, fontSize: 11),
      labelLarge: GoogleFonts.dmSans(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: primary.withOpacity(0.2),
      height: 64,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primaryLight,
          );
        }
        return GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaryLight, size: 22);
        }
        return const IconThemeData(color: textMuted, size: 22);
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textMuted),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
      dragHandleColor: border,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceAlt,
      selectedColor: primary.withOpacity(0.25),
      labelStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
      side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.white : textMuted),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? primary : surfaceHigh),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );

  // Gradients
  static LinearGradient get purpleGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
  );

  static LinearGradient get incomeGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static LinearGradient get expenseGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  static LinearGradient get savingsGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  );

  static LinearGradient gradientForColor(Color c) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [c, Color.lerp(c, Colors.black, 0.3)!],
  );
}
