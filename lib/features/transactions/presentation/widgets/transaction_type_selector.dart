import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/transaction.dart';
import '../../../../theme/app_theme.dart';

/// Pill-style transaction type selector. Premium fintech: one accent per type, soft elevation.
class TransactionTypeSelector extends StatelessWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onChanged;
  final bool enabled;

  const TransactionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
    this.enabled = true,
  });

  static Color _colorFor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.primary;
      case TransactionType.transfer:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _Pill(
              label: 'Income',
              type: TransactionType.income,
              isSelected: selectedType == TransactionType.income,
              color: _colorFor(TransactionType.income),
              onTap: enabled ? () => onChanged(TransactionType.income) : null,
            ),
            _Pill(
              label: 'Expense',
              type: TransactionType.expense,
              isSelected: selectedType == TransactionType.expense,
              color: _colorFor(TransactionType.expense),
              onTap: enabled ? () => onChanged(TransactionType.expense) : null,
            ),
            _Pill(
              label: 'Transfer',
              type: TransactionType.transfer,
              isSelected: selectedType == TransactionType.transfer,
              color: _colorFor(TransactionType.transfer),
              onTap: enabled ? () => onChanged(TransactionType.transfer) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final TransactionType type;
  final bool isSelected;
  final Color color;
  final VoidCallback? onTap;

  const _Pill({
    required this.label,
    required this.type,
    required this.isSelected,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
