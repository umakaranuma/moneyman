import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';

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
    // Initialize with mutable copies of default categories
    final defaultCategories = _isExpense
        ? DefaultCategories.expenseCategories
        : DefaultCategories.incomeCategories;
    _categories = defaultCategories.map((cat) => Category(
      id: cat.id,
      name: cat.name,
      emoji: cat.emoji,
      subcategories: List<String>.from(cat.subcategories),
      isIncome: cat.isIncome,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
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
            onPressed: () {
              _showAddCategoryDialog();
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryItem(category, index);
        },
      ),
    );
  }

  Widget _buildCategoryItem(Category category, int index) {
    final isExpanded = _expandedCategoryId == category.id;
    final hasSubcategories = category.subcategories.isNotEmpty;
    // Use vibrant color from categoryColors based on index
    final categoryColor = AppColors.categoryColors[index % AppColors.categoryColors.length];

    return Container(
      key: ValueKey(category.id),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category color indicator + emoji
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [categoryColor, categoryColor.withValues(alpha: 0.7)],
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
                        ? Text(category.emoji, style: const TextStyle(fontSize: 20))
                        : const Icon(Icons.category_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            title: Text(
              category.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasSubcategories)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                const SizedBox(width: 8),
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
              ],
            ),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCategoryId = null;
                } else {
                  _expandedCategoryId = category.id;
                }
              });
            },
          ),
          
          // Expanded Subcategories Section
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(12),
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
                  // Subcategories List
                  if (category.subcategories.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: category.subcategories.asMap().entries.map((entry) {
                        final subIndex = entry.key;
                        final sub = entry.value;
                        final subColor = AppColors.categoryColors[(index + subIndex + 1) % AppColors.categoryColors.length];
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                onTap: () => _showDeleteSubcategoryConfirmation(category, sub),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.expense.withValues(alpha: 0.7),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        mainAxisSize: MainAxisSize.min,
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
            child:
                const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              // Add category logic
              Navigator.pop(context);
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
              decoration: const InputDecoration(
                labelText: 'Category Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emojiController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Emoji',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              // Update category logic
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.fab)),
          ),
        ],
      ),
    );
  }

  void _showAddSubcategoryDialog(Category category) {
    final subcategoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Add Subcategory to ${category.name}',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: subcategoryController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Subcategory Name',
            hintText: 'e.g., Lunch',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              final subcategoryName = subcategoryController.text.trim();
              if (subcategoryName.isNotEmpty) {
                // Find the category index and update it
                final categoryIndex = _categories.indexWhere((c) => c.id == category.id);
                if (categoryIndex != -1) {
                  final updatedSubcategories = List<String>.from(_categories[categoryIndex].subcategories);
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
                  }
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: AppColors.fab)),
          ),
        ],
      ),
    );
  }

  void _showDeleteSubcategoryConfirmation(Category category, String subcategory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Subcategory',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "$subcategory" from "${category.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              // Find the category index and update it
              final categoryIndex = _categories.indexWhere((c) => c.id == category.id);
              if (categoryIndex != -1) {
                final updatedSubcategories = List<String>.from(_categories[categoryIndex].subcategories);
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
              }
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

