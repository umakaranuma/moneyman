import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/transaction.dart';
import '../../../../theme/app_theme.dart';

/// iOS-style detail rows: Category, Account, Date & Time. Clean, minimal.
class TransactionDetailsSection extends StatelessWidget {
  final TransactionType type;
  final Color activeColor;
  final String? selectedCategory;
  final String? selectedSubcategory;
  final AccountType accountType;
  final DateTime selectedDate;
  final String dateTimeLabel;
  final bool categoryError;
  final VoidCallback onCategoryTap;
  final VoidCallback onAccountTap;
  final VoidCallback onDateTap;
  final String Function(AccountType) getAccountLabel;

  const TransactionDetailsSection({
    super.key,
    required this.type,
    required this.activeColor,
    required this.selectedCategory,
    this.selectedSubcategory,
    required this.accountType,
    required this.selectedDate,
    required this.dateTimeLabel,
    required this.categoryError,
    required this.onCategoryTap,
    required this.onAccountTap,
    required this.onDateTap,
    required this.getAccountLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (type != TransactionType.transfer) ...[
            _DetailRow(
              title: 'Category',
              value: selectedCategory != null
                  ? (selectedSubcategory != null
                      ? '$selectedCategory • $selectedSubcategory'
                      : selectedCategory!)
                  : 'Select category',
              valueColor: categoryError ? AppColors.error : null,
              onTap: onCategoryTap,
            ),
            const _Divider(),
          ],
          _DetailRow(
            title: 'Account',
            value: getAccountLabel(accountType),
            onTap: onAccountTap,
          ),
          const _Divider(),
          _DetailRow(
            title: 'Date & Time',
            value: dateTimeLabel,
            onTap: onDateTap,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final VoidCallback onTap;

  const _DetailRow({
    required this.title,
    required this.value,
    this.valueColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: valueColor ?? AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.surfaceVariant.withValues(alpha: 0.6),
      indent: 20,
      endIndent: 20,
    );
  }
}
