class Category {
  final String id;
  final String name;
  final String emoji;
  final List<String> subcategories;
  final bool isIncome;

  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    this.subcategories = const [],
    this.isIncome = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'subcategories': subcategories,
      'isIncome': isIncome,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      subcategories: List<String>.from(json['subcategories'] ?? []),
      isIncome: json['isIncome'] ?? false,
    );
  }
}

class DefaultCategories {
  static const List<Category> expenseCategories = [
    Category(
      id: 'food',
      name: 'Food',
      emoji: '🍲',
      subcategories: ['Lunch', 'Dinner', 'Eating out', 'Beverages', 'fruits', 'snacks 🍪😋'],
    ),
    Category(
      id: 'social_life',
      name: 'Social Life',
      emoji: '👨‍👩‍👦‍👦',
      subcategories: ['Friend', 'Fellowship', 'Alumni', 'Dues'],
    ),
    Category(
      id: 'pets',
      name: 'Pets',
      emoji: '🐶',
      subcategories: [],
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      emoji: '🚌',
      subcategories: ['Bus', 'Subway', 'Taxi', 'Car'],
    ),
    Category(
      id: 'culture',
      name: 'Culture',
      emoji: '🖼️',
      subcategories: ['Books', 'Movie', 'Music', 'Apps'],
    ),
    Category(
      id: 'household',
      name: 'Household',
      emoji: '🪑',
      subcategories: ['Appliances', 'Furniture', 'Kitchen', 'Toiletries', 'Chandlery'],
    ),
    Category(
      id: 'apparel',
      name: 'Apparel',
      emoji: '👕',
      subcategories: ['Clothing', 'Fashion', 'Shoes', 'Laundry'],
    ),
    Category(
      id: 'beauty',
      name: 'Beauty',
      emoji: '🤡',
      subcategories: ['Cosmetics', 'Makeup', 'Accessories', 'Beauty'],
    ),
    Category(
      id: 'health',
      name: 'Health',
      emoji: '🧘',
      subcategories: ['Health', 'Yoga', 'Hospital', 'Medicine'],
    ),
    Category(
      id: 'education',
      name: 'Education',
      emoji: '📒',
      subcategories: ['Schooling', 'Textbooks', 'School supplies', 'Academy', 'notebook'],
    ),
    Category(
      id: 'gift',
      name: 'Gift',
      emoji: '🎁',
      subcategories: [],
    ),
    Category(
      id: 'package',
      name: 'package',
      emoji: '📱',
      subcategories: ['mobile', 'chat gpt', 'cursor', 'wifi'],
    ),
    Category(
      id: 'other_expense',
      name: 'Other',
      emoji: '',
      subcategories: [],
    ),
    Category(
      id: 'bike',
      name: 'Bike',
      emoji: '🏍️',
      subcategories: ['potrol', 'service', 'oil', 'other'],
    ),
    Category(
      id: 'cricket',
      name: 'Cricket',
      emoji: '🏏',
      subcategories: ['Enter fee', 'beverages'],
    ),
  ];

  static const List<Category> incomeCategories = [
    Category(
      id: 'salary',
      name: 'Salary',
      emoji: '💰',
      subcategories: [],
      isIncome: true,
    ),
    Category(
      id: 'business',
      name: 'Business',
      emoji: '💼',
      subcategories: [],
      isIncome: true,
    ),
    Category(
      id: 'investment',
      name: 'Investment',
      emoji: '📈',
      subcategories: [],
      isIncome: true,
    ),
    Category(
      id: 'gift_income',
      name: 'Gift',
      emoji: '🎁',
      subcategories: [],
      isIncome: true,
    ),
    Category(
      id: 'other_income',
      name: 'Other',
      emoji: '',
      subcategories: [],
      isIncome: true,
    ),
  ];

  static Category? getCategoryByName(String name, {bool isIncome = false}) {
    final categories = isIncome ? incomeCategories : expenseCategories;
    try {
      return categories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static String getCategoryEmoji(String? categoryName, {bool isIncome = false}) {
    if (categoryName == null) return '';
    final category = getCategoryByName(categoryName, isIncome: isIncome);
    return category?.emoji ?? '';
  }
}

