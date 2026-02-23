import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';

/// Segmented control: Income | Expenses. Premium, no gradients.
class IncomeExpenseSegment extends StatelessWidget {
  final TabController controller;
  final double income;
  final double expense;

  const IncomeExpenseSegment({
    super.key,
    required this.controller,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _Segment(
            label: 'Income',
            amount: income,
            isSelected: controller.index == 0,
            accentColor: AppColors.income,
            onTap: () => controller.animateTo(0),
          ),
          _Segment(
            label: 'Expenses',
            amount: expense,
            isSelected: controller.index == 1,
            accentColor: AppColors.expense,
            onTap: () => controller.animateTo(1),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final double amount;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.amount,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rs. ${NumberFormat('#,##0').format(amount)}',
                style: TextStyle(
                  color: isSelected ? Colors.white : accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
