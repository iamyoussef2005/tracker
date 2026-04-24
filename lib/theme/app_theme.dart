import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.seed,
  });

  final String id;
  final String name;
  final Color seed;
}

class AppTheme {
  const AppTheme._();

  static const palettes = [
    AppPalette(id: 'teal', name: 'Teal', seed: Color(0xFF006D77)),
    AppPalette(id: 'indigo', name: 'Indigo', seed: Color(0xFF3D5A80)),
    AppPalette(id: 'emerald', name: 'Emerald', seed: Color(0xFF2A9D8F)),
    AppPalette(id: 'rose', name: 'Rose', seed: Color(0xFFE76F51)),
  ];

  static AppPalette paletteFor(String id) {
    return palettes.firstWhere(
      (palette) => palette.id == id,
      orElse: () => palettes.first,
    );
  }

  static ThemeData light(String paletteId) {
    final palette = paletteFor(paletteId);
    return _buildTheme(
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.seed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F1E8),
    );
  }

  static ThemeData dark(String paletteId) {
    final palette = paletteFor(paletteId);
    return _buildTheme(
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.seed,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1720),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
  }) {
    final baseTheme = ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      useMaterial3: true,
    );
    final textTheme = _buildTextTheme(baseTheme.textTheme);
    final isDark = colorScheme.brightness == Brightness.dark;
    final panelColor = isDark
        ? colorScheme.surface.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.92);
    final borderColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.26)
        : colorScheme.outline.withValues(alpha: 0.12);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.28)
        : const Color(0xFF0F172A).withValues(alpha: 0.08);

    return baseTheme.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      canvasColor: scaffoldBackgroundColor,
      dividerColor: borderColor,
      splashFactory: InkRipple.splashFactory,
      cardTheme: CardThemeData(
        color: panelColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: shadowColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.05,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panelColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        extendedTextStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(42, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF17212B)
            : const Color(0xFF1F2933),
        contentTextStyle: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.dmSans(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.dmSans(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: GoogleFonts.dmSans(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    final body = GoogleFonts.dmSansTextTheme(base);

    return body.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        textStyle: body.displayLarge,
        fontSize: 54,
        fontWeight: FontWeight.w700,
        height: 0.98,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        textStyle: body.displayMedium,
        fontSize: 44,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        textStyle: body.displaySmall,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.04,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        textStyle: body.headlineLarge,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.08,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        textStyle: body.headlineMedium,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.08,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        textStyle: body.headlineSmall,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        textStyle: body.titleLarge,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.14,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        textStyle: body.titleMedium,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.16,
      ),
      titleSmall: GoogleFonts.spaceGrotesk(
        textStyle: body.titleSmall,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.18,
      ),
      bodyLarge: GoogleFonts.dmSans(
        textStyle: body.bodyLarge,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.42,
      ),
      bodyMedium: GoogleFonts.dmSans(
        textStyle: body.bodyMedium,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.42,
      ),
      bodySmall: GoogleFonts.dmSans(
        textStyle: body.bodySmall,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      labelLarge: GoogleFonts.dmSans(
        textStyle: body.labelLarge,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
      labelMedium: GoogleFonts.dmSans(
        textStyle: body.labelMedium,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
      labelSmall: GoogleFonts.dmSans(
        textStyle: body.labelSmall,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    );
  }
}
