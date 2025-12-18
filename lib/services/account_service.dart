import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import 'storage_service.dart';

class AccountService {
  static const String _accountBoxName = 'accounts';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await Hive.openBox(_accountBoxName);
    _initialized = true;

    // Initialize with default accounts if empty
    if (getAllAccounts().isEmpty) {
      await _initializeDefaultAccounts();
    }
  }

  static Future<void> _initializeDefaultAccounts() async {
    final defaultAccounts = DefaultAccounts.getDefaultAccounts();
    for (var account in defaultAccounts) {
      await addAccount(account);
    }
  }

  static Box get _accountBox {
    if (!_initialized) {
      throw StateError(
          'AccountService not initialized. Call AccountService.init() first.');
    }
    return Hive.box(_accountBoxName);
  }

  static Future<void> addAccount(Account account) async {
    await _accountBox.put(account.id, account.toJson());
  }

  static Future<void> updateAccount(Account account) async {
    account.updatedAt = DateTime.now();
    await _accountBox.put(account.id, account.toJson());
  }

  static Future<void> deleteAccount(String id) async {
    await _accountBox.delete(id);
  }

  static List<Account> getAllAccounts() {
    try {
      return _accountBox.values
          .map((json) => Account.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Account? getAccount(String id) {
    try {
      final json = _accountBox.get(id);
      if (json == null) return null;
      return Account.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      return null;
    }
  }

  static List<Account> getAccountsByCategory(AccountCategory category) {
    return getAllAccounts().where((a) => a.category == category).toList();
  }

  static List<Account> getAccountsByCurrency(CurrencyType currency) {
    return getAllAccounts().where((a) => a.currency == currency).toList();
  }

  // Calculate balances based on transactions
  static double getTotalAssets() {
    final transactions = StorageService.getAllTransactions();
    double total = 0.0;

    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        total += t.amount;
      } else if (t.type == TransactionType.expense) {
        total -= t.amount;
      }
    }

    return total;
  }

  static double getTotalLiabilities() {
    // For now, return 0 - can be extended for credit card balances
    return 0.0;
  }

  static double getNetWorth() {
    return getTotalAssets() - getTotalLiabilities();
  }

  static Map<String, double> getBalancesByAccountType() {
    final transactions = StorageService.getAllTransactions();
    final balances = <String, double>{};

    for (var t in transactions) {
      final accountKey = t.accountType.name;
      balances[accountKey] = balances[accountKey] ?? 0.0;

      if (t.type == TransactionType.income) {
        balances[accountKey] = balances[accountKey]! + t.amount;
      } else if (t.type == TransactionType.expense) {
        balances[accountKey] = balances[accountKey]! - t.amount;
      }
    }

    return balances;
  }

  static double getCashBalance() {
    final transactions = StorageService.getAllTransactions();
    double balance = 0.0;

    for (var t in transactions) {
      if (t.accountType == AccountType.cash) {
        if (t.type == TransactionType.income) {
          balance += t.amount;
        } else if (t.type == TransactionType.expense) {
          balance -= t.amount;
        }
      }
    }

    return balance;
  }

  static double getBankBalance() {
    final transactions = StorageService.getAllTransactions();
    double balance = 0.0;

    for (var t in transactions) {
      if (t.accountType == AccountType.bank ||
          t.accountType == AccountType.other) {
        if (t.type == TransactionType.income) {
          balance += t.amount;
        } else if (t.type == TransactionType.expense) {
          balance -= t.amount;
        }
      }
    }

    return balance;
  }

  static double getCardBalance() {
    final transactions = StorageService.getAllTransactions();
    double balance = 0.0;

    for (var t in transactions) {
      if (t.accountType == AccountType.card) {
        if (t.type == TransactionType.income) {
          balance += t.amount;
        } else if (t.type == TransactionType.expense) {
          balance -= t.amount;
        }
      }
    }

    return balance;
  }
}

