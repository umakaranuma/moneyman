// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import 'subcategories_screen.dart';
import 'add_edit_category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final bool isExpense;

  const CategoriesScreen({super.key, this.isExpense = true});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late bool _isExpense;
  late List<Category> _categories;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _isExpense = widget.isExpense;
    _categories = []; // Initialize empty to avoid late initialization error
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
    // Wait a bit to ensure Hive is fully initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Category> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    final q = _searchQuery.toLowerCase();
    return _categories
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.emoji.contains(_searchQuery) ||
              c.subcategories.any((s) => s.toLowerCase().contains(q)),
        )
        .toList();
  }

  Future<void> _loadCategories() async {
    try {
      // Load categories from storage
      final loadedCategories = CategoryService.getCategories(
        isIncome: !_isExpense,
      );
      if (mounted) {
        setState(() {
          _categories = loadedCategories
              .map(
                (cat) => Category(
                  id: cat.id,
                  name: cat.name,
                  emoji: cat.emoji,
                  subcategories: List<String>.from(cat.subcategories),
                  isIncome: cat.isIncome,
                ),
              )
              .toList();
        });
      }
    } catch (e) {
      // Fallback to defaults on error
      if (mounted) {
        final defaultCategories = _isExpense
            ? DefaultCategories.expenseCategories
            : DefaultCategories.incomeCategories;
        setState(() {
          _categories = defaultCategories
              .map(
                (cat) => Category(
                  id: cat.id,
                  name: cat.name,
                  emoji: cat.emoji,
                  subcategories: List<String>.from(cat.subcategories),
                  isIncome: cat.isIncome,
                ),
              )
              .toList();
        });
      }
    }
  }

  void _toggleCategoryType() {
    setState(() {
      _isExpense = !_isExpense;
    });
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildPremiumHeader(),
            _buildSearchBar(),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredCategories.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      itemCount: _filteredCategories.length,
                      itemBuilder: (_, index) {
                        final category = _filteredCategories[index];
                        final actualIndex = _categories.indexWhere(
                          (c) => c.id == category.id,
                        );
                        return _buildPremiumCategoryItem(
                          category,
                          actualIndex >= 0 ? actualIndex : index,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildAddButton(),
    );
  }

  Widget _buildPremiumHeader() {
    final accent = _isExpense ? AppColors.expense : AppColors.income;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.surfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isExpense ? "Expense Categories" : "Income Categories",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isExpense
                        ? "Organize spending with smart groups"
                        : "Organize earnings by source",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _toggleCategoryType,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.surfaceVariant.withValues(alpha: 0.55),
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            icon: Icon(Icons.search_rounded, color: AppColors.textMuted),
            hintText: "Search categories...",
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCategoryItem(Category category, int index) {
    final hasSubs = category.subcategories.isNotEmpty;
    final accent = _isExpense ? AppColors.expense : AppColors.income;
    final icon = _CategoryIconResolver.resolve(category.name, isExpense: _isExpense);
    final hasEmoji = category.emoji.trim().isNotEmpty;

    return Dismissible(
      key: ValueKey(category.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showDeleteCategoryConfirmation(category),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.expense,
        ),
      ),
      child: GestureDetector(
        onTap: hasSubs
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubcategoriesScreen(
                      category: category,
                      categoryIndex: index,
                    ),
                  ),
                ).then((_) => _loadCategories());
              }
            : null,
        onLongPress: () => _showEditCategoryDialog(category),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.surfaceVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: hasEmoji
                      ? Text(
                          category.emoji,
                          style: const TextStyle(fontSize: 22),
                        )
                      : Icon(
                          icon,
                          size: 22,
                          color: accent,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (hasSubs)
                      Text(
                        "${category.subcategories.length} subcategories",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasSubs)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                )
              else
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: accent.withValues(alpha: 0.55),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton.extended(
      backgroundColor: _isExpense ? AppColors.expense : AppColors.income,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
      label: const Text(
        "Add Category",
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      onPressed: _showAddCategoryDialog,
    );
  }

  Widget _buildEmptyState() {
    final isSearch = _searchQuery.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              isSearch ? Icons.search_off_rounded : Icons.category_outlined,
              size: 60,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearch ? 'No matches' : 'No Categories Yet',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? 'Try a different search'
                : 'Tap Add Category to create your first one',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteCategoryConfirmation(Category category) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Category',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              final allCategories = List<Category>.from(
                CategoryService.getCategories(isIncome: !_isExpense),
              );
              allCategories.removeWhere((c) => c.id == category.id);
              await CategoryService.saveCategories(
                allCategories,
                isIncome: !_isExpense,
              );
              if (mounted) {
                setState(() {
                  _categories.removeWhere((c) => c.id == category.id);
                });
              }
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
    return result;
  }

  void _showAddCategoryDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(isExpense: _isExpense),
      ),
    ).then((result) {
      if (result == true) {
        _loadCategories();
      }
    });
  }

  void _showEditCategoryDialog(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditCategoryScreen(category: category, isExpense: _isExpense),
      ),
    ).then((result) {
      if (result == true) {
        _loadCategories();
      }
    });
  }
}

class _CategoryIconResolver {
  static IconData resolve(String categoryName, {required bool isExpense}) {
    final name = categoryName.toLowerCase();

    if (name.contains('food') || name.contains('restaurant') || name.contains('dining')) {
      return Icons.restaurant_rounded;
    }
    if (name.contains('grocery') || name.contains('supermarket') || name.contains('market')) {
      return Icons.local_grocery_store_rounded;
    }
    if (name.contains('transport') || name.contains('travel')) {
      return Icons.directions_car_rounded;
    }
    if (name.contains('fuel') || name.contains('petrol') || name.contains('diesel')) {
      return Icons.local_gas_station_rounded;
    }
    if (name.contains('shopping') || name.contains('fashion') || name.contains('clothes')) {
      return Icons.shopping_bag_rounded;
    }
    if (name.contains('health') || name.contains('medical') || name.contains('pharmacy')) {
      return Icons.health_and_safety_rounded;
    }
    if (name.contains('education') || name.contains('study') || name.contains('school')) {
      return Icons.school_rounded;
    }
    if (name.contains('entertainment') || name.contains('movie') || name.contains('fun')) {
      return Icons.movie_rounded;
    }
    if (name.contains('bill') || name.contains('utility') || name.contains('electric')) {
      return Icons.receipt_long_rounded;
    }
    if (name.contains('rent') || name.contains('house') || name.contains('home')) {
      return Icons.home_rounded;
    }
    if (name.contains('subscription') || name.contains('streaming')) {
      return Icons.subscriptions_rounded;
    }
    if (name.contains('phone') || name.contains('mobile') || name.contains('internet')) {
      return Icons.phone_android_rounded;
    }
    if (name.contains('salary') || name.contains('income') || name.contains('wage')) {
      return Icons.payments_rounded;
    }
    if (name.contains('business') || name.contains('freelance') || name.contains('project')) {
      return Icons.work_rounded;
    }
    if (name.contains('investment') || name.contains('stock')) {
      return Icons.trending_up_rounded;
    }
    if (name.contains('gift') || name.contains('bonus')) {
      return Icons.card_giftcard_rounded;
    }
    if (name.contains('loan') || name.contains('emi') || name.contains('debt')) {
      return Icons.account_balance_rounded;
    }

    return isExpense ? Icons.receipt_rounded : Icons.account_balance_wallet_rounded;
  }
}
