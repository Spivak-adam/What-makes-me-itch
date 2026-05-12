import 'package:flutter/material.dart';
import 'dart:async';
import 'main_screen.dart';
import '../theme/app_colors.dart';

class LoadingPage extends StatefulWidget {
  final int userId;

  const LoadingPage({super.key, required this.userId});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(userId: widget.userId),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// LOGO
            Container(
              height: 90,
              width: 90,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'Assets/FinalLogo.png',
              ),
            ),

            const SizedBox(height: 24),

            /// APP TITLE
            const Text(
              "What Makes Me Itch?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.navyText,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Loading your dashboard...",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 20),

            const CircularProgressIndicator(
              color: AppColors.coral,
            ),
          ],
        ),
      ),
    );
  }
}