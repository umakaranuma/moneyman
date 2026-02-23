import '../../../../models/transaction.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/sms_service.dart';
import 'stats_calculator.dart';

/// Fetches and merges transactions for stats (manual + SMS). No UI.
class StatsDataSource {
  static Future<List<Transaction>> getAllTransactions() async {
    final manual = StorageService.getAllTransactions();
    final sms = await _getSmsTransactionsAsTransactions();
    final unique = <String, Transaction>{};
    for (final t in manual) {
      unique[t.id] = t;
    }
    for (final t in sms) {
      if (!unique.containsKey(t.id)) unique[t.id] = t;
    }
    return unique.values.toList();
  }

  static Future<List<Transaction>> getFilteredTransactions(
    DateTime month,
  ) async {
    final all = await getAllTransactions();
    return all
        .where((t) => t.date.year == month.year && t.date.month == month.month)
        .toList();
  }

  static Future<Map<String, Map<String, double>>> getMonthlyData() async {
    final all = await getAllTransactions();
    return StatsCalculator.monthlyData(all);
  }

  static Future<List<Transaction>> _getSmsTransactionsAsTransactions() async {
    try {
      if (!await SmsService.hasSmsPermission()) return [];
      final smsList = await SmsService.fetchAndParseSmsMessages(
        fetchAll: false,
      );
      return smsList.map((smsT) {
        final isTransfer = _isSmsTransactionTransfer(smsT);
        String? fromAccount;
        String? toAccount;
        if (isTransfer) {
          if (smsT.isCredit) {
            toAccount = smsT.accountNumber ?? 'Bank Account';
            fromAccount = 'Cash';
          } else {
            fromAccount = smsT.accountNumber ?? 'Bank Account';
            final upper = smsT.rawMessage.toUpperCase();
            if (upper.contains('TO ACCOUNT') ||
                upper.contains('TRANSFERRED TO') ||
                upper.contains('NEFT') ||
                upper.contains('RTGS') ||
                upper.contains('IMPS') ||
                upper.contains('UPI')) {
              toAccount =
                  _extractRecipientAccount(smsT.rawMessage) ?? 'Other Account';
            } else {
              toAccount = 'Cash';
            }
          }
        }
        final upper = smsT.rawMessage.toUpperCase();
        final title = isTransfer
            ? (smsT.isCredit
                  ? '${smsT.bankName} Deposit'
                  : (upper.contains('TO ACCOUNT') ||
                            upper.contains('TRANSFERRED TO') ||
                            upper.contains('NEFT') ||
                            upper.contains('RTGS') ||
                            upper.contains('IMPS')
                        ? '${smsT.bankName} Transfer'
                        : '${smsT.bankName} Withdrawal'))
            : '${smsT.bankName} ${smsT.isCredit ? "Credit" : "Debit"}';
        final note =
            'From SMS: ${smsT.rawMessage.length > 50 ? '${smsT.rawMessage.substring(0, 50)}...' : smsT.rawMessage}';
        return Transaction(
          id: 'sms_${smsT.id}',
          title: title,
          amount: smsT.amount,
          type: isTransfer
              ? TransactionType.transfer
              : (smsT.isCredit
                    ? TransactionType.income
                    : TransactionType.expense),
          date: smsT.date,
          category: isTransfer
              ? 'Transfer'
              : (smsT.isCredit ? 'Bank Transfer' : 'Bank Transaction'),
          note: note,
          accountType: AccountType.bank,
          fromAccount: fromAccount,
          toAccount: toAccount,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static bool _isSmsTransactionTransfer(ParsedSmsTransaction smsT) {
    final upper = smsT.rawMessage.toUpperCase();
    if (smsT.isCredit) {
      const keywords = [
        'CASH DEPOSIT',
        'CASH DEPOSITED',
        'DEPOSIT CASH',
        'CASH DEPOSITED TO',
      ];
      return keywords.any((k) => upper.contains(k));
    }
    if (upper.contains('ATM') &&
        (upper.contains('WITHDRAWAL') || upper.contains('WITHDRAWN'))) {
      return true;
    }
    if (RegExp(
      r'ATM\s+WITHDRAW(?:AL|N)',
      caseSensitive: false,
    ).hasMatch(upper)) {
      return true;
    }
    if (upper.contains('CASH WITHDRAWAL') || upper.contains('CASH WITHDRAWN')) {
      return true;
    }
    if ((upper.contains('WITHDRAWAL') || upper.contains('WITHDRAWN')) &&
        (upper.contains('FROM ACCOUNT') ||
            upper.contains('FROM A/C') ||
            upper.contains('FROM AC') ||
            RegExp(
              r'FROM\s+[A/C\s]*NO',
              caseSensitive: false,
            ).hasMatch(upper) ||
            upper.contains('A/C NO') ||
            upper.contains('ACCOUNT NO') ||
            upper.contains('A/C:'))) {
      return true;
    }
    if ((upper.contains('NEFT') ||
            upper.contains('RTGS') ||
            upper.contains('IMPS') ||
            upper.contains('UPI')) &&
        (upper.contains('TO ACCOUNT') ||
            upper.contains('TO A/C') ||
            upper.contains('TO AC') ||
            RegExp(
              r'DEBITED\s+TO\s+(?:AC|ACCOUNT|A/C)',
              caseSensitive: false,
            ).hasMatch(upper) ||
            RegExp(
              r'TO\s+(?:AC|ACCOUNT|A/C)\s+NO',
              caseSensitive: false,
            ).hasMatch(upper))) {
      return true;
    }
    if (upper.contains('TRANSFER') &&
        (upper.contains('TO ACCOUNT') ||
            upper.contains('TO A/C') ||
            upper.contains('TO AC') ||
            upper.contains('FROM ACCOUNT') ||
            upper.contains('FROM A/C') ||
            upper.contains('FROM AC') ||
            RegExp(r'TO\s+[A/C\s]*NO', caseSensitive: false).hasMatch(upper) ||
            RegExp(
              r'FROM\s+[A/C\s]*NO',
              caseSensitive: false,
            ).hasMatch(upper))) {
      return true;
    }
    const expenseKeywords = [
      'PAYMENT',
      'PAID',
      'PURCHASE',
      'PURCHASED',
      'BILL',
      'MERCHANT',
      'POS',
      'DEBIT CARD',
      'CREDIT CARD',
      'ONLINE',
      'SHOPPING',
      'RESTAURANT',
      'FOOD',
      'GROCERY',
      'FUEL',
      'PETROL',
      'DIESEL',
      'TAXI',
      'UBER',
      'OLA',
      'RENT',
      'SALARY',
      'SERVICE',
      'CHARGE',
      'FEE',
      'TAX',
    ];
    if (expenseKeywords.any((k) => upper.contains(k))) return false;
    return false;
  }

  static String? _extractRecipientAccount(String message) {
    final upper = message.toUpperCase();
    final patterns = [
      RegExp(
        r'TO\s+(?:ACCOUNT|A/C|ACCT)[:\s]*[X*]*([0-9]{4,})',
        caseSensitive: false,
      ),
      RegExp(r'TRANSFERRED\s+TO[:\s]*[X*]*([0-9]{4,})', caseSensitive: false),
      RegExp(r'BEN(?:EFICIARY)?[:\s]*[X*]*([0-9]{4,})', caseSensitive: false),
      RegExp(r'TO\s+([A-Z0-9]+@[A-Z]+)', caseSensitive: false),
      RegExp(r'TO[:\s]+[A-Z\s]*([0-9]{4,})', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(upper);
      if (m != null && m.group(1) != null) {
        final acc = m.group(1)!;
        return acc.contains('@')
            ? acc
            : '****${acc.length > 4 ? acc.substring(acc.length - 4) : acc}';
      }
    }
    return null;
  }
}
