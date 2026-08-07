import 'package:Checkin/mainscreen.dart';
import 'package:Checkin/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const Checkin());
}

class Checkin extends StatelessWidget {
  const Checkin({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Checkin',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: const MainScreen(),
        );
      },
    );
  }
}

