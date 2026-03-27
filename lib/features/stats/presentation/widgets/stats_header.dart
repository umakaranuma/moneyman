import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';

/// Clean stats header: back (optional), title, month nav. No heavy borders.
class StatsHeader extends StatelessWidget {
  final String title;
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool showBackButton;

  const StatsHeader({
    super.key,
    required this.title,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
            ),
          if (showBackButton) const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.textPrimary,
          ),
          Text(
            DateFormat('MMM yyyy').format(month),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
