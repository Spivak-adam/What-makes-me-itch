import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';

class AnalyticsPage extends StatefulWidget {
  final int userId;

  const AnalyticsPage({super.key, required this.userId});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool isLoading = true;
  String? errorMessage;

  int weeklyReactionCount = 0;
  String mostCommonTrigger = "N/A";
  String mostFrequentSymptom = "N/A";
  int entriesLogged = 0;
  String peakReactionTime = "N/A";

  List<Map<String, dynamic>> reactionTrend = [];

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Android emulator
      final uri = Uri.parse(
        "http://127.0.0.1:5000/api/analytics/${widget.userId}",
      );

      // If using physical phone, replace with your computer's local IP:
      // final uri = Uri.parse("http://192.168.1.100:5000/api/analytics/${widget.userId}");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          weeklyReactionCount = data["weeklySummary"]["reactionCount"] ?? 0;

          reactionTrend = List<Map<String, dynamic>>.from(
            data["reactionTrend"] ?? [],
          );

          mostCommonTrigger =
              data["insights"]["mostCommonTrigger"] ?? "N/A";
          mostFrequentSymptom =
              data["insights"]["mostFrequentSymptom"] ?? "N/A";
          entriesLogged = data["insights"]["entriesLogged"] ?? 0;
          peakReactionTime =
              data["insights"]["peakReactionTime"] ?? "N/A";

          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load analytics";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  List<FlSpot> buildChartSpots() {
    if (reactionTrend.isEmpty) {
      return const [
        FlSpot(0, 0),
        FlSpot(1, 0),
        FlSpot(2, 0),
        FlSpot(3, 0),
        FlSpot(4, 0),
        FlSpot(5, 0),
        FlSpot(6, 0),
      ];
    }

    return List.generate(reactionTrend.length, (index) {
      final item = reactionTrend[index];
      final count = (item["count"] ?? 0).toDouble();
      return FlSpot(index.toDouble(), count);
    });
  }

  double getMaxY() {
    if (reactionTrend.isEmpty) return 5;

    final counts = reactionTrend
        .map((item) => (item["count"] ?? 0).toDouble())
        .toList();

    final maxValue = counts.reduce((a, b) => a > b ? a : b);
    return maxValue < 5 ? 5 : maxValue + 1;
  }

  Widget buildChartLabels() {
    if (reactionTrend.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: reactionTrend.map((item) {
        return Expanded(
          child: Text(
            item["day"] ?? "",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchAnalytics,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView(
              children: [
                const SizedBox(height: 10),

                /// PAGE TITLE
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.coral.withOpacity(.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.bar_chart,
                        color: AppColors.coral,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Analytics",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (errorMessage != null)
                  Column(
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchAnalytics,
                        child: const Text("Retry"),
                      ),
                    ],
                  )
                else ...[
                  /// WEEKLY SUMMARY CARD
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.coral.withOpacity(.9),
                          AppColors.coral,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "This Week",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$weeklyReactionCount reactions logged",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// CHART SECTION
                  const Text(
                    "Reaction Trend",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(.05),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 180,
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: getMaxY(),
                              gridData: FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  color: AppColors.coral,
                                  barWidth: 4,
                                  spots: buildChartSpots(),
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(show: false),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        buildChartLabels(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// INSIGHTS HEADER
                  const Text(
                    "Allergy Insights",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _InsightCard(
                    icon: Icons.science,
                    title: "Most Common Trigger",
                    value: mostCommonTrigger,
                  ),

                  _InsightCard(
                    icon: Icons.sick,
                    title: "Most Frequent Symptom",
                    value: mostFrequentSymptom,
                  ),

                  _InsightCard(
                    icon: Icons.event_note,
                    title: "Entries Logged",
                    value: entriesLogged.toString(),
                  ),

                  _InsightCard(
                    icon: Icons.schedule,
                    title: "Peak Reaction Time",
                    value: peakReactionTime,
                  ),

                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// REUSABLE INSIGHT CARD
class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}