import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'custom_app_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> userData;
  bool isEditing = false;
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  int userId = 1; // Replace with dynamic user ID

  @override
  void initState() {
    super.initState();
    userData = fetchUserData(userId);
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

  void _updateProfile() async {
    try {
      final response = await http.put(
        Uri.parse('http://127.0.0.1:5000/update_user/$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text,
          "email": emailController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          isEditing = false;
          userData = fetchUserData(userId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile")),
      );
    }
  }

  void _deleteAllergen(String allergenName) async {
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:5000/delete_allergy'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "allergen_name": allergenName}),
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = fetchUserData(userId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Allergen deleted successfully!")),
        );
      } else {
        final errorMessage = jsonDecode(response.body)['error'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete allergen: $errorMessage")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting allergen")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Profile"),
      body: FutureBuilder<Map<String, dynamic>>(
        key: UniqueKey(),
        future: userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return Center(child: Text("No data available"));
          }

          final data = snapshot.data!;
          usernameController.text = data['username'];
          emailController.text = data['email'];
          final allergens = data['allergies'] as List<dynamic>;

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Personal Information",
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center),
                SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 350,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isEditing
                            ? TextField(
                                controller: usernameController,
                                decoration:
                                    InputDecoration(labelText: "Username"),
                              )
                            : Text(
                                data['username'],
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                        SizedBox(height: 5),
                        isEditing
                            ? TextField(
                                controller: emailController,
                                decoration: InputDecoration(labelText: "Email"),
                              )
                            : Text("Email: ${data['email']}",
                                style: TextStyle(fontSize: 18)),
                        SizedBox(height: 10),
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
                          child: Text(isEditing ? "Save" : "Edit Information"),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text("Potential Allergens",
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center),
                SizedBox(height: 10),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
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
                            subtitle: Text(severity,
                                style: TextStyle(color: Colors.blue)),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
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
