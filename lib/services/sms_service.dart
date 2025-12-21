import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';

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

  // MethodChannel for SMS User Consent API
  static const MethodChannel _channel = MethodChannel(
    'com.fynux.finzo/sms_consent',
  );

  /// Request SMS using User Consent API (Play Store approved method)
  /// Shows Android system dialog, user selects SMS, we get the message
  /// This is the user-friendly method - no copy-paste needed!
  static Future<String?> requestSmsConsent() async {
    try {
      final String? smsText = await _channel
          .invokeMethod<String>('requestSmsConsent')
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              return null;
            },
          );
      return smsText;
    } on PlatformException catch (e) {
      // Handle specific error codes
      if (e.code == 'TIMEOUT') {
      } else if (e.code == 'SMS_CONSENT_ERROR') {
      } else if (e.code == 'GOOGLE_PLAY_SERVICES_UNAVAILABLE') {}
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Import SMS transaction using User Consent API
  /// User taps button → Android shows SMS picker → User selects SMS → We parse and import
  static Future<ParsedSmsTransaction?> importSmsTransaction() async {
    try {
      // Request SMS via User Consent API (shows Android system dialog)
      final smsText = await requestSmsConsent();

      if (smsText == null || smsText.isEmpty) {
        // User cancelled or no SMS selected
        return null;
      }

      // Parse the SMS message
      final parsed = parseSmsText(smsText);

      if (parsed != null) {
        // Mark as imported
        await markAsImported(parsed.id);
      }

      return parsed;
    } catch (e) {
      return null;
    }
  }

  /// Parse SMS text (used by both manual paste and User Consent API)
  static ParsedSmsTransaction? parseSmsText(
    String smsText, {
    String? sender,
    String? bankName,
  }) {
    try {
      // Parse the SMS message
      final parsed = _parseTransactionMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: sender ?? _extractSenderFromMessage(smsText),
        body: smsText,
        date: DateTime.now(),
        bankName: bankName, // Use provided bank name if available
      );

      return parsed;
    } catch (e) {
      return null;
    }
  }

  /// Extract sender from SMS message text
  static String _extractSenderFromMessage(String message) {
    // Try to find bank name in message
    final upperMessage = message.toUpperCase();
    for (final bank in _bankSenders) {
      if (upperMessage.contains(bank)) {
        return bank;
      }
    }
    return 'Unknown';
  }

  /// Parse transaction message
  static ParsedSmsTransaction? _parseTransactionMessage({
    required String id,
    required String sender,
    required String body,
    required DateTime date,
    String? bankName,
  }) {
    final upperBody = body.toUpperCase();

    // Determine if credit or debit
    final isCredit = _isCredit(upperBody);
    final isDebit = _isDebit(upperBody);

    // Special handling: If message contains "FROM A/C" or "FROM ACCOUNT", it's likely a debit
    // Also "POS/ATM Transaction" indicates a debit
    final isLikelyDebit =
        upperBody.contains('FROM A/C') ||
        upperBody.contains('FROM ACCOUNT') ||
        upperBody.contains('POS/ATM') ||
        upperBody.contains('ATM TRANSACTION') ||
        upperBody.contains('POS TRANSACTION');

    if (!isCredit && !isDebit && !isLikelyDebit) {
      print('No transaction type detected in: $body');
      return null;
    }

    // Extract amount
    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) {
      print('Could not extract amount from: $body');
      return null;
    }

    // If it's a likely debit but not explicitly marked, treat as debit
    // If it's explicitly credit, it's credit; otherwise if it's debit or likely debit, it's debit
    final finalIsCredit = isCredit && !isLikelyDebit;

    // Extract account number
    final accountNumber = _extractAccountNumber(body);

    // Extract balance
    final balance = _extractBalance(body);

    // Determine bank name (use provided bankName if available, otherwise detect)
    final finalBankName = bankName ?? _determineBankName(sender, body);

    return ParsedSmsTransaction(
      id: id,
      sender: sender,
      amount: amount,
      isCredit: finalIsCredit,
      date: date,
      rawMessage: body,
      accountNumber: accountNumber,
      balance: balance,
      bankName: finalBankName,
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
      'WITHDRAWAL',
      'PURCHASED',
      'CHARGED',
      'DEDUCT',
      'TRANSACTION', // POS/ATM Transaction
      'POS', // Point of Sale
      'ATM', // ATM withdrawal
      'WITHDRAW', // ATM withdraw
      'CASH', // Cash withdrawal
    ];
    return debitKeywords.any((keyword) => body.contains(keyword));
  }

  static double? _extractAmount(String body) {
    // Common patterns for amounts in bank messages
    final patterns = [
      // Pattern: LKR 5,025.00 or LKR 5025.00 or LKR5,025.00
      RegExp(
        r'(?:RS\.?|LKR|INR|USD|\$)\s*([0-9,]+\.?[0-9]*)',
        caseSensitive: false,
      ),
      // Pattern: AMOUNT: LKR 5,025.00
      RegExp(
        r'(?:AMOUNT|AMT)[:\s]*(?:RS\.?|LKR|INR|USD|\$)?\s*([0-9,]+\.?[0-9]*)',
        caseSensitive: false,
      ),
      // Pattern: 5,025.00 LKR or 5025.00 LKR
      RegExp(r'([0-9,]+\.?[0-9]*)\s*(?:RS\.?|LKR|INR)', caseSensitive: false),
      // Pattern: Rs 450.00 (with space after currency) - more specific
      RegExp(r'(?:RS\.?|LKR|INR)\s+([0-9,]+\.?[0-9]*)', caseSensitive: false),
      // Pattern: Just numbers with commas and decimals (e.g., 5,025.00 or 5025.00)
      // This is more flexible and will catch amounts even without currency symbols
      // But prioritize larger numbers that look like amounts (not dates or small numbers)
      RegExp(r'\b([0-9]{2,}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?)\b'),
      // Pattern: Simple decimal number (e.g., 450.00 or 5025.00) - but avoid dates
      RegExp(r'\b([0-9]{2,}(?:\.[0-9]{1,2})?)\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.group(1) != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          // Filter out very small numbers that might be dates or other numbers
          // Also filter out very large numbers that are likely account numbers
          if (amount >= 0.01 && amount <= 999999999) {
            return amount;
          }
        }
      }
    }
    return null;
  }

  static String? _extractAccountNumber(String body) {
    final patterns = [
      // Pattern for "Ac No:11702XXXXX71" - most specific, captures full pattern with X's
      RegExp(r'AC\s+NO[:\s]*([0-9X*]+)', caseSensitive: false),
      RegExp(r'A/C[:\s]*([0-9X*]+)', caseSensitive: false),
      RegExp(r'ACCOUNT[:\s]*([0-9X*]+)', caseSensitive: false),
      RegExp(r'ACCT[:\s]*([0-9X*]+)', caseSensitive: false),
      // Fallback patterns for digits only
      RegExp(r'A/C[:\s]*[X*]*([0-9]{4,})', caseSensitive: false),
      RegExp(r'ACCOUNT[:\s]*[X*]*([0-9]{4,})', caseSensitive: false),
      RegExp(r'ACCT[:\s]*[X*]*([0-9]{4,})', caseSensitive: false),
      RegExp(r'[X*]{2,}([0-9]{4,6})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.group(1) != null) {
        final accountPart = match.group(1)!;
        // Extract last 4-6 digits if available
        final digitsOnly = accountPart.replaceAll(RegExp(r'[^0-9]'), '');
        if (digitsOnly.length >= 4) {
          return '****${digitsOnly.substring(digitsOnly.length - 4)}';
        }
        return '****$accountPart';
      }
    }
    return null;
  }

  static String? _extractBalance(String body) {
    final patterns = [
      RegExp(
        r'(?:BAL|BALANCE|AVAIL|AVL)[:\s]*(?:RS\.?|LKR|INR|USD|\$)?\s*([0-9,]+\.?[0-9]*)',
        caseSensitive: false,
      ),
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

    // Only detect from explicit message content - no account number pattern detection
    if (combined.contains('BOC') || combined.contains('BANK OF CEYLON')) {
      return 'Bank of Ceylon';
    } else if (combined.contains('HNB') || combined.contains('HATTON')) {
      return 'HNB';
    } else if (combined.contains('COMBANK') ||
        combined.contains('COMMERCIAL')) {
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
    } else if (combined.contains('NSB') ||
        combined.contains('NATIONAL SAVINGS')) {
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

    // If bank name is not explicitly in message, return "Unknown Bank"
    // This will trigger user selection dialog
    return 'Unknown Bank';
  }

  /// Get list of available banks for selection
  static List<String> getAvailableBanks() {
    return [
      'Bank of Ceylon',
      'HNB',
      'Commercial Bank',
      'Sampath Bank',
      'Seylan Bank',
      'NDB Bank',
      'DFCC Bank',
      "People's Bank",
      'NSB',
      'HDFC',
      'ICICI',
      'SBI',
      'Axis Bank',
      'Paytm',
      'Google Pay',
      'PhonePe',
      'Other',
    ];
  }

  // Storage methods
  static Box get _smsBox => Hive.box(_smsBoxName);
  static const String _smsTransactionsListKey = 'sms_transactions_list';

  static Future<void> markAsImported(String id) async {
    await _smsBox.put(id, true);
  }

  static bool isAlreadyImported(String id) {
    return _smsBox.get(id, defaultValue: false);
  }

  static Future<void> clearImportedStatus() async {
    await _smsBox.clear();
  }

  /// Save a parsed SMS transaction to persistent storage
  static Future<void> saveSmsTransaction(
    ParsedSmsTransaction transaction,
  ) async {
    final transactions = getAllSmsTransactions();

    // Check if transaction already exists
    final existingIndex = transactions.indexWhere(
      (t) => t.id == transaction.id,
    );

    if (existingIndex >= 0) {
      // Update existing transaction
      transactions[existingIndex] = transaction;
    } else {
      // Add new transaction at the beginning
      transactions.insert(0, transaction);
    }

    // Save to storage
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await _smsBox.put(_smsTransactionsListKey, jsonList);
  }

  /// Get all saved SMS transactions from persistent storage
  static List<ParsedSmsTransaction> getAllSmsTransactions() {
    final jsonList = _smsBox.get(_smsTransactionsListKey);
    if (jsonList == null) return [];

    try {
      final List<dynamic> list = jsonList as List<dynamic>;
      return list
          .map(
            (json) =>
                ParsedSmsTransaction.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete a saved SMS transaction
  static Future<void> deleteSmsTransaction(String id) async {
    final transactions = getAllSmsTransactions();
    transactions.removeWhere((t) => t.id == id);

    final jsonList = transactions.map((t) => t.toJson()).toList();
    await _smsBox.put(_smsTransactionsListKey, jsonList);
  }

  /// Clear all saved SMS transactions
  static Future<void> clearAllSmsTransactions() async {
    await _smsBox.delete(_smsTransactionsListKey);
  }
}
