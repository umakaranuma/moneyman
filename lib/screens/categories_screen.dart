import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoriesScreen extends StatefulWidget {
  final bool isExpense;

  const CategoriesScreen({super.key, this.isExpense = true});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late bool _isExpense;
  String? _expandedCategoryId;
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
    final isExpanded = _expandedCategoryId == category.id;
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
              vertical: 4,
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor,
                        categoryColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                    setState(() {
                      if (isExpanded) {
                        _expandedCategoryId = null;
                      } else {
                        _expandedCategoryId = category.id;
                      }
                    });
                  }
                : null,
          ),

          // Expanded Subcategories Section
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Divider
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  ),
                  // Subcategories List
                  if (category.subcategories.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: category.subcategories.asMap().entries.map((
                        entry,
                      ) {
                        final subIndex = entry.key;
                        final sub = entry.value;
                        final subColor =
                            AppColors.categoryColors[(index + subIndex + 1) %
                                AppColors.categoryColors.length];

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: subColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: subColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sub,
                                style: TextStyle(
                                  color: subColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _showDeleteSubcategoryConfirmation(
                                  category,
                                  sub,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.expense.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No subcategories yet',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Add Subcategory Button
                  GestureDetector(
                    onTap: () => _showAddSubcategoryDialog(category),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: categoryColor.withValues(alpha: 0.3),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: categoryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add Subcategory',
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
            onPressed: () {
              setState(() {
                _categories.removeWhere((c) => c.id == category.id);
              });
              _saveCategories();
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
    final nameController = TextEditingController();
    final emojiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Add Category',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Shopping',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emojiController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Emoji (optional)',
                hintText: 'e.g., 🛒',
              ),
            ),
          ],
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
            onPressed: () {
              final name = nameController.text.trim();
              final emoji = emojiController.text.trim();
              if (name.isNotEmpty) {
                final newCategory = Category(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  emoji: emoji,
                  subcategories: [],
                  isIncome: !_isExpense,
                );
                setState(() {
                  _categories.add(newCategory);
                });
                _saveCategories();
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: AppColors.fab)),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    final nameController = TextEditingController(text: category.name);
    final emojiController = TextEditingController(text: category.emoji);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Edit Category',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emojiController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Emoji'),
            ),
          ],
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
            onPressed: () {
              final name = nameController.text.trim();
              final emoji = emojiController.text.trim();
              if (name.isNotEmpty) {
                final categoryIndex = _categories.indexWhere(
                  (c) => c.id == category.id,
                );
                if (categoryIndex != -1) {
                  setState(() {
                    _categories[categoryIndex] = Category(
                      id: category.id,
                      name: name,
                      emoji: emoji,
                      subcategories: category.subcategories,
                      isIncome: category.isIncome,
                    );
                  });
                  _saveCategories();
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: AppColors.fab)),
          ),
        ],
      ),
    );
  }

  void _showAddSubcategoryDialog(Category category) {
    final subcategoryController = TextEditingController();
    final categoryColor =
        AppColors.categoryColors[_categories.indexWhere(
              (c) => c.id == category.id,
            ) %
            AppColors.categoryColors.length];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: category.emoji.isNotEmpty
                    ? Text(category.emoji, style: const TextStyle(fontSize: 20))
                    : const Icon(
                        Icons.category_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add to ${category.name}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: subcategoryController,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Subcategory Name',
            hintText: 'e.g., Lunch, Dinner, Snacks',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            hintStyle: TextStyle(color: AppColors.textMuted),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: categoryColor, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surfaceVariant),
            ),
            filled: true,
            fillColor: AppColors.background,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final subcategoryName = subcategoryController.text.trim();
              if (subcategoryName.isNotEmpty) {
                // Find the category index and update it
                final categoryIndex = _categories.indexWhere(
                  (c) => c.id == category.id,
                );
                if (categoryIndex != -1) {
                  final updatedSubcategories = List<String>.from(
                    _categories[categoryIndex].subcategories,
                  );
                  // Check if subcategory already exists
                  if (!updatedSubcategories.contains(subcategoryName)) {
                    updatedSubcategories.add(subcategoryName);
                    setState(() {
                      _categories[categoryIndex] = Category(
                        id: _categories[categoryIndex].id,
                        name: _categories[categoryIndex].name,
                        emoji: _categories[categoryIndex].emoji,
                        subcategories: updatedSubcategories,
                        isIncome: _categories[categoryIndex].isIncome,
                      );
                    });
                    _saveCategories();
                    Navigator.pop(context);
                  } else {
                    // Show error that subcategory already exists
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Subcategory "$subcategoryName" already exists',
                        ),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: categoryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Add',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteSubcategoryConfirmation(
    Category category,
    String subcategory,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.expense,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Subcategory',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceVariant, width: 1),
              ),
              child: Row(
                children: [
                  Text(
                    '"$subcategory"',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'from',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.name,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Find the category index and update it
              final categoryIndex = _categories.indexWhere(
                (c) => c.id == category.id,
              );
              if (categoryIndex != -1) {
                final updatedSubcategories = List<String>.from(
                  _categories[categoryIndex].subcategories,
                );
                updatedSubcategories.remove(subcategory);
                setState(() {
                  _categories[categoryIndex] = Category(
                    id: _categories[categoryIndex].id,
                    name: _categories[categoryIndex].name,
                    emoji: _categories[categoryIndex].emoji,
                    subcategories: updatedSubcategories,
                    isIncome: _categories[categoryIndex].isIncome,
                  );
                });
                _saveCategories();
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
