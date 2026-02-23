// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/router/app_router.dart';

/// Bottom nav bar height (72) + bottom margin (16) + FAB height (60) + gap above bar (12)
/// so the entire FAB sits fully above the nav bar.
const double _kBottomNavHeightWithMargin = 72 + 16 + 60 + 12;

class AddTransactionFAB extends StatelessWidget {
  final VoidCallback? onSaved;

  const AddTransactionFAB({super.key, this.onSaved});

  @override
  Widget build(BuildContext context) {
    // Scaffold FAB location already adds MediaQuery.padding.bottom; we only add
    // the height of the bottom nav bar (72 + 16 margin + 12 gap) so FAB sits above it.
    return Container(
      margin: const EdgeInsets.only(bottom: _kBottomNavHeightWithMargin),
      child: GestureDetector(
        onTap: () async {
          final result = await context.goToAddTransaction<bool>();
          if (result == true && onSaved != null) {
            onSaved!();
          }
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
