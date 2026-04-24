import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/finance_bloc.dart';
import 'bloc/theme_cubit.dart';
import 'models/app_theme_settings.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FinanceTrackerApp());
}

class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()..loadTheme()),
        BlocProvider(
          create: (_) => AuthBloc()..add(const AuthSessionRequested()),
        ),
        BlocProvider(create: (_) => FinanceBloc()),
      ],
      child: BlocBuilder<ThemeCubit, AppThemeSettings>(
        builder: (context, themeSettings) {
          return MaterialApp(
            title: 'Personal Finance Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(themeSettings.paletteId),
            darkTheme: AppTheme.dark(themeSettings.paletteId),
            themeMode: themeSettings.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
