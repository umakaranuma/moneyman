import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class CategoryService {
  static const String _incomeCategoriesBoxName = 'income_categories_full';
  static const String _expenseCategoriesBoxName = 'expense_categories_full';
  static const String _categoriesListKey = 'categories_list';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    
    await Hive.openBox(_incomeCategoriesBoxName);
    await Hive.openBox(_expenseCategoriesBoxName);
    
    _initialized = true;
    
    // Initialize with default categories if empty
    await _initializeDefaultCategories();
  }

  static Future<void> _initializeDefaultCategories() async {
    try {
      final incomeBox = Hive.box(_incomeCategoriesBoxName);
      final expenseBox = Hive.box(_expenseCategoriesBoxName);
      
      // Initialize expense categories only if not already saved
      if (!expenseBox.containsKey(_categoriesListKey)) {
        print('Initializing default expense categories (first time)');
        final expenseCategories = DefaultCategories.expenseCategories
            .map((cat) => cat.toJson())
            .toList();
        await expenseBox.put(_categoriesListKey, expenseCategories);
        print('Default expense categories initialized: ${expenseCategories.length} categories');
      } else {
        final saved = expenseBox.get(_categoriesListKey) as List<dynamic>?;
        print('Expense categories already exist in storage: ${saved?.length ?? 0} categories');
      }
      
      // Initialize income categories only if not already saved
      if (!incomeBox.containsKey(_categoriesListKey)) {
        print('Initializing default income categories (first time)');
        final incomeCategories = DefaultCategories.incomeCategories
            .map((cat) => cat.toJson())
            .toList();
        await incomeBox.put(_categoriesListKey, incomeCategories);
        print('Default income categories initialized: ${incomeCategories.length} categories');
      } else {
        final saved = incomeBox.get(_categoriesListKey) as List<dynamic>?;
        print('Income categories already exist in storage: ${saved?.length ?? 0} categories');
      }
    } catch (e) {
      print('Error initializing default categories: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  static Box get _incomeBox {
    if (!_initialized) {
      throw StateError('CategoryService not initialized. Call CategoryService.init() first.');
    }
    return Hive.box(_incomeCategoriesBoxName);
  }

  static Box get _expenseBox {
    if (!_initialized) {
      throw StateError('CategoryService not initialized. Call CategoryService.init() first.');
    }
    return Hive.box(_expenseCategoriesBoxName);
  }

  // Get all categories with subcategories
  static List<Category> getCategories({required bool isIncome}) {
    try {
      final box = isIncome ? _incomeBox : _expenseBox;
      
      // Check if categories exist in storage
      if (!box.containsKey(_categoriesListKey)) {
        print('No categories found in storage, returning defaults');
        // Return mutable copy of defaults
        final defaults = isIncome 
            ? DefaultCategories.incomeCategories
            : DefaultCategories.expenseCategories;
        return defaults.map((cat) => Category(
          id: cat.id,
          name: cat.name,
          emoji: cat.emoji,
          subcategories: List<String>.from(cat.subcategories),
          isIncome: cat.isIncome,
        )).toList();
      }
      
      final categoriesJson = box.get(_categoriesListKey) as List<dynamic>?;
      
      if (categoriesJson == null || categoriesJson.isEmpty) {
        print('Categories JSON is null or empty, returning defaults');
        // Return mutable copy of defaults
        final defaults = isIncome 
            ? DefaultCategories.incomeCategories
            : DefaultCategories.expenseCategories;
        return defaults.map((cat) => Category(
          id: cat.id,
          name: cat.name,
          emoji: cat.emoji,
          subcategories: List<String>.from(cat.subcategories),
          isIncome: cat.isIncome,
        )).toList();
      }
      
      print('Loading ${categoriesJson.length} categories from storage');
      
      final categories = categoriesJson
          .map((json) {
            try {
              // Convert Map<dynamic, dynamic> to Map<String, dynamic>
              final categoryMap = Map<String, dynamic>.from(json as Map);
              return Category.fromJson(categoryMap);
            } catch (e) {
              print('Error parsing category: $e');
              print('Category JSON: $json');
              return null;
            }
          })
          .whereType<Category>()
          .toList();
      
      // Return saved categories, or defaults if parsing failed
      // Always return a mutable copy
      if (categories.isNotEmpty) {
        print('Successfully loaded ${categories.length} categories from storage');
        return categories.map((cat) => Category(
          id: cat.id,
          name: cat.name,
          emoji: cat.emoji,
          subcategories: List<String>.from(cat.subcategories),
          isIncome: cat.isIncome,
        )).toList();
      } else {
        print('Parsed categories list is empty, returning defaults');
        // Return mutable copy of defaults
        final defaults = isIncome 
            ? DefaultCategories.incomeCategories
            : DefaultCategories.expenseCategories;
        return defaults.map((cat) => Category(
          id: cat.id,
          name: cat.name,
          emoji: cat.emoji,
          subcategories: List<String>.from(cat.subcategories),
          isIncome: cat.isIncome,
        )).toList();
      }
    } catch (e) {
      print('Error getting categories: $e');
      // Return mutable copy of defaults on error
      final defaults = isIncome 
          ? DefaultCategories.incomeCategories
          : DefaultCategories.expenseCategories;
      return defaults.map((cat) => Category(
        id: cat.id,
        name: cat.name,
        emoji: cat.emoji,
        subcategories: List<String>.from(cat.subcategories),
        isIncome: cat.isIncome,
      )).toList();
    }
  }

  // Save all categories
  static Future<void> saveCategories(List<Category> categories, {required bool isIncome}) async {
    try {
      final box = isIncome ? _incomeBox : _expenseBox;
      final categoriesJson = categories.map((cat) => cat.toJson()).toList();
      
      print('Saving ${categories.length} categories to storage (isIncome: $isIncome)');
      print('Categories to save: ${categories.map((c) => '${c.name}(${c.id})').join(", ")}');
      
      // Save to Hive
      await box.put(_categoriesListKey, categoriesJson);
      
      // Force Hive to flush to disk
      await box.flush();
      
      // Verify the save worked by reading back
      final saved = box.get(_categoriesListKey) as List<dynamic>?;
      if (saved != null && saved.length == categories.length) {
        print('✓ Categories saved and verified successfully: ${saved.length} categories');
        // Double-check by parsing back
        final parsed = saved.map((json) {
          try {
            // Convert Map<dynamic, dynamic> to Map<String, dynamic>
            final categoryMap = Map<String, dynamic>.from(json as Map);
            return Category.fromJson(categoryMap);
          } catch (e) {
            print('Error parsing saved category: $e');
            return null;
          }
        }).whereType<Category>().toList();
        if (parsed.length == categories.length) {
          print('✓ Categories parsed successfully after save');
        } else {
          print('WARNING: Parsed count mismatch. Expected ${categories.length}, got ${parsed.length}');
        }
      } else {
        print('ERROR: Save verification failed. Expected ${categories.length}, got ${saved?.length ?? 0}');
        throw Exception('Failed to verify saved categories');
      }
    } catch (e) {
      print('Error saving categories: $e');
      print('Stack trace: ${StackTrace.current}');
      // Re-throw to let caller know save failed
      rethrow;
    }
  }

  // Legacy methods for backward compatibility
  static List<String> getIncomeCategories() {
    try {
      final categories = getCategories(isIncome: true);
      return categories.map((c) => c.name).toList()..sort();
    } catch (e) {
      return [];
    }
  }

  static List<String> getExpenseCategories() {
    try {
      final categories = getCategories(isIncome: false);
      return categories.map((c) => c.name).toList()..sort();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addIncomeCategory(String category) async {
    // Legacy method - not used for full category management
  }

  static Future<void> addExpenseCategory(String category) async {
    // Legacy method - not used for full category management
  }

  static Future<void> deleteIncomeCategory(String category) async {
    // Legacy method - not used for full category management
  }

  static Future<void> deleteExpenseCategory(String category) async {
    // Legacy method - not used for full category management
  }

  static List<String> getCategoriesForType(TransactionType type) {
    try {
      switch (type) {
        case TransactionType.income:
          return getIncomeCategories();
        case TransactionType.expense:
          return getExpenseCategories();
        case TransactionType.transfer:
          return []; // Transfers don't need categories
      }
    } catch (e) {
      return [];
    }
  }

  // Get category by name from saved categories
  static Category? getCategoryByName(String name, {bool isIncome = false}) {
    try {
      final categories = getCategories(isIncome: isIncome);
      try {
        return categories.firstWhere(
          (c) => c.name.toLowerCase() == name.toLowerCase(),
        );
      } catch (e) {
        // Category not found in saved categories, try defaults
        return DefaultCategories.getCategoryByName(name, isIncome: isIncome);
      }
    } catch (e) {
      // Fallback to default categories on error
      return DefaultCategories.getCategoryByName(name, isIncome: isIncome);
    }
  }

  // Get category emoji from saved categories
  static String getCategoryEmoji(String? categoryName, {bool isIncome = false}) {
    if (categoryName == null) return '';
    try {
      final category = getCategoryByName(categoryName, isIncome: isIncome);
      return category?.emoji ?? '';
    } catch (e) {
      // Fallback to default categories
      return DefaultCategories.getCategoryEmoji(categoryName, isIncome: isIncome);
    }
  }
}
