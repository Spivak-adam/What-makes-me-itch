import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'custom_app_bar.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  const ProfilePage({super.key, required this.userId});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> userData;
  bool isEditing = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userData = fetchUserData(widget.userId);
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchUserData(int userId) async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:5000/user/$userId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user data');
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _updateProfile() async {
    try {
      final response = await http.put(
        Uri.parse('http://127.0.0.1:5000/update_user/${widget.userId}'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text.trim(),
          "username": usernameController.text.trim(),
          "email": emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          isEditing = false;
          userData = fetchUserData(widget.userId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error updating profile")),
      );
    }
  }

  void _deleteAllergen(String allergenName) async {
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:5000/delete_allergy'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "allergen_name": allergenName,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = fetchUserData(widget.userId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Allergen deleted successfully!")),
        );
      } else {
        final errorMessage = jsonDecode(response.body)['error'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete allergen: $errorMessage")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting allergen")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Profile"),
      body: FutureBuilder<Map<String, dynamic>>(
        future: userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No data available"));
          }

          final data = snapshot.data!;
          nameController.text = data['name'] ?? "";
          usernameController.text = data['username'] ?? "";
          emailController.text = data['email'] ?? "";
          final allergens = data['allergies'] as List<dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Personal Information",
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                Center(
                  child: Container(
                    width: 350,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isEditing
                            ? TextField(
                                controller: nameController,
                                decoration:
                                    const InputDecoration(labelText: "Name"),
                              )
                            : Text(
                                data['name'] ?? "No name saved",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                        const SizedBox(height: 8),

                        isEditing
                            ? TextField(
                                controller: usernameController,
                                decoration: const InputDecoration(
                                    labelText: "Username"),
                              )
                            : Text(
                                "Username: ${data['username']}",
                                style: const TextStyle(fontSize: 18),
                              ),

                        const SizedBox(height: 5),

                        isEditing
                            ? TextField(
                                controller: emailController,
                                decoration:
                                    const InputDecoration(labelText: "Email"),
                              )
                            : Text(
                                "Email: ${data['email']}",
                                style: const TextStyle(fontSize: 18),
                              ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                if (isEditing) {
                                  _updateProfile();
                                } else {
                                  setState(() {
                                    isEditing = true;
                                  });
                                }
                              },
                              child: Text(
                                  isEditing ? "Save" : "Edit Information"),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                              label: const Text("Logout"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Potential Allergens",
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.builder(
                      itemCount: allergens.length,
                      itemBuilder: (context, index) {
                        final allergen = allergens[index]['allergen_name'];
                        final severity = allergens[index]['severity'];

                        return Card(
                          child: ListTile(
                            title: Text(allergen),
                            subtitle: Text(
                              severity,
                              style: const TextStyle(color: Colors.blue),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAllergen(allergen),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}