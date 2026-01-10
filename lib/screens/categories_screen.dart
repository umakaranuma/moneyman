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

  @override
  void initState() {
    super.initState();
    _isExpense = widget.isExpense;
    _categories = []; // Initialize empty to avoid late initialization error
    // Wait a bit to ensure Hive is fully initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadCategories();
    });
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

  Future<void> _saveCategories() async {
    try {
      // Save categories to storage
      await CategoryService.saveCategories(_categories, isIncome: !_isExpense);
      print('Categories saved: ${_categories.length}');
    } catch (e) {
      print('Error saving categories: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save categories: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        title: Text(
          _isExpense ? 'Expenses Category' : 'Income Category',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textPrimary),
            onPressed: () => _showAddCategoryDialog(),
          ),
        ],
      ),
      body: _categories.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryItem(category, index);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
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
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.category_outlined,
              size: 60,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Categories Yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first category',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Category category, int index) {
    final hasSubcategories = category.subcategories.isNotEmpty;
    final subcategoryCount = category.subcategories.length;
    // Use vibrant color from categoryColors based on index
    final categoryColor =
        AppColors.categoryColors[index % AppColors.categoryColors.length];

    return Container(
      key: ValueKey(category.id),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Category Header
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              // vertical: 4,
            ),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Delete button
                GestureDetector(
                  onTap: () => _showDeleteCategoryConfirmation(category),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: AppColors.expense,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Category color indicator + emoji
                Container(
                  // width: 44,
                  // height: 44,
                  // decoration: BoxDecoration(
                  //   gradient: LinearGradient(
                  //     colors: [
                  //       categoryColor,
                  //       categoryColor.withValues(alpha: 0.7),
                  //     ],
                  //     begin: Alignment.topLeft,
                  //     end: Alignment.bottomRight,
                  //   ),
                  //   borderRadius: BorderRadius.circular(12),
                  //   boxShadow: [
                  //     BoxShadow(
                  //       color: categoryColor.withValues(alpha: 0.3),
                  //       blurRadius: 8,
                  //       offset: const Offset(0, 2),
                  //     ),
                  //   ],
                  // ),
                  child: Center(
                    child: category.emoji.isNotEmpty
                        ? Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 20),
                          )
                        : const Icon(
                            Icons.category_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasSubcategories)
                  Container(
                    // padding: const EdgeInsets.symmetric(
                    //   horizontal: 8,
                    //   vertical: 3,
                    // ),
                    // decoration: BoxDecoration(
                    //   color: categoryColor.withValues(alpha: 0.15),
                    //   borderRadius: BorderRadius.circular(8),
                    // ),
                    child: Text(
                      '($subcategoryCount)',
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _showEditCategoryDialog(category),
                  child: Container(
                    // padding: const EdgeInsets.all(8),
                    // decoration: BoxDecoration(
                    //   color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    //   borderRadius: BorderRadius.circular(8),
                    // ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.drag_handle_rounded,
                  color: categoryColor.withValues(alpha: 0.5),
                  size: 22,
                ),
              ],
            ),
            onTap: hasSubcategories
                ? () {
                    // Navigate to subcategories screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubcategoriesScreen(
                          category: category,
                          categoryIndex: index,
                        ),
                      ),
                    ).then((_) {
                      // Reload categories when returning from subcategories screen
                      _loadCategories();
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryConfirmation(Category category) {
    showDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Get categories and create a mutable copy
              final allCategories = List<Category>.from(
                CategoryService.getCategories(isIncome: !_isExpense),
              );
              allCategories.removeWhere((c) => c.id == category.id);
              await CategoryService.saveCategories(
                allCategories,
                isIncome: !_isExpense,
              );
              setState(() {
                _categories.removeWhere((c) => c.id == category.id);
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
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
