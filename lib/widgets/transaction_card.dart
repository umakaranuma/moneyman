import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  String _getAccountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.card:
        return 'Card';
      case AccountType.bank:
        return 'Accounts';
      case AccountType.other:
        return 'Other';
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return 'Rs. ${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    String prefix;

    switch (transaction.type) {
      case TransactionType.income:
        color = AppColors.income;
        prefix = '+';
        break;
      case TransactionType.expense:
        color = AppColors.expense;
        prefix = '-';
        break;
      case TransactionType.transfer:
        color = AppColors.transfer;
        prefix = '';
        break;
    }

    final emoji = DefaultCategories.getCategoryEmoji(
      transaction.category,
      isIncome: transaction.type == TransactionType.income,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Category with emoji
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (emoji.isNotEmpty)
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (emoji.isNotEmpty) const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          transaction.category ?? 'Other',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Title and Account
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    transaction.type == TransactionType.transfer
                        ? '${transaction.fromAccount} → ${transaction.toAccount}'
                        : _getAccountTypeLabel(transaction.accountType),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Delete button if provided
            if (onDelete != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.expense,
                  size: 20,
                ),
                onPressed: onDelete,
              ),

            // Amount
            Text(
              '$prefix${_formatCurrency(transaction.amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
