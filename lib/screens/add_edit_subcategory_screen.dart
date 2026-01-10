import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class AddEditSubcategoryScreen extends StatefulWidget {
  final Category? category;
  final String? subcategory;
  final bool isExpense;
  final bool isConvertingFromCategory;

  const AddEditSubcategoryScreen({
    super.key,
    this.category,
    this.subcategory,
    required this.isExpense,
    this.isConvertingFromCategory = false,
  });

  @override
  State<AddEditSubcategoryScreen> createState() =>
      _AddEditSubcategoryScreenState();
}

class _AddEditSubcategoryScreenState extends State<AddEditSubcategoryScreen> {
  late TextEditingController _subcategoryController;
  late TextEditingController _categoryController;
  final _formKey = GlobalKey<FormState>();
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _subcategoryController =
        TextEditingController(text: widget.subcategory ?? '');
    _categoryController = TextEditingController(
      text: widget.category != null
          ? '${widget.category!.emoji} ${widget.category!.name}'
          : '',
    );
    _selectedCategory = widget.category;
    
    // If converting from category, show category picker immediately
    if (widget.isConvertingFromCategory && widget.category == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCategoryPicker();
      });
    }
  }

  @override
  void dispose() {
    _subcategoryController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _showCategoryPicker() {
    final categories = CategoryService.getCategories(
      isIncome: !widget.isExpense,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final maxHeight = screenHeight * 0.7;
        
        return Container(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Category',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory?.id == category.id;
                    return ListTile(
                      leading: category.emoji.isNotEmpty
                          ? Text(
                              category.emoji,
                              style: const TextStyle(fontSize: 24),
                            )
                          : const Icon(Icons.category_rounded),
                      title: Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.fab
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.fab)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                          _categoryController.text =
                              '${category.emoji} ${category.name}';
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveSubcategory() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final subcategoryName = _subcategoryController.text.trim();
      if (subcategoryName.isEmpty) {
        return;
      }

      try {
        // Get categories and create a mutable copy
        final allCategories = List<Category>.from(
          CategoryService.getCategories(
            isIncome: !widget.isExpense,
          ),
        );

        // If converting from main category, remove the original category
        if (widget.isConvertingFromCategory && widget.subcategory != null) {
          allCategories.removeWhere(
            (c) => c.name == widget.subcategory,
          );
        }

        final categoryIndex = allCategories.indexWhere(
          (c) => c.id == _selectedCategory!.id,
        );

        if (categoryIndex != -1) {
          final updatedSubcategories =
              List<String>.from(allCategories[categoryIndex].subcategories);

          if (widget.subcategory != null && !widget.isConvertingFromCategory) {
            // Edit existing subcategory
            final oldIndex = updatedSubcategories.indexOf(widget.subcategory!);
            if (oldIndex != -1) {
              updatedSubcategories[oldIndex] = subcategoryName;
            }
          } else {
            // Add new subcategory
            if (!updatedSubcategories.contains(subcategoryName)) {
              updatedSubcategories.add(subcategoryName);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Subcategory "$subcategoryName" already exists'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }
          }

          allCategories[categoryIndex] = Category(
            id: allCategories[categoryIndex].id,
            name: allCategories[categoryIndex].name,
            emoji: allCategories[categoryIndex].emoji,
            subcategories: updatedSubcategories,
            isIncome: allCategories[categoryIndex].isIncome,
          );

          await CategoryService.saveCategories(
            allCategories,
            isIncome: !widget.isExpense,
          );

          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving subcategory: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _convertToMainCategory() {
    final subcategoryName = _subcategoryController.text.trim();
    if (subcategoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a subcategory name first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Convert to Main Category',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to convert "$subcategoryName" to a main category?',
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
              try {
                // Get categories and create a mutable copy
                final allCategories = List<Category>.from(
                  CategoryService.getCategories(
                    isIncome: !widget.isExpense,
                  ),
                );

                // Remove subcategory from current category
                if (_selectedCategory != null) {
                  final categoryIndex = allCategories.indexWhere(
                    (c) => c.id == _selectedCategory!.id,
                  );
                  if (categoryIndex != -1) {
                    final updatedSubcategories = List<String>.from(
                      allCategories[categoryIndex].subcategories,
                    );
                    updatedSubcategories.remove(subcategoryName);

                    allCategories[categoryIndex] = Category(
                      id: allCategories[categoryIndex].id,
                      name: allCategories[categoryIndex].name,
                      emoji: allCategories[categoryIndex].emoji,
                      subcategories: updatedSubcategories,
                      isIncome: allCategories[categoryIndex].isIncome,
                    );
                  }
                }

                // Add as new main category
                final newCategory = Category(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: subcategoryName,
                  emoji: '',
                  subcategories: [],
                  isIncome: !widget.isExpense,
                );
                allCategories.add(newCategory);

                await CategoryService.saveCategories(
                  allCategories,
                  isIncome: !widget.isExpense,
                );

                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Close subcategory screen
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error converting: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
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
          widget.subcategory != null
              ? 'Modify Subcategory'
              : 'Add Subcategory',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _convertToMainCategory,
            child: const Text(
              '+ Main Category',
              style: TextStyle(
                color: AppColors.fab,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Category Field (Read-only, tappable to change)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _showCategoryPicker,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _categoryController.text.isEmpty
                                ? 'Select category'
                                : _categoryController.text,
                            style: TextStyle(
                              color: _categoryController.text.isEmpty
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.textMuted,
                          size: 16,
                        ),
                      ],
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.only(top: 8),
                      color: AppColors.surfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Subcategory Name Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextFormField(
                controller: _subcategoryController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Subcategory',
                  labelStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  hintText: 'Enter subcategory name',
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
                autofocus: widget.subcategory == null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subcategory name';
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
                  onPressed: _saveSubcategory,
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

