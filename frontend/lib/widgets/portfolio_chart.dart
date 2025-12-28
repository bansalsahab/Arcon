import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PortfolioChart extends StatelessWidget {
  final Map<String, dynamic> positions;

  const PortfolioChart({super.key, required this.positions});

  @override
  Widget build(BuildContext context) {
    if (positions.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'No investments yet',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final colors = [
      const Color(0xFFff9a8d),
      const Color(0xFF4a536b),
      const Color(0xFF8ed16f),
      const Color(0xFFff8c42),
      const Color(0xFF6366f1),
    ];

    final entries = positions.entries.toList();
    final total = entries.fold<double>(0, (sum, e) => sum + ((e.value as num?)?.toDouble() ?? 0));

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: entries.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final value = (data.value as num?)?.toDouble() ?? 0;
                final percentage = total > 0 ? (value / total * 100) : 0;

                return PieChartSectionData(
                  color: colors[index % colors.length],
                  value: value,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: entries.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  data.key,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
