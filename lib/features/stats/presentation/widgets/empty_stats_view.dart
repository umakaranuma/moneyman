import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Empty state for no income/expense data. Soft icon, no gradient circle.
class EmptyStatsView extends StatelessWidget {
  final bool isIncome;

  const EmptyStatsView({super.key, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.income : AppColors.expense;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pie_chart_outline_rounded,
              size: 56,
              color: color.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No ${isIncome ? 'income' : 'expense'} data',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your ${isIncome ? 'income' : 'expenses'}',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
