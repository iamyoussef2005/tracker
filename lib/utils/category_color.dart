import 'package:flutter/material.dart';

class CategoryColor {
  const CategoryColor._();

  static const Color fallback = Color(0xFF006D77);

  static const List<Color> fallbackPalette = [
    Color(0xFFD95D39),
    Color(0xFF3D5A80),
    Color(0xFF81B29A),
    Color(0xFFE9C46A),
    Color(0xFF6D597A),
    Color(0xFF2A9D8F),
  ];

  static Color fromHex(String? colorHex, {Color? fallbackColor}) {
    final fallbackValue = fallbackColor ?? fallback;
    if (colorHex == null || colorHex.isEmpty) {
      return fallbackValue;
    }

    final normalized = colorHex.replaceFirst('#', '');
    if (normalized.length != 6) {
      return fallbackValue;
    }

    final colorValue = int.tryParse('FF$normalized', radix: 16);
    if (colorValue == null) {
      return fallbackValue;
    }

    return Color(colorValue);
  }

  static Color fallbackForIndex(int index) {
    return fallbackPalette[index % fallbackPalette.length];
  }
}
