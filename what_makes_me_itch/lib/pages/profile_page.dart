import 'package:flutter/material.dart';
import 'custom_app_bar.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  List<Map<String, dynamic>> allergens = [
    {
      "severity": "High Severity",
      "items": ["Peanuts", "Shellfish"]
    },
    {
      "severity": "Medium Severity",
      "items": ["Dust Mites", "Dairy"]
    },
    {
      "severity": "Low Severity",
      "items": ["Pollens", "Pet Dander"]
    },
  ];

  void _editPersonalInfo() {
    // Implement edit functionality here
  }

  void _deleteAllergen(String severity, String allergen) {
    setState(() {
      for (var group in allergens) {
        if (group["severity"] == severity) {
          group["items"].remove(allergen);
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Profile"),
      body: Padding(
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
                    Text("John Doe",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("Age: 25", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 5),
                    Text("Email: johndoe@example.com",
                        style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _editPersonalInfo,
                      child: Text("Edit Information"),
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
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: allergens.length,
                        itemBuilder: (context, index) {
                          final allergenGroup = allergens[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(allergenGroup["severity"],
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue)),
                              Column(
                                children: List.generate(
                                  allergenGroup["items"].length,
                                  (i) => Card(
                                    child: ListTile(
                                      title: Text(allergenGroup["items"][i]),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _deleteAllergen(
                                            allergenGroup["severity"],
                                            allergenGroup["items"][i]),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          () {}, // Placeholder for future allergen editing functionality
                      child: Text("Edit Allergens"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}