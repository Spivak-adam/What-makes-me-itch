import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../config/api_config.dart';

class AddEntryPage extends StatefulWidget {
  final int userId;

  const AddEntryPage({super.key, required this.userId});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final TextEditingController triggerController = TextEditingController();
  final TextEditingController symptomController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  DateTime? selectedDate;
  bool isSaving = false;

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String? formatDateForBackend(DateTime? date) {
    if (date == null) return null;

    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return "$year-$month-$day 00:00:00";
  }

  Future<void> saveEntry() async {
    final trigger = triggerController.text.trim();
    final symptom = symptomController.text.trim();
    final notes = notesController.text.trim();

    if (trigger.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an allergy trigger")),
      );
      return;
    }

    if (symptom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a symptom")),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final uri = Uri.parse("${ApiConfig.baseUrl}/api/allergies");

      // For physical device, use your computer's local IP instead:
      // final uri = Uri.parse("http://192.168.1.100:5000/api/allergies");

      final requestBody = {
        "user_id": widget.userId,
        "allergen_name": trigger,
        "reaction": symptom,
        "notes": notes.isEmpty ? null : notes,
        "date_added": formatDateForBackend(selectedDate),
      };

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Entry saved successfully")),
        );

        triggerController.clear();
        symptomController.clear();
        notesController.clear();

        setState(() {
          selectedDate = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["error"] ?? "Failed to save entry"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving entry: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    triggerController.dispose();
    symptomController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 10),

              /// PAGE HEADER
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withOpacity(.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add, color: AppColors.coral, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Add Entry",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),

              const SizedBox(height: 25),

              /// TRIGGER FIELD
              _InputCard(
                icon: Icons.science,
                label: "Allergy Trigger",
                child: TextField(
                  controller: triggerController,
                  decoration: const InputDecoration(
                    hintText: "Example: Dust, Pollen, Dairy",
                    border: InputBorder.none,
                  ),
                ),
              ),

              /// SYMPTOM FIELD
              _InputCard(
                icon: Icons.sick,
                label: "Symptom",
                child: TextField(
                  controller: symptomController,
                  decoration: const InputDecoration(
                    hintText: "Example: Itchy Skin, Sneezing",
                    border: InputBorder.none,
                  ),
                ),
              ),

              /// DATE FIELD
              _InputCard(
                icon: Icons.calendar_today,
                label: "Date",
                child: GestureDetector(
                  onTap: pickDate,
                  child: Text(
                    selectedDate == null
                        ? "Select Date"
                        : "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}",
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate == null
                          ? Colors.black54
                          : Colors.black,
                    ),
                  ),
                ),
              ),

              /// NOTES FIELD
              _InputCard(
                icon: Icons.notes,
                label: "Notes",
                child: TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Optional notes about the reaction",
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// SUBMIT BUTTON
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isSaving ? null : saveEntry,
                  child: isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Save Entry",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// REUSABLE INPUT CARD
class _InputCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _InputCard({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(.05),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.coral.withOpacity(.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.coral),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 5),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}