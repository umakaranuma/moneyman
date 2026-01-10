enum TransactionType {
  income,
  expense,
  transfer,
}

enum AccountType {
  cash,
  card,
  bank,
  other,
}

class Transaction {
  String id;
  String title;
  double amount;
  TransactionType type; // income, expense, or transfer
  DateTime date;
  String? category;
  String? note; // Changed from description to note
  AccountType accountType; // Cash, Card, Bank, Other
  String? fromAccount; // For transfers
  String? toAccount; // For transfers
  bool isBookmarked; // Bookmark flag

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.category,
    this.note,
    required this.accountType,
    this.fromAccount,
    this.toAccount,
    this.isBookmarked = false,
  });

  // Helper getter for backward compatibility
  bool get isIncome => type == TransactionType.income;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'category': category,
      'note': note,
      'accountType': accountType.name,
      'fromAccount': fromAccount,
      'toAccount': toAccount,
      'isBookmarked': isBookmarked,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'].toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => json['isIncome'] == true
            ? TransactionType.income
            : TransactionType.expense, // Backward compatibility
      ),
      date: DateTime.parse(json['date']),
      category: json['category'],
      note: json['note'] ?? json['description'], // Backward compatibility
      accountType: json['accountType'] != null
          ? AccountType.values.firstWhere(
              (e) => e.name == json['accountType'],
              orElse: () => AccountType.cash,
            )
          : AccountType.cash,
      fromAccount: json['fromAccount'],
      toAccount: json['toAccount'],
      isBookmarked: json['isBookmarked'] ?? false,
    );
  }
}
