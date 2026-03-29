import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Accent colors (same in both themes) ─────────────────────────────────
  static const Color primary       = Color(0xFF7C3AED);
  static const Color primaryLight  = Color(0xFF8B5CF6);
  static const Color secondary     = Color(0xFF0891B2);

  static const Color income        = Color(0xFF059669);
  static const Color incomeLight   = Color(0xFF10B981);
  static const Color expense       = Color(0xFFDC2626);
  static const Color expenseLight  = Color(0xFFEF4444);
  static const Color savings       = Color(0xFF2563EB);
  static const Color savingsLight  = Color(0xFF3B82F6);

  // ─── Dark palette ────────────────────────────────────────────────────────
  static const Color darkBg            = Color(0xFF0A0A14);
  static const Color darkSurface       = Color(0xFF141424);
  static const Color darkSurfaceAlt    = Color(0xFF1E1E32);
  static const Color darkSurfaceHigh   = Color(0xFF262640);
  static const Color darkBorder        = Color(0xFF2A2A44);
  static const Color darkTextPrimary   = Color(0xFFF1F0FF);
  static const Color darkTextSecondary = Color(0xFF9090B8);
  static const Color darkTextMuted     = Color(0xFF5A5A7A);

  // ─── Light palette ───────────────────────────────────────────────────────
  static const Color lightBg            = Color(0xFFF5F4FF);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt    = Color(0xFFF0EFFE);
  static const Color lightSurfaceHigh   = Color(0xFFE8E5FD);
  static const Color lightBorder        = Color(0xFFDDD9FA);
  static const Color lightTextPrimary   = Color(0xFF1A1433);
  static const Color lightTextSecondary = Color(0xFF6B63A3);
  static const Color lightTextMuted     = Color(0xFF9E98C8);

  // ─── Context-aware helpers ───────────────────────────────────────────────
  static bool isDark(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark;

  static Color bgColor(BuildContext ctx)          => isDark(ctx) ? darkBg            : lightBg;
  static Color surfaceColor(BuildContext ctx)     => isDark(ctx) ? darkSurface       : lightSurface;
  static Color surfaceAltColor(BuildContext ctx)  => isDark(ctx) ? darkSurfaceAlt    : lightSurfaceAlt;
  static Color surfaceHighColor(BuildContext ctx) => isDark(ctx) ? darkSurfaceHigh   : lightSurfaceHigh;
  static Color borderColor(BuildContext ctx)      => isDark(ctx) ? darkBorder        : lightBorder;
  static Color textPrimaryColor(BuildContext ctx) => isDark(ctx) ? darkTextPrimary   : lightTextPrimary;
  static Color textSecColor(BuildContext ctx)     => isDark(ctx) ? darkTextSecondary : lightTextSecondary;
  static Color textMutedColor(BuildContext ctx)   => isDark(ctx) ? darkTextMuted     : lightTextMuted;

  // ─── Themes ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme  => _build(dark: true);
  static ThemeData get lightTheme => _build(dark: false);

  static ThemeData _build({required bool dark}) {
    final bg           = dark ? darkBg            : lightBg;
    final surface      = dark ? darkSurface       : lightSurface;
    final surfaceAlt   = dark ? darkSurfaceAlt    : lightSurfaceAlt;
    final surfaceHigh  = dark ? darkSurfaceHigh   : lightSurfaceHigh;
    final border       = dark ? darkBorder        : lightBorder;
    final textPri      = dark ? darkTextPrimary   : lightTextPrimary;
    final textSec      = dark ? darkTextSecondary : lightTextSecondary;
    final textMut      = dark ? darkTextMuted     : lightTextMuted;
    final brightness   = dark ? Brightness.dark   : Brightness.light;
    final baseText     = dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final overlayStyle = dark ? SystemUiOverlayStyle.light  : SystemUiOverlayStyle.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: dark
          ? ColorScheme.dark(primary: primary, secondary: secondary, surface: surface, onPrimary: Colors.white, onSecondary: Colors.white, onSurface: textPri, outline: border)
          : ColorScheme.light(primary: primary, secondary: secondary, surface: surface, onPrimary: Colors.white, onSecondary: Colors.white, onSurface: textPri, outline: border),
      textTheme: GoogleFonts.dmSansTextTheme(baseText).apply(bodyColor: textPri, displayColor: textPri).copyWith(
        displayLarge:  GoogleFonts.spaceGrotesk(color: textPri, fontWeight: FontWeight.w700, letterSpacing: -1.5),
        headlineLarge: GoogleFonts.spaceGrotesk(color: textPri, fontWeight: FontWeight.w700, letterSpacing: -1),
        headlineMedium:GoogleFonts.spaceGrotesk(color: textPri, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        titleLarge:    GoogleFonts.dmSans(color: textPri, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium:   GoogleFonts.dmSans(color: textPri, fontWeight: FontWeight.w600, fontSize: 15),
        bodyLarge:     GoogleFonts.dmSans(color: textPri, fontSize: 15),
        bodyMedium:    GoogleFonts.dmSans(color: textSec, fontSize: 13),
        bodySmall:     GoogleFonts.dmSans(color: textMut, fontSize: 11),
        labelLarge:    GoogleFonts.dmSans(color: textPri, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, elevation: 0,
        systemOverlayStyle: overlayStyle,
        titleTextStyle: GoogleFonts.spaceGrotesk(color: textPri, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        iconTheme: IconThemeData(color: textPri),
      ),
      cardTheme: CardThemeData(
        color: surface, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: border)),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withOpacity(0.15),
        height: 64, elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
            ? GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: primary)
            : GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: textSec)),
        iconTheme: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
            ? IconThemeData(color: primary, size: 22)
            : IconThemeData(color: textMut, size: 22)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: primary, foregroundColor: Colors.white, elevation: 0, shape: CircleBorder()),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 1.5)),
        labelStyle: TextStyle(color: textSec),
        hintStyle: TextStyle(color: textMut),
        prefixIconColor: textSec,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        showDragHandle: true, dragHandleColor: border,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        selectedColor: primary.withOpacity(0.2),
        labelStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPri),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : textMut),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : surfaceHigh),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(backgroundColor: surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      listTileTheme: ListTileThemeData(tileColor: Colors.transparent, textColor: textPri, iconColor: textSec),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: border)),
      ),
    );
  }

  // ─── Gradients ───────────────────────────────────────────────────────────
  static const LinearGradient purpleGradient  = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]);
  static const LinearGradient incomeGradient  = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF059669), Color(0xFF047857)]);
  static const LinearGradient expenseGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]);
  static const LinearGradient savingsGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]);

  static LinearGradient gradientForColor(Color c) => LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [c, Color.lerp(c, Colors.black, 0.3)!],
  );
}
