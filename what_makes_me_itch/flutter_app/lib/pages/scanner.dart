import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_colors.dart';
import '../config/api_config.dart';
import 'custom_app_bar.dart';

class BarcodeEntryPage extends StatefulWidget {
  final int userId;

  const BarcodeEntryPage({super.key, required this.userId});

  @override
  State<BarcodeEntryPage> createState() => _BarcodeEntryPageState();
}

class _BarcodeEntryPageState extends State<BarcodeEntryPage> {
  final MobileScannerController scannerController = MobileScannerController();

  final TextEditingController symptomController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool hasScanned = false;
  bool isLoadingProduct = false;
  bool isSaving = false;

  String scannerStatus = "Camera ready. Point it at a barcode.";

  String? barcode;
  String? productName;
  String? ingredients;
  String? brand;
  String? imageUrl;

  String selectedSeverity = "mild";
  DateTime? selectedDate;

  Future<void> lookupProduct(String scannedCode) async {
    setState(() {
      hasScanned = true;
      isLoadingProduct = true;
      barcode = scannedCode;
      scannerStatus = "Barcode read. Looking up product...";
    });

    try {
      final uri = Uri.parse(
        "https://world.openfoodfacts.org/api/v2/product/$scannedCode.json",
      );

      final response = await http.get(
        uri,
        headers: {
          "User-Agent": "WhatMakesMeItch/1.0 (your-email@example.com)",
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data["status"] != 1) {
        showPopup("Barcode read, but product was not found.", isError: true);
        resetScanner();
        return;
      }

      final product = data["product"];

      setState(() {
        productName = product["product_name"] ?? "Unknown Product";
        brand = product["brands"];
        ingredients = product["ingredients_text"] ?? "";
        imageUrl = product["image_url"];
        scannerStatus = "Product found!";
      });
    } catch (e) {
      showPopup("Barcode read, but product lookup failed.", isError: true);
      resetScanner();
    } finally {
      if (mounted) {
        setState(() {
          isLoadingProduct = false;
        });
      }
    }
  }

  Future<void> saveScannedReaction() async {
    if (productName == null || productName!.isEmpty) {
      showPopup("No product selected.", isError: true);
      return;
    }

    if (symptomController.text.trim().isEmpty) {
      showPopup("Please enter the reaction/symptom.", isError: true);
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final uri = Uri.parse("${ApiConfig.baseUrl}/api/scanned-product-entry");

      final requestBody = {
        "user_id": widget.userId,
        "barcode": barcode,
        "product_name": productName,
        "brand": brand,
        "ingredients": ingredients,
        "allergen_name": productName,
        "severity": selectedSeverity,
        "reaction": symptomController.text.trim(),
        "notes": notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        "date_added": formatDateForBackend(selectedDate ?? DateTime.now()),
      };

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        showPopup("Scanned product saved!", isError: false);
        resetForm();
      } else {
        showPopup("Failed to save product reaction.", isError: true);
      }
    } catch (e) {
      showPopup("Failed to save product reaction.", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void resetScanner() {
    setState(() {
      hasScanned = false;
      barcode = null;
      scannerStatus = "Camera ready. Point it at a barcode.";
    });
  }

  void resetForm() {
    symptomController.clear();
    notesController.clear();

    setState(() {
      hasScanned = false;
      barcode = null;
      productName = null;
      ingredients = null;
      brand = null;
      imageUrl = null;
      selectedSeverity = "mild";
      selectedDate = null;
      scannerStatus = "Camera ready. Point it at a barcode.";
    });
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
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

  String formatDateForBackend(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return "$year-$month-$day 00:00:00";
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
    scannerController.dispose();
    symptomController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Widget buildScannerBox() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.coral,
          width: 3,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: MobileScanner(
              controller: scannerController,
              onDetect: (capture) {
                if (hasScanned) return;

                final barcodes = capture.barcodes;

                if (barcodes.isEmpty) {
                  setState(() {
                    scannerStatus = "Camera active, no barcode found yet.";
                  });
                  debugPrint("Camera active, but no barcode detected.");
                  return;
                }

                final scannedCode = barcodes.first.rawValue;

                if (scannedCode == null || scannedCode.isEmpty) {
                  setState(() {
                    scannerStatus =
                        "Barcode seen, but I could not read it. Try better lighting.";
                  });

                  debugPrint("Barcode detected, but could not read value.");
                  return;
                }

                debugPrint("Barcode read successfully: $scannedCode");

                setState(() {
                  scannerStatus = "Barcode read: $scannedCode";
                });

                lookupProduct(scannedCode);
              },
            ),
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                scannerStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          Center(
            child: Container(
              width: 220,
              height: 110,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                "Hold the barcode inside the box",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Scan Product"),
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 10),

            if (!hasScanned) buildScannerBox(),

            if (isLoadingProduct)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (productName != null && !isLoadingProduct) ...[
              _InputCard(
                icon: Icons.qr_code,
                label: "Scanned Barcode",
                child: Text(
                  barcode ?? "",
                  style: const TextStyle(
                    color: AppColors.navyText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (imageUrl != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

              _InputCard(
                icon: Icons.fastfood,
                label: "Product",
                child: Text(
                  brand == null || brand!.isEmpty
                      ? productName!
                      : "$productName\n$brand",
                  style: const TextStyle(
                    color: AppColors.navyText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              _InputCard(
                icon: Icons.list_alt,
                label: "Ingredients",
                child: Text(
                  ingredients == null || ingredients!.isEmpty
                      ? "No ingredients found."
                      : ingredients!,
                  style: const TextStyle(
                    color: AppColors.navyText,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),

              _InputCard(
                icon: Icons.sick,
                label: "Did this cause a reaction?",
                child: TextField(
                  controller: symptomController,
                  decoration: const InputDecoration(
                    hintText: "Example: itchy skin, rash, sneezing",
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
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSeverity = level;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(.95)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? color : Colors.grey.shade300,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              level[0].toUpperCase() + level.substring(1),
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
                        ? "Today, or tap to change"
                        : "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.navyText,
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
                    hintText: "Optional notes",
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(height: 12),

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
                  onPressed: isSaving ? null : saveScannedReaction,
                  child: Text(
                    isSaving ? "Saving..." : "Save Reaction",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              TextButton(
                onPressed: resetForm,
                child: const Text("Scan another product"),
              ),
            ],

            const SizedBox(height: 90),
          ],
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