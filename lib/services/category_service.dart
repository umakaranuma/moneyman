import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';

class CategoryService {
  static const String _incomeCategoriesBoxName = 'income_categories';
  static const String _expenseCategoriesBoxName = 'expense_categories';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    
    await Hive.openBox(_incomeCategoriesBoxName);
    await Hive.openBox(_expenseCategoriesBoxName);
    
    _initialized = true;
    
    // Initialize with default categories if empty
    if (getIncomeCategories().isEmpty) {
      _initializeDefaultCategories();
    }
  }

  static void _initializeDefaultCategories() {
    try {
      final incomeBox = Hive.box(_incomeCategoriesBoxName);
      final expenseBox = Hive.box(_expenseCategoriesBoxName);
      
      final defaultIncome = ['Salary', 'Business', 'Investment', 'Gift', 'Other'];
      final defaultExpense = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Education', 'Other'];
      
      for (var category in defaultIncome) {
        if (!incomeBox.containsKey(category)) {
          incomeBox.put(category, true);
        }
      }
      
      for (var category in defaultExpense) {
        if (!expenseBox.containsKey(category)) {
          expenseBox.put(category, true);
        }
      }
    } catch (e) {
      // Handle error silently
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

  static List<String> getIncomeCategories() {
    try {
      return _incomeBox.keys.cast<String>().toList()..sort();
    } catch (e) {
      return [];
    }
  }

  static List<String> getExpenseCategories() {
    try {
      return _expenseBox.keys.cast<String>().toList()..sort();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addIncomeCategory(String category) async {
    if (category.trim().isNotEmpty) {
      await _incomeBox.put(category.trim(), true);
    }
  }

  static Future<void> addExpenseCategory(String category) async {
    if (category.trim().isNotEmpty) {
      await _expenseBox.put(category.trim(), true);
    }
  }

  static Future<void> deleteIncomeCategory(String category) async {
    await _incomeBox.delete(category);
  }

  static Future<void> deleteExpenseCategory(String category) async {
    await _expenseBox.delete(category);
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
}
