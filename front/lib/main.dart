import 'package:flutter/material.dart';
import 'pages/login.dart';
import 'pages/meusApontamentos.dart';
import '';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => Login(),
        '/meusApontamentos': (context) => meusApontamentos(),
        '/home': (context) => _HomeState(),
      },
    );
  }
}
