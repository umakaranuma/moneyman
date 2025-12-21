class Budget {
  String id;
  String category;
  double amount;
  int year;
  int month; // 1-12
  DateTime createdAt;
  DateTime updatedAt;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.year,
    required this.month,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'year': year,
      'month': month,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      category: json['category'],
      amount: json['amount'].toDouble(),
      year: json['year'],
      month: json['month'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}







