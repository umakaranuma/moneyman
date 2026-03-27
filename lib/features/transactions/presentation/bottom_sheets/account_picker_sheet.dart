import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/transaction.dart';
import '../../../../theme/app_theme.dart';

/// Account type picker — matches [CategoryPickerSheet] layout and styling.
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

  static String _subtitle(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Physical cash';
      case AccountType.card:
        return 'Debit or credit card';
      case AccountType.bank:
        return 'Banking & transfers';
      case AccountType.other:
        return 'Custom or misc.';
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
    final accent = AppColors.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Account',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Where this transaction is recorded',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: AccountType.values.length,
                itemBuilder: (context, index) {
                  final type = AccountType.values[index];
                  final isSelected = selected == type;
                  return _AccountTile(
                    label: _label(type),
                    subtitle: _subtitle(type),
                    icon: _icon(type),
                    isSelected: isSelected,
                    accent: accent,
                    onTap: () {
                      onSelected(type);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _AccountTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? accent.withValues(alpha: 0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? accent.withValues(alpha: 0.45)
              : AppColors.surfaceVariant.withValues(alpha: 0.45),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected ? accent : AppColors.textSecondary,
            size: 21,
          ),
        ),
        minVerticalPadding: 8,
        horizontalTitleGap: 10,
        minLeadingWidth: 0,
        visualDensity: const VisualDensity(vertical: -1),
        title: Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: accent, size: 22)
            : Icon(
                Icons.radio_button_unchecked_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
        onTap: onTap,
      ),
    );
  }
}
