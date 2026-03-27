import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../utils/helpers.dart';
import '../../../../models/transaction.dart';
import '../../../../theme/app_theme.dart';
import '../widgets/transaction_item.dart';

void showDayTransactionsSheet(
  BuildContext context, {
  required DateTime date,
  required List<Transaction> transactions,
  required void Function(Transaction) onTransactionTap,
}) {
  transactions.sort((a, b) => b.date.compareTo(a.date));

  final dayIncome = transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
  final dayExpense = transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
  final dayTransfer = transactions
      .where((t) => t.type == TransactionType.transfer)
      .fold(0.0, (sum, t) => sum + t.amount);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(date),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (dayIncome > 0) _DotLabel('+${Helpers.formatCurrency(dayIncome)}', AppColors.income),
                          if (dayExpense > 0) _DotLabel('-${Helpers.formatCurrency(dayExpense)}', AppColors.expense),
                          if (dayTransfer > 0) _DotLabel(Helpers.formatCurrency(dayTransfer), AppColors.transfer),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              shrinkWrap: true,
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (context, index) => TransactionItem(
                transaction: transactions[index],
                onTap: () => onTransactionTap(transactions[index]),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16),
        ],
        ),
      ),
    ),
  );
}

class _DotLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _DotLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
