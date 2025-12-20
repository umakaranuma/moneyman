import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';

class BudgetService {
  static const String _budgetBoxName = 'budgets';

  static Future<void> init() async {
    await Hive.openBox(_budgetBoxName);
  }

  static Box get _budgetBox => Hive.box(_budgetBoxName);

  static Future<void> addBudget(Budget budget) async {
    await _budgetBox.put(budget.id, budget.toJson());
  }

  static Future<void> updateBudget(Budget budget) async {
    budget.updatedAt = DateTime.now();
    await _budgetBox.put(budget.id, budget.toJson());
  }

  static Future<void> deleteBudget(String id) async {
    await _budgetBox.delete(id);
  }

  static List<Budget> getAllBudgets() {
    final budgets = _budgetBox.values
        .map((json) => Budget.fromJson(Map<String, dynamic>.from(json)))
        .toList();
    return budgets;
  }

  static Budget? getBudget(String category, int year, int month) {
    final budgets = getAllBudgets();
    try {
      return budgets.firstWhere(
        (b) => b.category == category && b.year == year && b.month == month,
      );
    } catch (e) {
      return null;
    }
  }

  static List<Budget> getBudgetsForMonth(int year, int month) {
    return getAllBudgets()
        .where((b) => b.year == year && b.month == month)
        .toList();
  }

  static double getSpentForCategory(String category, int year, int month) {
    final transactions = StorageService.getAllTransactions();
    return transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.category == category &&
            t.date.year == year &&
            t.date.month == month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  static double getRemainingForCategory(String category, int year, int month) {
    final budget = getBudget(category, year, month);
    if (budget == null) return 0.0;
    final spent = getSpentForCategory(category, year, month);
    return budget.amount - spent;
  }

  static Map<String, BudgetStatus> getBudgetStatuses(int year, int month) {
    final budgets = getBudgetsForMonth(year, month);
    final statuses = <String, BudgetStatus>{};

    for (var budget in budgets) {
      final spent = getSpentForCategory(budget.category, year, month);
      final remaining = budget.amount - spent;
      final percentage = (spent / budget.amount * 100).clamp(0.0, 100.0);

      statuses[budget.category] = BudgetStatus(
        budget: budget,
        spent: spent,
        remaining: remaining,
        percentage: percentage,
      );
    }

    return statuses;
  }
}

class BudgetStatus {
  final Budget budget;
  final double spent;
  final double remaining;
  final double percentage;

  BudgetStatus({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
  });

  bool get isOverBudget => remaining < 0;
}






