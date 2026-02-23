// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../../models/transaction.dart';
import '../../../../models/category.dart';
import '../../../../theme/app_theme.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
  });

  static String formatAmount(double value) {
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isExpense = transaction.type == TransactionType.expense;
    final color = isIncome
        ? AppColors.income
        : isExpense
        ? AppColors.expense
        : AppColors.transfer;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: _buildIcon(isIncome, isExpense)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.category ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Rs. ${formatAmount(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(bool isIncome, bool isExpense) {
    final emoji = DefaultCategories.getCategoryEmoji(
      transaction.category,
      isIncome: isIncome,
    );
    if (emoji.isNotEmpty) {
      return Text(emoji, style: const TextStyle(fontSize: 18));
    }
    return Icon(
      isIncome
          ? Icons.arrow_downward_rounded
          : isExpense
          ? Icons.arrow_upward_rounded
          : Icons.swap_horiz_rounded,
      color: isIncome
          ? AppColors.income
          : isExpense
          ? AppColors.expense
          : AppColors.transfer,
      size: 18,
    );
  }
}
