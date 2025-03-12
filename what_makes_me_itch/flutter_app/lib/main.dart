import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(DevicePreview(builder: (context) => MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'What Makes Me Itch',
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0x00575757),
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.green,
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 255, 255, 255)),
          bodyMedium: TextStyle(
              fontSize: 16, color: const Color.fromARGB(221, 255, 255, 255)),
        ),
      ),
      home: LoginPage(),
    );
  }
}