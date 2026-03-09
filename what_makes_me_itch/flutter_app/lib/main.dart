import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true, // you can turn this off for release
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'What Makes Me Itch',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.blueBtn,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.blueBtn,
          secondary: AppColors.coral,
          surface: AppColors.background,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.navyText,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.navyText,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: AppColors.navyText,
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}
