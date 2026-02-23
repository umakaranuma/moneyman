import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Bottom sheet to choose Daily / Weekly / Monthly. Clean, no gradients.
class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onSelected;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onSelected,
  });

  static const List<({String label, IconData icon})> options = [
    (label: 'Daily', icon: Icons.today_rounded),
    (label: 'Weekly', icon: Icons.view_week_rounded),
    (label: 'Monthly', icon: Icons.calendar_month_rounded),
  ];

  static void show(
    BuildContext context, {
    required String selectedPeriod,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PeriodSelector(
        selectedPeriod: selectedPeriod,
        onSelected: (p) {
          onSelected(p);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Period',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final isSelected = selectedPeriod == opt.label;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(opt.label),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        opt.icon,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        opt.label,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_rounded, color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
