import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

import '../theme/app_colors.dart';
import 'custom_app_bar.dart';

class AnalyticsPage extends StatefulWidget {
  final int userId;

  const AnalyticsPage({super.key, required this.userId});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late Future<Map<String, dynamic>> analyticsData;

  @override
  void initState() {
    super.initState();
    analyticsData = fetchAnalytics();
  }

  Future<Map<String, dynamic>> fetchAnalytics() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/analytics/${widget.userId}'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load analytics");
    }
  }

  String _highestSeverity(int severe, int moderate, int mild) {
    if (severe > 0) return "Severe";
    if (moderate > 0) return "Moderate";
    if (mild > 0) return "Mild";
    return "None yet";
  }

  List<MapEntry<String, int>> _topTriggers(List<dynamic> recent) {
    final Map<String, int> counts = {};

    for (final item in recent) {
      final name = item["allergen_name"]?.toString() ?? "Unknown";
      counts[name] = (counts[name] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).toList();
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
      appBar: const CustomAppBar(title: "Analytics"),
      backgroundColor: Colors.grey.shade100,
      body: FutureBuilder<Map<String, dynamic>>(
        future: analyticsData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;
          final total = data["total_entries"] ?? 0;
          final severe = data["severe_count"] ?? 0;
          final moderate = data["moderate_count"] ?? 0;
          final mild = data["mild_count"] ?? 0;
          final mostCommon = data["most_common_trigger"] ?? "None yet";
          final recent = data["recent_allergies"] as List<dynamic>;
          final highestSeverity = _highestSeverity(severe, moderate, mild);
          final topTriggers = _topTriggers(recent);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RiskOverviewCard(
                  total: total,
                  mostCommon: mostCommon,
                  highestSeverity: highestSeverity,
                ),

                const SizedBox(height: 22),

                const Text(
                  "Severity Breakdown",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyText,
                  ),
                ),

                const SizedBox(height: 12),

                _SeverityChartCard(
                  mild: mild,
                  moderate: moderate,
                  severe: severe,
                  total: total,
                ),

                const SizedBox(height: 22),

                const Text(
                  "Top Triggers",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyText,
                  ),
                ),

                const SizedBox(height: 12),

                if (topTriggers.isEmpty)
                  const _EmptyCard(
                    icon: Icons.insights,
                    title: "No trigger patterns yet",
                    subtitle: "Add allergens to start seeing your top triggers.",
                  )
                else
                  ...topTriggers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final trigger = entry.value;

                    return _TriggerRankCard(
                      rank: index + 1,
                      name: trigger.key,
                      count: trigger.value,
                    );
                  }),

                const SizedBox(height: 22),

                const Text(
                  "Recent Activity",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyText,
                  ),
                ),

                const SizedBox(height: 12),

                if (recent.isEmpty)
                  const _EmptyCard(
                    icon: Icons.timeline,
                    title: "No recent activity",
                    subtitle: "Your recently added allergens will appear here.",
                  )
                else
                  ...recent.map((item) {
                    final name = item["allergen_name"]?.toString() ?? "Unknown";
                    final severity = item["severity"]?.toString() ?? "mild";
                    return _TimelineCard(
                      name: name,
                      severity: severity,
                      color: _severityColor(severity),
                    );
                  }),

                const SizedBox(height: 22),

                _InsightCallout(
                  total: total,
                  severe: severe,
                  mostCommon: mostCommon,
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

class _RiskOverviewCard extends StatelessWidget {
  final int total;
  final String mostCommon;
  final String highestSeverity;

  const _RiskOverviewCard({
    required this.total,
    required this.mostCommon,
    required this.highestSeverity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.coral.withOpacity(.88),
            AppColors.coral,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            color: AppColors.coral.withOpacity(.25),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Allergy Risk Overview",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$total allergens logged",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: "Highest",
                  value: highestSeverity,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: "Top Trigger",
                  value: mostCommon,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityChartCard extends StatelessWidget {
  final int mild;
  final int moderate;
  final int severe;
  final int total;

  const _SeverityChartCard({
    required this.mild,
    required this.moderate,
    required this.severe,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return const _EmptyCard(
        icon: Icons.pie_chart_outline,
        title: "No severity data yet",
        subtitle: "Add allergens with severity levels to build your chart.",
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(.05),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 150,
            width: 150,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 38,
                sectionsSpace: 3,
                sections: [
                  if (severe > 0)
                    PieChartSectionData(
                      value: severe.toDouble(),
                      color: Colors.redAccent,
                      title: severe.toString(),
                      radius: 42,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (moderate > 0)
                    PieChartSectionData(
                      value: moderate.toDouble(),
                      color: Colors.orangeAccent,
                      title: moderate.toString(),
                      radius: 42,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (mild > 0)
                    PieChartSectionData(
                      value: mild.toDouble(),
                      color: Colors.green,
                      title: mild.toString(),
                      radius: 42,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                _LegendRow(label: "Severe", value: severe, color: Colors.redAccent),
                _LegendRow(label: "Moderate", value: moderate, color: Colors.orangeAccent),
                _LegendRow(label: "Mild", value: mild, color: Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _LegendRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TriggerRankCard extends StatelessWidget {
  final int rank;
  final String name;
  final int count;

  const _TriggerRankCard({
    required this.rank,
    required this.name,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(.04),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.coral.withOpacity(.15),
            child: Text(
              "$rank",
              style: const TextStyle(
                color: AppColors.coral,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            "${count}x",
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final String name;
  final String severity;
  final Color color;

  const _TimelineCard({
    required this.name,
    required this.severity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 8,
                backgroundColor: color,
              ),
              Container(
                height: 48,
                width: 2,
                color: color.withOpacity(.25),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(.04),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      severity,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCallout extends StatelessWidget {
  final int total;
  final int severe;
  final String mostCommon;

  const _InsightCallout({
    required this.total,
    required this.severe,
    required this.mostCommon,
  });

  @override
  Widget build(BuildContext context) {
    String message;

    if (total == 0) {
      message = "Start adding known allergens to unlock personalized insights.";
    } else if (severe > 0) {
      message =
          "You have severe allergens logged. Keep these visible and consider sharing them with a doctor.";
    } else {
      message =
          "Your most common logged trigger is $mostCommon. Watch for repeated exposure patterns.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.coral.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.coral.withOpacity(.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.coral),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.navyText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.black38),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}