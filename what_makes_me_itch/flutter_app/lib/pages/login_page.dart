import 'package:flutter/material.dart';
import 'main_screen.dart';
import '../theme/app_colors.dart';

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

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  String errorMessage = "";

  // -------------------------
  // LOGIN FUNCTION
  // -------------------------
  Future<void> loginUser() async {
    setState(() => errorMessage = "");

    final response = await http.post(
      Uri.parse("http://127.0.0.1:5000/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": _emailController.text,
        "password": _passwordController.text,
      }),
    );

    print("LOGIN STATUS: ${response.statusCode}");
    print("LOGIN BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final int userId = data["user_id"];

      // For now just navigate
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(userId: userId)),
      );
    } else {
      final data = jsonDecode(response.body);
      setState(() {
        errorMessage = data["error"] ?? "Login failed";
      });
    }
  }

  // -------------------------
  // SIGNUP FUNCTION
  // -------------------------
  Future<void> signupUser() async {
    setState(() => errorMessage = "");

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => errorMessage = "Passwords do not match");
      return;
    }

    final response = await http.post(
      Uri.parse("http://127.0.0.1:5000/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": _nameController.text,
        "email": _emailController.text,
        "password": _passwordController.text,
      }),
    );

    print("SIGNUP STATUS: ${response.statusCode}");
    print("SIGNUP BODY: ${response.body}");

    if (response.statusCode == 201) {
      // After successful signup, switch to login form
      setState(() {
        showSignupForm = false;
        showLoginForm = true;
        errorMessage = "Account created! Please log in.";
      });
    } else {
      final data = jsonDecode(response.body);
      setState(() {
        errorMessage = data["error"] ?? "Signup failed";
      });
    }
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
                      controller: _emailController,
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
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loginUser,
                      child: const Text("Login"),
                    ),
                    const SizedBox(height: 10),
                    if (errorMessage.isNotEmpty)
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          showLoginForm = false;
                          errorMessage = "";
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
                      controller: _emailController,
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
                    const SizedBox(height: 10),
                    if (errorMessage.isNotEmpty)
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          showSignupForm = false;
                          errorMessage = "";
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
