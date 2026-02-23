import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/transaction.dart';
import '../../../../theme/app_theme.dart';
import 'summary_card.dart';

class MonthlyView extends StatelessWidget {
  final DateTime selectedMonth;
  final List<Transaction> transactions;

  const MonthlyView({
    super.key,
    required this.selectedMonth,
    required this.transactions,
  });

  Map<String, Map<String, double>> _getYearlyData() {
    final months = <String, Map<String, double>>{};
    final now = DateTime.now();
    for (int month = 12; month >= 1; month--) {
      if (selectedMonth.year == now.year && month > now.month) continue;
      if (selectedMonth.year > now.year) continue;
      final list = transactions
          .where((t) => t.date.year == selectedMonth.year && t.date.month == month)
          .toList();
      final income = list.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
      final expense = list.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
      final monthName = DateFormat('MMM').format(DateTime(selectedMonth.year, month));
      months[monthName] = {'income': income, 'expense': expense, 'total': income - expense};
    }
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final yearly = _getYearlyData();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        ...yearly.entries.map(
          (e) => _MonthRow(
            monthName: e.key,
            income: e.value['income']!,
            expense: e.value['expense']!,
            total: e.value['total']!,
          ),
        ),
      ],
    );
  }
}

class _MonthRow extends StatelessWidget {
  final String monthName;
  final double income;
  final double expense;
  final double total;

  const _MonthRow({
    required this.monthName,
    required this.income,
    required this.expense,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              monthName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Rs. ${SummaryCard.formatCurrency(income)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.income,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. ${SummaryCard.formatCurrency(expense)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.expense,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Rs. ${SummaryCard.formatCurrency(total)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: total >= 0 ? AppColors.textSecondary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
