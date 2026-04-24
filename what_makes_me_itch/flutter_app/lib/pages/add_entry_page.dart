import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
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
                  ),
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
                    style: const TextStyle(fontSize: 16),
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
                  onPressed: () {
                    print("USER ID: ${widget.userId}");
                    print("Trigger: ${triggerController.text}");
                    print("Symptom: ${symptomController.text}");
                    print("Notes: ${notesController.text}");
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