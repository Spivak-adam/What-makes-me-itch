import 'package:flutter/material.dart';
import 'main_screen.dart';
import '../theme/app_colors.dart';
import '../config/api_config.dart';
import 'loading_page.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showLoginForm = false;
  bool showSignupForm = false;

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void showPopup(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? validatePassword(String password) {
    if (password.length < 8) {
      return "Password must be at least 8 characters long.";
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Password must include at least one uppercase letter.";
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Password must include at least one lowercase letter.";
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Password must include at least one number.";
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]').hasMatch(password)) {
      return "Password must include at least one special character.";
    }

    return null;
  }

  Future<void> loginUser() async {
    if (_usernameController.text.trim().isEmpty) {
      showPopup("Please enter your username.", isError: true);
      return;
    }

    if (_passwordController.text.isEmpty) {
      showPopup("Please enter your password.", isError: true);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final int userId = data["user_id"];

        if (!mounted) return;

        showPopup("Login successful!", isError: false);

        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoadingPage(userId: userId)),
        );
      } else {
        showPopup(data["error"] ?? "Login failed.", isError: true);
      }
    } catch (e) {
      showPopup("Could not connect to the server.", isError: true);
      print("LOGIN ERROR: $e");
    }
  }

  Future<void> signupUser() async {
    if (_nameController.text.trim().isEmpty) {
      showPopup("Please enter your name.", isError: true);
      return;
    }

    if (_usernameController.text.trim().isEmpty) {
      showPopup("Please choose a username.", isError: true);
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      showPopup("Please enter your email.", isError: true);
      return;
    }

    if (!_emailController.text.trim().contains("@")) {
      showPopup("Please enter a valid email address.", isError: true);
      return;
    }

    final passwordError = validatePassword(_passwordController.text);
    if (passwordError != null) {
      showPopup(passwordError, isError: true);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      showPopup("Passwords do not match.", isError: true);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": _nameController.text.trim(),
          "username": _usernameController.text.trim(),
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      print("SIGNUP STATUS: ${response.statusCode}");
      print("SIGNUP BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        showPopup("Account created! Please log in.", isError: false);

        setState(() {
          showSignupForm = false;
          showLoginForm = true;
        });

        _passwordController.clear();
        _confirmPasswordController.clear();
      } else {
        showPopup(data["error"] ?? "Signup failed.", isError: true);
      }
    } catch (e) {
      showPopup("Could not connect to the server.", isError: true);
      print("SIGNUP ERROR: $e");
    }
  }

  void clearFields() {
    _nameController.clear();
    _usernameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('Assets/FinalLogo.png', height: 150),
                  const SizedBox(height: 28),

                  Text(
                    showLoginForm
                        ? 'Log In'
                        : showSignupForm
                            ? 'Sign Up'
                            : 'Welcome to\nWhat makes\nme itch?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 36,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyText,
                    ),
                  ),

                  const SizedBox(height: 30),

                  if (!showLoginForm && !showSignupForm) ...[
                    SizedBox(
                      width: width,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            clearFields();
                            showLoginForm = true;
                            showSignupForm = false;
                          });
                        },
                        child: const Text('Log In'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: width,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            clearFields();
                            showSignupForm = true;
                            showLoginForm = false;
                          });
                        },
                        child: const Text('Sign Up'),
                      ),
                    ),
                  ],

                  if (showLoginForm) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loginUser,
                      child: const Text("Login"),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          clearFields();
                          showLoginForm = false;
                        });
                      },
                      child: const Text("Back"),
                    ),
                  ],

                  if (showSignupForm) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        helperText:
                            "8+ chars, uppercase, lowercase, number, special character",
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Confirm Password",
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: signupUser,
                      child: const Text("Create Account"),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          clearFields();
                          showSignupForm = false;
                        });
                      },
                      child: const Text("Back"),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}