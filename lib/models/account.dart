enum AccountCategory {
  cash,
  bank,
  card,
  debitCard,
  savings,
  topUpPrepaid,
  investments,
  overdrafts,
  loan,
  insurance,
  others,
}

enum CurrencyType {
  lkr, // Sri Lankan Rupees - Rs.
  inr, // Indian Rupees - Rs.
  usd, // US Dollar - $
  eur, // Euro - €
  gbp, // British Pound - £
  jpy, // Japanese Yen - ¥
}

extension CurrencyTypeExtension on CurrencyType {
  /// Display label for settings and selectors (e.g. "LKR (Rs.)")
  String get displayLabel {
    switch (this) {
      case CurrencyType.lkr:
        return 'LKR (Rs.)';
      case CurrencyType.inr:
        return 'INR (Rs.)';
      case CurrencyType.usd:
        return 'USD (\$)';
      case CurrencyType.eur:
        return 'EUR (€)';
      case CurrencyType.gbp:
        return 'GBP (£)';
      case CurrencyType.jpy:
        return 'JPY (¥)';
    }
  }
}

class Account {
  String id;
  String name;
  AccountCategory category;
  CurrencyType currency;
  double balance;
  double? balancePayable; // For credit cards
  double? outstandingBalance; // For credit cards
  String? description;
  DateTime createdAt;
  DateTime updatedAt;

  Account({
    required this.id,
    required this.name,
    required this.category,
    this.currency = CurrencyType.lkr,
    this.balance = 0.0,
    this.balancePayable,
    this.outstandingBalance,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get currencySymbol {
    switch (currency) {
      case CurrencyType.lkr:
      case CurrencyType.inr:
        return 'Rs.';
      case CurrencyType.usd:
        return '\$';
      case CurrencyType.eur:
        return '€';
      case CurrencyType.gbp:
        return '£';
      case CurrencyType.jpy:
        return '¥';
    }
  }

  String get categoryLabel {
    switch (category) {
      case AccountCategory.cash:
        return 'Cash';
      case AccountCategory.bank:
        return 'Accounts';
      case AccountCategory.card:
        return 'Card';
      case AccountCategory.debitCard:
        return 'Debit Card';
      case AccountCategory.savings:
        return 'Savings';
      case AccountCategory.topUpPrepaid:
        return 'Top-Up/Prepaid';
      case AccountCategory.investments:
        return 'Investments';
      case AccountCategory.overdrafts:
        return 'Overdrafts';
      case AccountCategory.loan:
        return 'Loan';
      case AccountCategory.insurance:
        return 'Insurance';
      case AccountCategory.others:
        return 'Others';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'currency': currency.name,
      'balance': balance,
      'balancePayable': balancePayable,
      'outstandingBalance': outstandingBalance,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      category: AccountCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AccountCategory.cash,
      ),
      currency: CurrencyType.values.firstWhere(
        (e) => e.name == json['currency'],
        orElse: () => CurrencyType.lkr,
      ),
      balance: (json['balance'] ?? 0.0).toDouble(),
      balancePayable: json['balancePayable']?.toDouble(),
      outstandingBalance: json['outstandingBalance']?.toDouble(),
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

class DefaultAccounts {
  static List<Account> getDefaultAccounts() {
    return [
      Account(
        id: 'cash_inr',
        name: 'Cash',
        category: AccountCategory.cash,
        currency: CurrencyType.inr,
        balance: 0.0,
      ),
      Account(
        id: 'cash_usd',
        name: 'Cash',
        category: AccountCategory.cash,
        currency: CurrencyType.usd,
        balance: 0.0,
      ),
      Account(
        id: 'accounts_inr',
        name: 'Accounts',
        category: AccountCategory.bank,
        currency: CurrencyType.inr,
        balance: 0.0,
      ),
      Account(
        id: 'accounts_usd',
        name: 'Accounts',
        category: AccountCategory.bank,
        currency: CurrencyType.usd,
        balance: 0.0,
      ),
      Account(
        id: 'card_inr',
        name: 'Card',
        category: AccountCategory.card,
        currency: CurrencyType.inr,
        balance: 0.0,
        balancePayable: 0.0,
        outstandingBalance: 0.0,
      ),
      Account(
        id: 'card_usd',
        name: 'Card',
        category: AccountCategory.card,
        currency: CurrencyType.usd,
        balance: 0.0,
        balancePayable: 0.0,
        outstandingBalance: 0.0,
      ),
    ];
  }
}

