import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../config/api_config.dart';
import 'custom_app_bar.dart';

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
  String selectedSeverity = "mild";

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

  void showPopup(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
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
      appBar: const CustomAppBar(title: "Add Entry"),
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.coral.withOpacity(.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.coral.withOpacity(.18),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.coral),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "The more reactions and exposures you track, the more accurate your results will be for identifying possible allergens.",
                        style: TextStyle(
                          color: AppColors.navyText,
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              _InputCard(
                icon: Icons.science,
                label: "Allergy Trigger",
                child: TextField(
                  controller: triggerController,
                  decoration: const InputDecoration(
                    hintText: "Type a trigger, like dust, pollen, or dairy",
                    hintStyle: TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),

              _InputCard(
                icon: Icons.sick,
                label: "Symptom",
                child: TextField(
                  controller: symptomController,
                  decoration: const InputDecoration(
                    hintText: "Type a symptom, like itchy skin or sneezing",
                    hintStyle: TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),

              _InputCard(
                icon: Icons.warning_amber_rounded,
                label: "Severity",
                child: Row(
                  children: ["mild", "moderate", "severe"].map((level) {
                    final isSelected = selectedSeverity == level;

                    Color color;
                    if (level == "severe") {
                      color = Colors.redAccent;
                    } else if (level == "moderate") {
                      color = Colors.orangeAccent;
                    } else {
                      color = Colors.green;
                    }

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedSeverity = level;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(.95)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                level[0].toUpperCase() + level.substring(1),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.navyText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              _InputCard(
                icon: Icons.calendar_today,
                label: "Date",
                child: GestureDetector(
                  onTap: pickDate,
                  child: Text(
                    selectedDate == null
                        ? "Tap to select a date"
                        : "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}",
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate == null
                          ? Colors.black38
                          : AppColors.navyText,
                    ),
                  ),
                ),
              ),

              _InputCard(
                icon: Icons.notes,
                label: "Notes",
                child: TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Optional: add anything else you noticed",
                    hintStyle: TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (triggerController.text.trim().isEmpty ||
                        symptomController.text.trim().isEmpty ||
                        selectedDate == null) {
                      showPopup(
                        "Please fill out trigger, symptom, and date.",
                        isError: true,
                      );
                      return;
                    }

                    showPopup("Entry saved!", isError: false);

                    print("USER ID: ${widget.userId}");
                    print("Trigger: ${triggerController.text.trim()}");
                    print("Symptom: ${symptomController.text.trim()}");
                    print("Severity: $selectedSeverity");
                    print("Notes: ${notesController.text.trim()}");
                    print("Date: $selectedDate");
                  },
                  child: const Text(
                    "Save Entry",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(.05),
            offset: const Offset(0, 4),
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
              borderRadius: BorderRadius.circular(12),
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
                    color: AppColors.navyText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}