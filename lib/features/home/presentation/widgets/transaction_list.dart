import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/transaction.dart';
import '../../../../theme/app_theme.dart';
import 'summary_card.dart';
import 'transaction_item.dart';
import 'empty_state.dart';

class DailyTransactionsView extends StatelessWidget {
  final List<Transaction> transactions;
  final Map<DateTime, List<Transaction>> groupedByDate;
  final List<DateTime> sortedDates;
  final Future<void> Function() onRefresh;
  final void Function(Transaction) onTransactionTap;
  final void Function(Transaction)? onTransactionLongPress;

  const DailyTransactionsView({
    super.key,
    required this.transactions,
    required this.groupedByDate,
    required this.sortedDates,
    required this.onRefresh,
    required this.onTransactionTap,
    this.onTransactionLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const HomeEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayTransactions = List<Transaction>.from(groupedByDate[date] ?? [])
          ..sort((a, b) => b.date.compareTo(a.date));
        return _DateGroup(
          date: date,
          transactions: dayTransactions,
          onTransactionTap: onTransactionTap,
          onTransactionLongPress: onTransactionLongPress,
        );
      },
    );
  }
}

class _DateGroup extends StatelessWidget {
  final DateTime date;
  final List<Transaction> transactions;
  final void Function(Transaction) onTransactionTap;
  final void Function(Transaction)? onTransactionLongPress;

  const _DateGroup({
    required this.date,
    required this.transactions,
    required this.onTransactionTap,
    this.onTransactionLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final dayIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final dayExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final dayName = DateFormat('E').format(date);
    final dateStr = DateFormat('MM.yyyy').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Text(
                '${date.day} $dayName $dateStr',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayIncome > 0
                        ? 'Rs. ${SummaryCard.formatCurrency(dayIncome)}'
                        : 'Rs.00',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.income,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (dayExpense > 0)
                    Text(
                      'Rs. ${SummaryCard.formatCurrency(dayExpense)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.expense,
                      ),
                    ),
                  if (dayExpense == 0)
                    Text(
                      'Rs.00',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        ...transactions.map(
          (t) => TransactionItem(
            transaction: t,
            onTap: () => onTransactionTap(t),
            onLongPress: onTransactionLongPress != null
                ? () => onTransactionLongPress!(t)
                : null,
          ),
        ),
      ],
    );
  }
}
