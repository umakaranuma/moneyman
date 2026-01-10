import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import 'add_edit_subcategory_screen.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final Category? category;
  final bool isExpense;

  const AddEditCategoryScreen({
    super.key,
    this.category,
    required this.isExpense,
  });

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _convertToSubcategory() {
    final categoryName = _nameController.text.trim();
    if (categoryName.isEmpty && widget.category != null) {
      // Use existing category name
      _showConvertToSubcategoryDialog(widget.category!.name);
    } else if (categoryName.isNotEmpty) {
      _showConvertToSubcategoryDialog(categoryName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category name first'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showConvertToSubcategoryDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Convert to Subcategory',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to convert "$categoryName" to a subcategory? This will remove it as a main category.',
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
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close category screen
              
              // Navigate to add subcategory screen with pre-filled name
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditSubcategoryScreen(
                    category: null, // User will select target category
                    subcategory: categoryName,
                    isExpense: widget.isExpense,
                    isConvertingFromCategory: true,
                  ),
                ),
              );
            },
            child: const Text(
              'Convert',
              style: TextStyle(color: AppColors.fab),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      if (name.isNotEmpty) {
        try {
          // Get categories and create a mutable copy
          final allCategories = List<Category>.from(
            CategoryService.getCategories(
              isIncome: !widget.isExpense,
            ),
          );

          if (widget.category != null) {
            // Edit existing category
            final categoryIndex = allCategories.indexWhere(
              (c) => c.id == widget.category!.id,
            );
            if (categoryIndex != -1) {
              allCategories[categoryIndex] = Category(
                id: widget.category!.id,
                name: name,
                emoji: widget.category!.emoji,
                subcategories: widget.category!.subcategories,
                isIncome: widget.category!.isIncome,
              );
            }
          } else {
            // Add new category
            final newCategory = Category(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              emoji: '',
              subcategories: [],
              isIncome: !widget.isExpense,
            );
            allCategories.add(newCategory);
          }

          await CategoryService.saveCategories(
            allCategories,
            isIncome: !widget.isExpense,
          );

          if (mounted) {
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving category: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
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
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        title: Text(
          widget.category != null
              ? 'Edit Category'
              : widget.isExpense
                  ? 'Expenses Category'
                  : 'Income Category',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: widget.category != null
            ? [
                TextButton(
                  onPressed: _convertToSubcategory,
                  child: const Text(
                    '+ Subcategory',
                    style: TextStyle(
                      color: AppColors.fab,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ]
            : [
                TextButton(
                  onPressed: () {
                    // Navigate to add subcategory screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditSubcategoryScreen(
                          category: widget.category,
                          isExpense: widget.isExpense,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '+ Subcategory',
                        style: TextStyle(
                          color: AppColors.fab,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.fab,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Category Name Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextFormField(
                controller: _nameController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  hintText: 'Enter category name',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.surfaceVariant,
                      width: 1,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.fab,
                      width: 2,
                    ),
                  ),
                ),
                autofocus: widget.category == null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
            ),
            const Spacer(),
            // Save Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fab,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

