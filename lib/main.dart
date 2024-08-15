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
          fontFamily: 'Poppins',
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: Colors.orange,
            onPrimary: Colors.blue,
            secondary: Colors.purple,
            onSecondary: Colors.deepPurple,
            error: Colors.red,
            onError: Colors.orange,
            background: Colors.black,
            onBackground: Colors.black,
            surface: Colors.black,
            onSurface: Colors.black,
          ),
          cardColor: Theme.of(context).primaryColor,
          scaffoldBackgroundColor: Colors.black,
        ),
        home: MainScreen());
  }
}
