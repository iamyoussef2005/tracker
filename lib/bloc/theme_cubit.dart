import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/database_helper.dart';
import '../models/app_theme_settings.dart';

class ThemeCubit extends Cubit<AppThemeSettings> {
  ThemeCubit({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
      super(AppThemeSettings.fallback);

  final DatabaseHelper _databaseHelper;

  Future<void> loadTheme() async {
    try {
      final settings = await _databaseHelper.getAppThemeSettings();
      emit(settings);
    } catch (_) {
      emit(AppThemeSettings.fallback);
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final settings = state.copyWith(themeMode: themeMode);
    emit(settings);
    try {
      await _databaseHelper.upsertAppThemeSettings(settings);
    } catch (_) {
      // Keep the selected theme active even if persistence fails.
      return;
    }
  }

  Future<void> setPalette(String paletteId) async {
    final settings = state.copyWith(paletteId: paletteId);
    emit(settings);
    try {
      await _databaseHelper.upsertAppThemeSettings(settings);
    } catch (_) {
      // Keep the selected theme active even if persistence fails.
      return;
    }
  }
}
