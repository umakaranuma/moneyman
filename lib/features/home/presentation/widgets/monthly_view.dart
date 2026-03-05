import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/transaction.dart';
import '../../../../theme/app_theme.dart';
import 'summary_card.dart';

class MonthlyView extends StatelessWidget {
  final DateTime selectedMonth;
  final List<Transaction> transactions;
  final void Function(DateTime weekDate) onWeekSelected;

  const MonthlyView({
    super.key,
    required this.selectedMonth,
    required this.transactions,
    required this.onWeekSelected,
  });

  List<_MonthData> _getYearlyData() {
    final months = <_MonthData>[];
    final now = DateTime.now();

    for (int month = 12; month >= 1; month--) {
      if (selectedMonth.year == now.year && month > now.month) continue;
      if (selectedMonth.year > now.year) continue;

      final monthTransactions = transactions
          .where(
            (t) => t.date.year == selectedMonth.year && t.date.month == month,
          )
          .toList();

      final income = monthTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);
      final expense = monthTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);

      final monthName =
          DateFormat('MMM').format(DateTime(selectedMonth.year, month));

      months.add(
        _MonthData(
          year: selectedMonth.year,
          month: month,
          monthName: monthName,
          income: income,
          expense: expense,
          total: income - expense,
          transactions: monthTransactions,
        ),
      );
    }
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final yearly = _getYearlyData();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        ...yearly.map(
          (data) => _MonthRow(
            data: data,
            onWeekSelected: onWeekSelected,
          ),
        ),
      ],
    );
  }
}

class _MonthData {
  final int year;
  final int month;
  final String monthName;
  final double income;
  final double expense;
  final double total;
  final List<Transaction> transactions;

  _MonthData({
    required this.year,
    required this.month,
    required this.monthName,
    required this.income,
    required this.expense,
    required this.total,
    required this.transactions,
  });
}

class _MonthRow extends StatelessWidget {
  final _MonthData data;
  final void Function(DateTime weekDate) onWeekSelected;

  const _MonthRow({
    required this.data,
    required this.onWeekSelected,
  });

  List<_WeekData> _getWeeklyData() {
    if (data.transactions.isEmpty) return [];

    final weeks = <int, _WeekData>{};

    for (final t in data.transactions) {
      final weekIndex = ((t.date.day - 1) ~/ 7) + 1; // 1..5
      final existingWeek = weeks[weekIndex];

      final isIncome = t.type == TransactionType.income;
      final isExpense = t.type == TransactionType.expense;

      final weekStartDay = ((weekIndex - 1) * 7) + 1;
      final weekDate = DateTime(data.year, data.month, weekStartDay);

      if (existingWeek == null) {
        weeks[weekIndex] = _WeekData(
          label: 'Week $weekIndex',
          weekDate: weekDate,
          income: isIncome ? t.amount : 0.0,
          expense: isExpense ? t.amount : 0.0,
        );
      } else {
        weeks[weekIndex] = existingWeek.copyWith(
          income: existingWeek.income + (isIncome ? t.amount : 0.0),
          expense: existingWeek.expense + (isExpense ? t.amount : 0.0),
        );
      }
    }

    final list = weeks.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return list.map((e) => e.value).toList();
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _getWeeklyData();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          collapsedIconColor: AppColors.textMuted,
          iconColor: AppColors.textMuted,
          title: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  data.monthName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Rs. ${SummaryCard.formatCurrency(data.income)}',
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
                      'Rs. ${SummaryCard.formatCurrency(data.expense)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.expense,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Rs. ${SummaryCard.formatCurrency(data.total)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: data.total >= 0
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          children: weeks.isEmpty
              ? [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No transactions for this month',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ]
              : weeks
                  .map(
                    (week) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onWeekSelected(week.weekDate),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                week.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Rs. ${SummaryCard.formatCurrency(week.income)}',
                                style: const TextStyle(
                                  fontSize: 12,
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
                                    'Rs. ${SummaryCard.formatCurrency(week.expense)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.expense,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${SummaryCard.formatCurrency(week.total)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: week.total >= 0
                                          ? AppColors.textSecondary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

class _WeekData {
  final String label;
  final DateTime weekDate;
  final double income;
  final double expense;

  double get total => income - expense;

  const _WeekData({
    required this.label,
    required this.weekDate,
    required this.income,
    required this.expense,
  });

  _WeekData copyWith({
    String? label,
    DateTime? weekDate,
    double? income,
    double? expense,
  }) {
    return _WeekData(
      label: label ?? this.label,
      weekDate: weekDate ?? this.weekDate,
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }
}
