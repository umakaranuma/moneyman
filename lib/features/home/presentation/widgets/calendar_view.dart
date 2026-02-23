// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/transaction.dart';
import '../../../../theme/app_theme.dart';
import '../bottom_sheets/day_transactions_sheet.dart';

class CalendarView extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime selectedDay;
  final List<Transaction> transactions;
  final void Function(Transaction) onTransactionTap;
  final void Function(DateTime) onDaySelected;

  const CalendarView({
    super.key,
    required this.selectedMonth,
    required this.selectedDay,
    required this.transactions,
    required this.onTransactionTap,
    required this.onDaySelected,
  });

  Map<DateTime, List<Transaction>> _getTransactionsByDate() {
    final map = <DateTime, List<Transaction>>{};
    for (var t in transactions) {
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(date, () => []).add(t);
    }
    return map;
  }

  Map<String, double> _getDayTotals(DateTime day) {
    final byDate = _getTransactionsByDate();
    final date = DateTime(day.year, day.month, day.day);
    final list = byDate[date] ?? [];
    double income = 0, expense = 0, transfer = 0;
    for (var t in list) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else if (t.type == TransactionType.expense)
        expense += t.amount;
      else
        transfer += t.amount;
    }
    return {'income': income, 'expense': expense, 'transfer': transfer};
  }

  List<Transaction> _getTransactionsForDay(DateTime day) {
    final byDate = _getTransactionsByDate();
    final date = DateTime(day.year, day.month, day.day);
    return byDate[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7;
    const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: weekDays.map((day) {
              final isWeekend = day == 'Sun' || day == 'Sat';
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      color: isWeekend
                          ? AppColors.secondary
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.75,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - firstWeekday;
              final isCurrentMonth = dayOffset >= 0 && dayOffset < daysInMonth;
              late DateTime cellDate;
              if (dayOffset < 0) {
                final prev = DateTime(
                  selectedMonth.year,
                  selectedMonth.month,
                  0,
                );
                cellDate = DateTime(
                  prev.year,
                  prev.month,
                  prev.day + dayOffset + 1,
                );
              } else if (dayOffset >= daysInMonth) {
                cellDate = DateTime(
                  selectedMonth.year,
                  selectedMonth.month + 1,
                  dayOffset - daysInMonth + 1,
                );
              } else {
                cellDate = DateTime(
                  selectedMonth.year,
                  selectedMonth.month,
                  dayOffset + 1,
                );
              }
              final totals = _getDayTotals(cellDate);
              final dayTransactions = _getTransactionsForDay(cellDate);
              final isToday = _isToday(cellDate);
              final isSelected = _isSameDay(cellDate, selectedDay);

              return _CalendarDayCell(
                day: cellDate.day,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isSelected: isSelected,
                income: totals['income']!,
                expense: totals['expense']!,
                transfer: totals['transfer']!,
                hasTransactions: dayTransactions.isNotEmpty,
                onTap: () {
                  if (dayTransactions.isNotEmpty) {
                    showDayTransactionsSheet(
                      context,
                      date: cellDate,
                      transactions: dayTransactions,
                      onTransactionTap: onTransactionTap,
                    );
                  } else {
                    onDaySelected(cellDate);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int day;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final double income;
  final double expense;
  final double transfer;
  final bool hasTransactions;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.income,
    required this.expense,
    required this.transfer,
    required this.hasTransactions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isToday
                ? AppColors.primary.withOpacity(0.4)
                : hasTransactions
                ? AppColors.surfaceVariant.withOpacity(0.5)
                : AppColors.surfaceVariant.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday || isSelected
                    ? FontWeight.w700
                    : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : !isCurrentMonth
                    ? AppColors.textMuted.withOpacity(0.3)
                    : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (isCurrentMonth && hasTransactions) ...[
              if (income > 0)
                Text(
                  formatter.format(income),
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white.withOpacity(0.95)
                        : AppColors.income,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (expense > 0)
                Text(
                  formatter.format(expense),
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : AppColors.expense,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (transfer > 0)
                Text(
                  formatter.format(transfer),
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white.withOpacity(0.85)
                        : AppColors.transfer,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
