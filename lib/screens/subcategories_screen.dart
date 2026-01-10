import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import 'add_edit_subcategory_screen.dart';

class SubcategoriesScreen extends StatefulWidget {
  final Category category;
  final int categoryIndex;

  const SubcategoriesScreen({
    super.key,
    required this.category,
    required this.categoryIndex,
  });

  @override
  State<SubcategoriesScreen> createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  late Category _category;
  late List<String> _subcategories;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _subcategories = List<String>.from(_category.subcategories);
  }

  Future<void> _saveSubcategories() async {
    try {
      // Get all categories and create a mutable copy
      final allCategories = List<Category>.from(
        CategoryService.getCategories(
          isIncome: _category.isIncome,
        ),
      );
      
      // Find and update the category
      final categoryIndex = allCategories.indexWhere(
        (c) => c.id == _category.id,
      );
      
      if (categoryIndex != -1) {
        allCategories[categoryIndex] = Category(
          id: _category.id,
          name: _category.name,
          emoji: _category.emoji,
          subcategories: _subcategories,
          isIncome: _category.isIncome,
        );
        
        await CategoryService.saveCategories(
          allCategories,
          isIncome: _category.isIncome,
        );
        
        // Update local category
        setState(() {
          _category = allCategories[categoryIndex];
        });
      }
    } catch (e) {
      print('Error saving subcategories: $e');
    }
  }

  void _showAddSubcategoryDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditSubcategoryScreen(
          category: _category,
          isExpense: !_category.isIncome,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Reload subcategories
        final allCategories = CategoryService.getCategories(
          isIncome: _category.isIncome,
        );
        final updatedCategory = allCategories.firstWhere(
          (c) => c.id == _category.id,
          orElse: () => _category,
        );
        setState(() {
          _category = updatedCategory;
          _subcategories = List<String>.from(updatedCategory.subcategories);
        });
      }
    });
  }

  void _showEditSubcategoryDialog(int index, String currentName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditSubcategoryScreen(
          category: _category,
          subcategory: currentName,
          isExpense: !_category.isIncome,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Reload subcategories
        final allCategories = CategoryService.getCategories(
          isIncome: _category.isIncome,
        );
        final updatedCategory = allCategories.firstWhere(
          (c) => c.id == _category.id,
          orElse: () => _category,
        );
        setState(() {
          _category = updatedCategory;
          _subcategories = List<String>.from(updatedCategory.subcategories);
        });
      }
    });
  }

  void _showDeleteSubcategoryConfirmation(int index, String subcategory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Subcategory',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "$subcategory"?',
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
                _subcategories.removeAt(index);
              });
              _saveSubcategories();
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

  void _showEditCategoryDialog() {
    final nameController = TextEditingController(text: _category.name);
    final emojiController = TextEditingController(text: _category.emoji);

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
                // Update category in storage
                // Get categories and create a mutable copy
                final allCategories = List<Category>.from(
                  CategoryService.getCategories(
                    isIncome: _category.isIncome,
                  ),
                );
                final categoryIndex = allCategories.indexWhere(
                  (c) => c.id == _category.id,
                );
                
                if (categoryIndex != -1) {
                  allCategories[categoryIndex] = Category(
                    id: _category.id,
                    name: name,
                    emoji: emoji,
                    subcategories: _subcategories,
                    isIncome: _category.isIncome,
                  );
                  
                  CategoryService.saveCategories(
                    allCategories,
                    isIncome: _category.isIncome,
                  );
                  
                  setState(() {
                    _category = allCategories[categoryIndex];
                  });
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

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.categoryColors[
        widget.categoryIndex % AppColors.categoryColors.length];

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
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        title: Row(
          children: [
            if (_category.emoji.isNotEmpty)
              Text(
                _category.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            const SizedBox(width: 8),
            Text(
              _category.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.textPrimary),
            onPressed: _showEditCategoryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textPrimary),
            onPressed: _showAddSubcategoryDialog,
          ),
        ],
      ),
      body: _subcategories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No subcategories yet',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first subcategory',
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _subcategories.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _subcategories.removeAt(oldIndex);
                  _subcategories.insert(newIndex, item);
                });
                _saveSubcategories();
              },
              itemBuilder: (context, index) {
                final subcategory = _subcategories[index];
                return Container(
                  key: ValueKey(subcategory),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: GestureDetector(
                      onTap: () => _showDeleteSubcategoryConfirmation(
                        index,
                        subcategory,
                      ),
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
                    title: Text(
                      subcategory,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _showEditSubcategoryDialog(
                            index,
                            subcategory,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withValues(
                                alpha: 0.5,
                              ),
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
                  ),
                );
              },
            ),
    );
  }
}

