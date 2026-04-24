import 'package:flutter/material.dart';

class AppThemeSettings {
  const AppThemeSettings({
    required this.themeMode,
    required this.paletteId,
  });

  final ThemeMode themeMode;
  final String paletteId;

  static const fallback = AppThemeSettings(
    themeMode: ThemeMode.system,
    paletteId: 'teal',
  );

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'theme_mode': themeMode.name,
      'palette_id': paletteId,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory AppThemeSettings.fromMap(Map<String, dynamic> map) {
    return AppThemeSettings(
      themeMode: _themeModeFromName(map['theme_mode'] as String?),
      paletteId: map['palette_id'] as String? ?? fallback.paletteId,
    );
  }

  AppThemeSettings copyWith({
    ThemeMode? themeMode,
    String? paletteId,
  }) {
    return AppThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      paletteId: paletteId ?? this.paletteId,
    );
  }

  static ThemeMode _themeModeFromName(String? name) {
    for (final mode in ThemeMode.values) {
      if (mode.name == name) {
        return mode;
      }
    }

    return fallback.themeMode;
  }
}
