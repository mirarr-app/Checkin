import 'package:Checkin/mainscreen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const Checkin());
}

class Checkin extends StatelessWidget {
  const Checkin({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Checkin',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.dark(
          primary: Colors.orange.shade400,
          secondary: Colors.orange.shade200,
          surface: Colors.grey.shade900,
          onSurface: Colors.white,
        ),
        cardColor: Colors.grey.shade900,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade900,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const MainScreen(),
    );
  }
}
