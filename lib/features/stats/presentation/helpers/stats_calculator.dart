import 'package:intl/intl.dart';
import '../../../../models/transaction.dart';

/// Pure calculation logic for stats. No UI, no I/O.
class StatsCalculator {
  /// Returns total income and expense from [transactions].
  static Map<String, double> calculateIncomeExpense(List<Transaction> transactions) {
    double income = 0;
    double expense = 0;
    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else if (t.type == TransactionType.expense) {
        expense += t.amount;
      }
    }
    return {'income': income, 'expense': expense};
  }

  /// Returns category name -> total amount for expenses (or income if [isIncome]).
  static Map<String, double> categoryBreakdown(
    List<Transaction> transactions, {
    required bool isIncome,
  }) {
    final map = <String, double>{};
    for (final t in transactions) {
      if (t.category == null) continue;
      if (isIncome && t.type == TransactionType.income) {
        map[t.category!] = (map[t.category!] ?? 0) + t.amount;
      } else if (!isIncome && t.type == TransactionType.expense) {
        map[t.category!] = (map[t.category!] ?? 0) + t.amount;
      }
    }
    return map;
  }

  /// Last 6 months: month key -> { income, expense, balance }.
  /// [allTransactions] should be all transactions (not filtered by month).
  static Map<String, Map<String, double>> monthlyData(List<Transaction> allTransactions) {
    final now = DateTime.now();
    final result = <String, Map<String, double>>{};
    double cumulativeBalance = 0;

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM yyyy').format(monthDate);

      final monthTransactions = allTransactions.where((t) {
        return t.date.year == monthDate.year && t.date.month == monthDate.month;
      }).toList();

      double income = 0;
      double expense = 0;
      for (final t in monthTransactions) {
        if (t.type == TransactionType.income) {
          income += t.amount;
          cumulativeBalance += t.amount;
        } else if (t.type == TransactionType.expense) {
          expense += t.amount;
          cumulativeBalance -= t.amount;
        }
      }

      result[monthKey] = {
        'income': income,
        'expense': expense,
        'balance': cumulativeBalance,
      };
    }
    return result;
  }

  static String formatCurrency(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }
}
