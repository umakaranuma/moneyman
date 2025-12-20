import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ParsedSmsTransaction {
  final String id;
  final String sender;
  final double amount;
  final bool isCredit; // true = credited, false = debited
  final DateTime date;
  final String rawMessage;
  final String? accountNumber;
  final String? balance;
  final String bankName;
  bool isImported;

  ParsedSmsTransaction({
    required this.id,
    required this.sender,
    required this.amount,
    required this.isCredit,
    required this.date,
    required this.rawMessage,
    this.accountNumber,
    this.balance,
    required this.bankName,
    this.isImported = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'amount': amount,
      'isCredit': isCredit,
      'date': date.toIso8601String(),
      'rawMessage': rawMessage,
      'accountNumber': accountNumber,
      'balance': balance,
      'bankName': bankName,
      'isImported': isImported,
    };
  }

  factory ParsedSmsTransaction.fromJson(Map<String, dynamic> json) {
    return ParsedSmsTransaction(
      id: json['id'],
      sender: json['sender'],
      amount: json['amount'].toDouble(),
      isCredit: json['isCredit'],
      date: DateTime.parse(json['date']),
      rawMessage: json['rawMessage'],
      accountNumber: json['accountNumber'],
      balance: json['balance'],
      bankName: json['bankName'],
      isImported: json['isImported'] ?? false,
    );
  }
}

class SmsService {
  static const String _smsBoxName = 'sms_transactions';
  static const String _installDateKey = 'app_install_date';
  static const String _settingsBoxName = 'app_settings';
  
  static final SmsQuery _query = SmsQuery();

  // Bank sender patterns - add more as needed
  static const List<String> _bankSenders = [
    'BOC', // Bank of Ceylon
    'HNB', // Hatton National Bank
    'COMBANK', // Commercial Bank
    'SAMPATH', // Sampath Bank
    'SEYLAN', // Seylan Bank
    'NDB', // NDB Bank
    'DFCC',
    'PEOPLES', // People's Bank
    'NSB', // National Savings Bank
    'HDFC',
    'ICICI',
    'SBI',
    'AXIS',
    'PAYTM',
    'GPAY',
    'PHONEPE',
  ];

  static Future<void> init() async {
    await Hive.openBox(_smsBoxName);
    await Hive.openBox(_settingsBoxName);
    
    // Store install date if not already stored
    final settingsBox = Hive.box(_settingsBoxName);
    if (settingsBox.get(_installDateKey) == null) {
      await settingsBox.put(_installDateKey, DateTime.now().toIso8601String());
    }
  }

  static DateTime getInstallDate() {
    final settingsBox = Hive.box(_settingsBoxName);
    final dateStr = settingsBox.get(_installDateKey);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return DateTime.now();
  }

  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.status;
    if (status.isGranted) {
      return true;
    }
    
    final result = await Permission.sms.request();
    return result.isGranted;
  }

  static Future<bool> hasSmsPermission() async {
    return await Permission.sms.isGranted;
  }

  static Future<List<ParsedSmsTransaction>> fetchAndParseSmsMessages({bool fetchAll = false}) async {
    final hasPermission = await requestSmsPermission();
    if (!hasPermission) {
      return [];
    }

    final installDate = getInstallDate();
    
    // Fetch all inbox messages
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
    );

    final List<ParsedSmsTransaction> transactions = [];

    for (final message in messages) {
      // Filter by date - only get messages from install month onwards (unless fetchAll is true)
      if (!fetchAll && message.date != null && message.date!.isBefore(
        DateTime(installDate.year, installDate.month, 1)
      )) {
        continue;
      }

      // Check if sender is a bank
      final sender = message.sender?.toUpperCase() ?? '';
      final isBankMessage = _bankSenders.any(
        (bank) => sender.contains(bank) || 
                  (message.body?.toUpperCase().contains(bank) ?? false)
      );

      if (!isBankMessage) continue;

      // Try to parse the message
      final parsed = _parseTransactionMessage(
        id: '${message.id}',
        sender: message.sender ?? 'Unknown',
        body: message.body ?? '',
        date: message.date ?? DateTime.now(),
      );

      if (parsed != null) {
        transactions.add(parsed);
      }
    }

    // Sort by date, newest first
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  static ParsedSmsTransaction? _parseTransactionMessage({
    required String id,
    required String sender,
    required String body,
    required DateTime date,
  }) {
    final upperBody = body.toUpperCase();
    
    // Determine if credit or debit
    final isCredit = _isCredit(upperBody);
    final isDebit = _isDebit(upperBody);
    
    if (!isCredit && !isDebit) return null;

    // Extract amount
    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    // Extract account number
    final accountNumber = _extractAccountNumber(body);
    
    // Extract balance
    final balance = _extractBalance(body);
    
    // Determine bank name
    final bankName = _determineBankName(sender, body);

    return ParsedSmsTransaction(
      id: id,
      sender: sender,
      amount: amount,
      isCredit: isCredit,
      date: date,
      rawMessage: body,
      accountNumber: accountNumber,
      balance: balance,
      bankName: bankName,
    );
  }

  static bool _isCredit(String body) {
    final creditKeywords = [
      'CREDITED',
      'CREDIT',
      'RECEIVED',
      'DEPOSITED',
      'ADDED',
      'CR',
      'REFUND',
      'CASHBACK',
      'REVERSED',
    ];
    return creditKeywords.any((keyword) => body.contains(keyword));
  }

  static bool _isDebit(String body) {
    final debitKeywords = [
      'DEBITED',
      'DEBIT',
      'WITHDRAWN',
      'PURCHASE',
      'PAID',
      'PAYMENT',
      'TRANSFERRED',
      'DR',
      'SPENT',
      'DEDUCTED',
    ];
    return debitKeywords.any((keyword) => body.contains(keyword));
  }

  static double? _extractAmount(String body) {
    // Common patterns for amounts in bank messages
    // Rs.1,234.56 or Rs 1234.56 or LKR 1,234.56 or INR 1234 or $1234.56
    final patterns = [
      RegExp(r'(?:RS\.?|LKR|INR|USD|\$)\s*([0-9,]+\.?[0-9]*)', caseSensitive: false),
      RegExp(r'(?:AMOUNT|AMT)[:\s]*(?:RS\.?|LKR|INR|USD|\$)?\s*([0-9,]+\.?[0-9]*)', caseSensitive: false),
      RegExp(r'([0-9,]+\.?[0-9]*)\s*(?:RS\.?|LKR|INR)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.group(1) != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }
    return null;
  }

  static String? _extractAccountNumber(String body) {
    // Pattern for account numbers (usually last 4-6 digits shown)
    final patterns = [
      RegExp(r'A/C[:\s]*[X*]*([0-9]{4,})', caseSensitive: false),
      RegExp(r'ACCOUNT[:\s]*[X*]*([0-9]{4,})', caseSensitive: false),
      RegExp(r'ACCT[:\s]*[X*]*([0-9]{4,})', caseSensitive: false),
      RegExp(r'[X*]{2,}([0-9]{4,6})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return '****${match.group(1)}';
      }
    }
    return null;
  }

  static String? _extractBalance(String body) {
    final patterns = [
      RegExp(r'(?:BAL|BALANCE|AVAIL|AVL)[:\s]*(?:RS\.?|LKR|INR|USD|\$)?\s*([0-9,]+\.?[0-9]*)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
    }
    return null;
  }

  static String _determineBankName(String sender, String body) {
    final combined = '$sender $body'.toUpperCase();
    
    if (combined.contains('BOC') || combined.contains('BANK OF CEYLON')) {
      return 'Bank of Ceylon';
    } else if (combined.contains('HNB') || combined.contains('HATTON')) {
      return 'HNB';
    } else if (combined.contains('COMBANK') || combined.contains('COMMERCIAL')) {
      return 'Commercial Bank';
    } else if (combined.contains('SAMPATH')) {
      return 'Sampath Bank';
    } else if (combined.contains('SEYLAN')) {
      return 'Seylan Bank';
    } else if (combined.contains('NDB')) {
      return 'NDB Bank';
    } else if (combined.contains('DFCC')) {
      return 'DFCC Bank';
    } else if (combined.contains('PEOPLES') || combined.contains("PEOPLE'S")) {
      return "People's Bank";
    } else if (combined.contains('NSB') || combined.contains('NATIONAL SAVINGS')) {
      return 'NSB';
    } else if (combined.contains('HDFC')) {
      return 'HDFC';
    } else if (combined.contains('ICICI')) {
      return 'ICICI';
    } else if (combined.contains('SBI')) {
      return 'SBI';
    } else if (combined.contains('AXIS')) {
      return 'Axis Bank';
    } else if (combined.contains('PAYTM')) {
      return 'Paytm';
    } else if (combined.contains('GPAY') || combined.contains('GOOGLE PAY')) {
      return 'Google Pay';
    } else if (combined.contains('PHONEPE')) {
      return 'PhonePe';
    }
    
    return sender;
  }

  // Storage methods
  static Box get _smsBox => Hive.box(_smsBoxName);

  static Future<void> markAsImported(String id) async {
    await _smsBox.put(id, true);
  }

  static bool isAlreadyImported(String id) {
    return _smsBox.get(id, defaultValue: false);
  }

  static Future<void> clearImportedStatus() async {
    await _smsBox.clear();
  }
}

