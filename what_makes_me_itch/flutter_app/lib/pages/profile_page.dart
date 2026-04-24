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

  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

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

  void _showPopup(String message, {required bool isError}) {
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
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

        _showPopup("Profile updated successfully!", isError: false);
      } else {
        _showPopup("Failed to update profile.", isError: true);
      }
    } catch (e) {
      _showPopup("Error updating profile.", isError: true);
    }
  }

  void _addAllergy(String allergenName, String severity) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/add_allergy'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "allergen_name": allergenName,
          "severity": severity,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          userData = fetchUserData(widget.userId);
        });

        _showPopup("Allergy added successfully!", isError: false);
      } else {
        final errorMessage = jsonDecode(response.body)['error'];
        _showPopup("Failed to add allergy: $errorMessage", isError: true);
      }
    } catch (e) {
      _showPopup("Error adding allergy.", isError: true);
    }
  }

  void _showAddAllergyDialog() {
    final TextEditingController allergyController = TextEditingController();
    String selectedSeverity = "mild";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Allergy"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: allergyController,
                    decoration: const InputDecoration(
                      labelText: "Allergy name",
                      hintText: "Example: Peanuts",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedSeverity,
                    decoration: const InputDecoration(
                      labelText: "Severity",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "mild", child: Text("Mild")),
                      DropdownMenuItem(
                          value: "moderate", child: Text("Moderate")),
                      DropdownMenuItem(value: "severe", child: Text("Severe")),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedSeverity = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    allergyController.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final allergyName = allergyController.text.trim();

                    if (allergyName.isEmpty) {
                      _showPopup("Please enter an allergy name.",
                          isError: true);
                      return;
                    }

                    allergyController.dispose();
                    Navigator.pop(context);
                    _addAllergy(allergyName, selectedSeverity);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
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

        _showPopup("Allergen deleted successfully!", isError: false);
      } else {
        final errorMessage = jsonDecode(response.body)['error'];
        _showPopup("Failed to delete allergen: $errorMessage", isError: true);
      }
    } catch (e) {
      _showPopup("Error deleting allergen.", isError: true);
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case "severe":
        return Colors.redAccent;
      case "moderate":
        return Colors.orangeAccent;
      case "mild":
        return Colors.green;
      default:
        return Colors.blueGrey;
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
          final allergens = data['allergies'] as List<dynamic>;

          nameController.text = data['name'] ?? "";
          usernameController.text = data['username'] ?? "";
          emailController.text = data['email'] ?? "";

          final severe =
              allergens.where((a) => a['severity'] == 'severe').length;
          final moderate =
              allergens.where((a) => a['severity'] == 'moderate').length;
          final mild = allergens.where((a) => a['severity'] == 'mild').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 42,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (isEditing) ...[
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: "Name",
                            border: OutlineInputBorder(),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: "Username",
                            border: OutlineInputBorder(),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                            filled: true,
                          ),
                        ),
                      ] else ...[
                        Text(
                          data['name'] ?? "No name saved",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "@${data['username']}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data['email'],
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (isEditing) {
                                _updateProfile();
                              } else {
                                setState(() {
                                  isEditing = true;
                                });
                              }
                            },
                            icon: Icon(isEditing ? Icons.save : Icons.edit),
                            label: Text(isEditing ? "Save" : "Edit"),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text("Logout"),
                          ),
                        ],
                      ),
                      if (isEditing) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isEditing = false;
                              nameController.text = data['name'] ?? "";
                              usernameController.text = data['username'] ?? "";
                              emailController.text = data['email'] ?? "";
                            });
                          },
                          child: const Text("Cancel"),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _StatCard(
                      label: "Allergens",
                      value: allergens.length.toString(),
                      icon: Icons.warning_amber_rounded,
                    ),
                    _StatCard(
                      label: "Severe",
                      value: severe.toString(),
                      icon: Icons.priority_high,
                    ),
                    _StatCard(
                      label: "Moderate",
                      value: moderate.toString(),
                      icon: Icons.trending_up,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Potential Allergens",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddAllergyDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Add"),
                    ),
                  ],
                ),
                if (mild > 0) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "$mild mild allergen${mild == 1 ? '' : 's'} logged",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (allergens.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          size: 42,
                          color: Colors.black38,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "No allergens logged yet",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Tap Add to manually enter allergies you already know about.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allergens.length,
                    itemBuilder: (context, index) {
                      final allergen = allergens[index]['allergen_name'];
                      final severity = allergens[index]['severity'];
                      final color = _severityColor(severity);

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.15),
                            child: Icon(
                              Icons.science_outlined,
                              color: color,
                            ),
                          ),
                          title: Text(
                            allergen,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            severity,
                            style: TextStyle(color: color),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteAllergen(allergen),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 90),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.blue[700]),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}