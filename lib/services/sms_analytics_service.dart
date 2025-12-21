import 'package:intl/intl.dart';
import 'sms_service.dart';

enum TimePeriod { daily, weekly, monthly, custom }

class SmsAnalyticsService {
  /// Get summary statistics (total credits, debits, net balance)
  static Map<String, dynamic> getSummaryStats(
    List<ParsedSmsTransaction> transactions,
  ) {
    double totalCredits = 0.0;
    double totalDebits = 0.0;

    for (var transaction in transactions) {
      if (transaction.isCredit) {
        totalCredits += transaction.amount;
      } else {
        totalDebits += transaction.amount;
      }
    }

    return {
      'totalCredits': totalCredits,
      'totalDebits': totalDebits,
      'netBalance': totalCredits - totalDebits,
      'transactionCount': transactions.length,
    };
  }

  /// Get bank-wise breakdown
  static Map<String, Map<String, double>> getBankBreakdown(
    List<ParsedSmsTransaction> transactions,
  ) {
    final Map<String, Map<String, double>> bankData = {};

    for (var transaction in transactions) {
      final bankName = transaction.bankName;
      if (!bankData.containsKey(bankName)) {
        bankData[bankName] = {'credits': 0.0, 'debits': 0.0, 'count': 0.0};
      }

      if (transaction.isCredit) {
        bankData[bankName]!['credits'] =
            bankData[bankName]!['credits']! + transaction.amount;
      } else {
        bankData[bankName]!['debits'] =
            bankData[bankName]!['debits']! + transaction.amount;
      }
      bankData[bankName]!['count'] = bankData[bankName]!['count']! + 1;
    }

    return bankData;
  }

  /// Get credit vs debit trends by time period
  static List<Map<String, dynamic>> getCreditDebitTrends(
    List<ParsedSmsTransaction> transactions,
    TimePeriod period,
  ) {
    final Map<String, Map<String, double>> grouped = {};

    for (var transaction in transactions) {
      final periodKey = _getPeriodKey(transaction.date, period);
      if (!grouped.containsKey(periodKey)) {
        grouped[periodKey] = {'credits': 0.0, 'debits': 0.0};
      }

      if (transaction.isCredit) {
        grouped[periodKey]!['credits'] =
            grouped[periodKey]!['credits']! + transaction.amount;
      } else {
        grouped[periodKey]!['debits'] =
            grouped[periodKey]!['debits']! + transaction.amount;
      }
    }

    final List<Map<String, dynamic>> trends = [];
    final sortedKeys = grouped.keys.toList()..sort();

    for (var key in sortedKeys) {
      trends.add({
        'period': key,
        'date': _parsePeriodKey(key, period),
        'credits': grouped[key]!['credits']!,
        'debits': grouped[key]!['debits']!,
      });
    }

    return trends;
  }

  /// Get balance over time from SMS balance data
  static List<Map<String, dynamic>> getBalanceOverTime(
    List<ParsedSmsTransaction> transactions,
    TimePeriod period,
  ) {
    // Filter transactions with balance data
    final transactionsWithBalance = transactions
        .where((t) => t.balance != null && t.balance!.isNotEmpty)
        .toList();

    if (transactionsWithBalance.isEmpty) {
      return [];
    }

    // Sort by date
    transactionsWithBalance.sort((a, b) => a.date.compareTo(b.date));

    final List<Map<String, dynamic>> balanceData = [];

    for (var transaction in transactionsWithBalance) {
      final balanceStr = transaction.balance!.replaceAll(',', '');
      final balance = double.tryParse(balanceStr);

      if (balance != null) {
        balanceData.add({
          'date': transaction.date,
          'balance': balance,
          'period': _getPeriodKey(transaction.date, period),
        });
      }
    }

    // Group by period and take the latest balance for each period
    final Map<String, Map<String, dynamic>> grouped = {};
    for (var data in balanceData) {
      final periodKey = data['period'] as String;
      final date = data['date'] as DateTime;
      final balance = data['balance'] as double;

      if (!grouped.containsKey(periodKey) ||
          date.isAfter(grouped[periodKey]!['date'] as DateTime)) {
        grouped[periodKey] = {
          'date': date,
          'balance': balance,
          'period': periodKey,
        };
      }
    }

    final List<Map<String, dynamic>> result = [];
    final sortedKeys = grouped.keys.toList()..sort();

    for (var key in sortedKeys) {
      result.add(grouped[key]!);
    }

    return result;
  }

  /// Get transaction volume by time period
  static List<Map<String, dynamic>> getTransactionVolume(
    List<ParsedSmsTransaction> transactions,
    TimePeriod period,
  ) {
    final Map<String, Map<String, int>> grouped = {};

    for (var transaction in transactions) {
      final periodKey = _getPeriodKey(transaction.date, period);
      if (!grouped.containsKey(periodKey)) {
        grouped[periodKey] = {'credits': 0, 'debits': 0};
      }

      if (transaction.isCredit) {
        grouped[periodKey]!['credits'] = grouped[periodKey]!['credits']! + 1;
      } else {
        grouped[periodKey]!['debits'] = grouped[periodKey]!['debits']! + 1;
      }
    }

    final List<Map<String, dynamic>> volume = [];
    final sortedKeys = grouped.keys.toList()..sort();

    for (var key in sortedKeys) {
      volume.add({
        'period': key,
        'date': _parsePeriodKey(key, period),
        'credits': grouped[key]!['credits']!,
        'debits': grouped[key]!['debits']!,
        'total': grouped[key]!['credits']! + grouped[key]!['debits']!,
      });
    }

    return volume;
  }

  /// Filter transactions by date range
  static List<ParsedSmsTransaction> filterByDateRange(
    List<ParsedSmsTransaction> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    return transactions.where((t) {
      return t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get period key for grouping
  static String _getPeriodKey(DateTime date, TimePeriod period) {
    switch (period) {
      case TimePeriod.daily:
        return DateFormat('yyyy-MM-dd').format(date);
      case TimePeriod.weekly:
        // Get week number and year
        final weekNumber = _getWeekNumber(date);
        return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
      case TimePeriod.monthly:
        return DateFormat('yyyy-MM').format(date);
      case TimePeriod.custom:
        return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  /// Parse period key back to DateTime
  static DateTime _parsePeriodKey(String key, TimePeriod period) {
    switch (period) {
      case TimePeriod.daily:
        return DateFormat('yyyy-MM-dd').parse(key);
      case TimePeriod.weekly:
        final parts = key.split('-W');
        final year = int.parse(parts[0]);
        final week = int.parse(parts[1]);
        return _getDateFromWeekNumber(year, week);
      case TimePeriod.monthly:
        return DateFormat('yyyy-MM').parse('$key-01');
      case TimePeriod.custom:
        return DateFormat('yyyy-MM-dd').parse(key);
    }
  }

  /// Get week number from date
  static int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }

  /// Get date from week number
  static DateTime _getDateFromWeekNumber(int year, int week) {
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysToAdd = (week - 1) * 7 - firstDayOfYear.weekday + 1;
    return firstDayOfYear.add(Duration(days: daysToAdd));
  }
}
