import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'main_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "What makes me itch?"),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("Keeping track of allergies for you!",
                  style: Theme.of(context).textTheme.titleLarge),
              Spacer(), // Pushes everything below towards the center
              SizedBox(height: 20),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  obscureText: true,
                ),
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text("Forgot Password?",
                      style: TextStyle(color: Colors.blue)),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen()),
                  );
                },
                child: Text("Login"),
              ),
              SizedBox(height: 40),
              TextButton(
                onPressed: () {},
                child: Text("Create an Account",
                    style: TextStyle(color: Colors.blue, fontSize: 16)),
              ),
              Spacer(), // Pushes everything above towards the center
              Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '"What Makes Me Itch" is not liable. Please see a doctor for more accurate results.',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 196, 196, 196),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
