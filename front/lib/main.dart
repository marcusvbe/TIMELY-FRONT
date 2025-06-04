import 'package:flutter/material.dart';
import 'pages/login.dart';
import 'pages/home.dart';
import 'screens/settings_screen.dart';
import 'config/app_config.dart';

void main() async {
  // Inicializa o Flutter antes de usar plugins nativos
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega configurações salvas
  await AppConfig.init();

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
        '/home': (context) => Home(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}
