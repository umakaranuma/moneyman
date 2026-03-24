import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../utils/helpers.dart';
import '../../../../theme/app_theme.dart';

/// Clean pie chart card: soft surface, one subtle shadow, no gradient/borders.
class PieChartCard extends StatelessWidget {
  final double total;
  final List<PieChartSectionData> sections;
  final bool isIncome;

  const PieChartCard({
    super.key,
    required this.total,
    required this.sections,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 70,
                    sections: sections,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Helpers.formatCurrency(total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isIncome ? 'Total Income' : 'Total Expense',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Build [PieChartSectionData] list from category entries and total.
List<PieChartSectionData> buildPieSections(
  List<MapEntry<String, double>> entries,
  double total,
) {
  return entries.asMap().entries.map((mapEntry) {
    final index = mapEntry.key;
    final entry = mapEntry.value;
    final color =
        AppColors.categoryColors[index % AppColors.categoryColors.length];
    return PieChartSectionData(
      value: entry.value,
      title: '',
      color: color,
      radius: 60,
      badgeWidget: null,
    );
  }).toList();
}
