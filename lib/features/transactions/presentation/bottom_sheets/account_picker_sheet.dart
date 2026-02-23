import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/transaction.dart';
import '../../../../theme/app_theme.dart';

/// Minimal account type picker. No gradients, clean list.
class AccountPickerSheet extends StatelessWidget {
  final AccountType selected;
  final ValueChanged<AccountType> onSelected;

  const AccountPickerSheet({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static String _label(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.card:
        return 'Card';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.other:
        return 'Other';
    }
  }

  static IconData _icon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.card:
        return Icons.credit_card_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.other:
        return Icons.account_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
              Text(
                'Select Account',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...AccountType.values.map((type) {
                final isSelected = selected == type;
                return ListTile(
                  leading: Icon(_icon(type), color: AppColors.primary, size: 22),
                  title: Text(
                    _label(type),
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 22)
                      : null,
                  onTap: () {
                    onSelected(type);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
