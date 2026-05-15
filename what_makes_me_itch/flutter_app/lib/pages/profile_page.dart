import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
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
  String selectedSeverityFilter = "all";
  String selectedSort = "severity";

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
        await http.get(Uri.parse('${ApiConfig.baseUrl}/user/$userId'));

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
        Uri.parse('${ApiConfig.baseUrl}/update_user/${widget.userId}'),
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
        Uri.parse('${ApiConfig.baseUrl}/add_allergy'),
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
        Uri.parse('${ApiConfig.baseUrl}/delete_allergy'),
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

  int _severityRank(String severity) {
    switch (severity.toLowerCase()) {
      case "severe":
        return 0;
      case "moderate":
        return 1;
      case "mild":
        return 2;
      default:
        return 3;
    }
  }

  DateTime? _parseAllergenDate(dynamic rawDate) {
    if (rawDate == null) return null;
    final dateString = rawDate.toString().trim();

    if (dateString.isEmpty) return null;

    try {
      return DateTime.parse(dateString);
    } catch (_) {}

    final knownFormats = [
      DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'"),
      DateFormat("yyyy-MM-dd HH:mm:ss"),
      DateFormat("yyyy-MM-dd"),
    ];

    for (final format in knownFormats) {
      try {
        final parsed = format.parseUtc(dateString);
        return parsed;
      } catch (_) {
        // try next format
      }
    }

    return null;
  }

  String _formatAllergenDate(dynamic rawDate) {
    final parsed = _parseAllergenDate(rawDate);
    if (parsed == null) return "Date unavailable";
    return DateFormat.yMMMd().add_jm().format(parsed.toLocal());
  }

  String _allergenInfo(String allergenName) {
    final lookup = allergenName.toLowerCase();
    if (lookup.contains("peanut")) {
      return "Peanut allergy can trigger severe reactions. Common sources include snacks, sauces, baked goods, and cross-contact during food prep.";
    }
    if (lookup.contains("dairy") || lookup.contains("milk")) {
      return "Dairy allergens are commonly found in milk, cheese, butter, cream, and many processed foods.";
    }
    if (lookup.contains("egg")) {
      return "Egg allergy may involve both egg whites and yolks. Eggs can appear in baked foods, dressings, and some vaccines.";
    }
    if (lookup.contains("shellfish") || lookup.contains("shrimp")) {
      return "Shellfish allergies often include shrimp, crab, and lobster. Reactions can be severe even with trace exposure.";
    }
    if (lookup.contains("soy")) {
      return "Soy can appear in sauces, protein products, oils, and packaged foods under different ingredient names.";
    }
    return "Track this allergen carefully and review food labels, ingredient lists, and possible cross-contact sources.";
  }

  void _showAllergenDetails(Map<String, dynamic> allergenEntry) {
    final allergenName = allergenEntry['allergen_name'] ?? "Unknown";
    final severity = allergenEntry['severity'] ?? "unknown";
    final reaction = (allergenEntry['reaction'] ?? "Not provided").toString();
    final location = (allergenEntry['location'] ?? "Not provided").toString();
    final productId = allergenEntry['product_id'];
    final productName = allergenEntry['product_name'];
    final loggedDate = _formatAllergenDate(allergenEntry['date_added']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(allergenName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Severity: ${severity[0].toUpperCase()}${severity.substring(1)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _severityColor(severity),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Logged: $loggedDate",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              "Allergen entry",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text("Allergen: $allergenName"),
            const SizedBox(height: 4),
            Text("Reaction: $reaction"),
            const SizedBox(height: 4),
            Text("Location: $location"),
            if (productId != null) ...[
              const SizedBox(height: 4),
              Text(
                "Product: ${productName?.toString().isNotEmpty == true ? productName : "ID $productId"}",
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              "About this allergen",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(_allergenInfo(allergenName)),
            const SizedBox(height: 12),
            const Text(
              "Tip: Verify ingredients when trying new foods and keep emergency medicine available if prescribed.",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllergen(allergenName);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
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
          final filteredAndSortedAllergens = allergens
              .where((allergen) =>
                  selectedSeverityFilter == "all" ||
                  allergen['severity'] == selectedSeverityFilter)
              .toList()
            ..sort((a, b) {
              if (selectedSort == "name") {
                return a['allergen_name']
                    .toString()
                    .toLowerCase()
                    .compareTo(b['allergen_name'].toString().toLowerCase());
              }
              if (selectedSort == "date") {
                final dateA = _parseAllergenDate(a['date_added']);
                final dateB = _parseAllergenDate(b['date_added']);
                if (dateA == null && dateB == null) {
                  return a['allergen_name']
                      .toString()
                      .toLowerCase()
                      .compareTo(b['allergen_name'].toString().toLowerCase());
                }
                if (dateA == null) return 1;
                if (dateB == null) return -1;
                return dateB.compareTo(dateA);
              }
              final severityCompare =
                  _severityRank(a['severity']).compareTo(_severityRank(b['severity']));
              if (severityCompare != 0) {
                return severityCompare;
              }
              return a['allergen_name']
                  .toString()
                  .toLowerCase()
                  .compareTo(b['allergen_name'].toString().toLowerCase());
            });

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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSeverityFilter,
                        decoration: const InputDecoration(
                          labelText: "Filter",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: "all", child: Text("All")),
                          DropdownMenuItem(value: "severe", child: Text("Severe")),
                          DropdownMenuItem(
                              value: "moderate", child: Text("Moderate")),
                          DropdownMenuItem(value: "mild", child: Text("Mild")),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedSeverityFilter = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSort,
                        decoration: const InputDecoration(
                          labelText: "Sort",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: "severity", child: Text("By severity")),
                          DropdownMenuItem(value: "name", child: Text("By name")),
                          DropdownMenuItem(value: "date", child: Text("By date")),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedSort = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
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
                    itemCount: filteredAndSortedAllergens.length,
                    itemBuilder: (context, index) {
                      final allergenEntry = filteredAndSortedAllergens[index];
                      final allergen = allergenEntry['allergen_name'];
                      final severity = allergenEntry['severity'];
                      final color = _severityColor(severity);

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () => _showAllergenDetails(allergenEntry),
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
                            "$severity • ${_formatAllergenDate(allergenEntry['date_added'])}",
                            style: TextStyle(color: color),
                          ),
                          trailing: const Icon(Icons.chevron_right),
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
