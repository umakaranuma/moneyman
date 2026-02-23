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
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.emoji.contains(_searchQuery) ||
            c.subcategories.any((s) => s.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> _loadCategories() async {
    try {
      // Load categories from storage
      final loadedCategories = CategoryService.getCategories(
        isIncome: !_isExpense,
      );
      print('Loaded ${loadedCategories.length} categories from storage');
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
      print('Error loading categories: $e');
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
                        final actualIndex = _categories
                            .indexWhere((c) => c.id == category.id);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _isExpense ? "Expense Categories" : "Income Categories",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: _toggleCategoryType,
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    category.emoji.isNotEmpty ? category.emoji : "📁",
                    style: const TextStyle(fontSize: 22),
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        "Add Category",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
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
