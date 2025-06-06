import 'package:flutter/material.dart';
import 'pages/login.dart';
import 'pages/home.dart';
import 'screens/settings_screen.dart';
import 'config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init(); // <-- load & normalize saved wsUrl here
  runApp(const MyApp()); // <-- now AppConfig.wsUrl is correct
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
