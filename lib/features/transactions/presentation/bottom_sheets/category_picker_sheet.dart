import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/category.dart';
import '../../../../services/category_service.dart';
import '../../../../theme/app_theme.dart';

/// Category picker: list of categories (minimal style). Subcategory via inline or second sheet.
class CategoryPickerSheet extends StatelessWidget {
  final bool isIncome;
  final String? selectedCategory;
  final String? selectedSubcategory;
  final void Function(String category, String? subcategory) onSelected;
  final VoidCallback? onManageCategories;

  const CategoryPickerSheet({
    super.key,
    required this.isIncome,
    required this.selectedCategory,
    this.selectedSubcategory,
    required this.onSelected,
    this.onManageCategories,
  });

  @override
  Widget build(BuildContext context) {
    final categories = CategoryService.getCategories(isIncome: isIncome);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Category',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isIncome ? 'Income source' : 'Expense category',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (onManageCategories != null)
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onManageCategories?.call();
                    },
                    icon: const Icon(Icons.settings_rounded, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category.name;
                return _CategoryTile(
                  category: category,
                  isSelected: isSelected,
                  selectedSubcategory: selectedSubcategory,
                  onTap: () => _onCategoryTap(context, category),
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _onCategoryTap(BuildContext context, Category category) {
    if (category.subcategories.isEmpty) {
      onSelected(category.name, null);
      Navigator.pop(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SubcategorySheet(
        category: category,
        selectedSubcategory: selectedSubcategory,
        onSelected: (sub) {
          onSelected(category.name, sub);
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final String? selectedSubcategory;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    this.selectedSubcategory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(
        category.emoji.isNotEmpty ? category.emoji : '📁',
        style: const TextStyle(fontSize: 22),
      ),
      title: Text(
        category.name,
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: category.subcategories.isNotEmpty
          ? Text(
              '${category.subcategories.length} subcategories',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
            )
          : null,
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: AppColors.primary, size: 22)
          : null,
      onTap: onTap,
    );
  }
}

class _SubcategorySheet extends StatelessWidget {
  final Category category;
  final String? selectedSubcategory;
  final ValueChanged<String?> onSelected;

  const _SubcategorySheet({
    required this.category,
    required this.selectedSubcategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  category.name,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                ListTile(
                  title: Text('All ${category.name}', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  trailing: selectedSubcategory == null
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () => onSelected(null),
                ),
                ...category.subcategories.map((sub) {
                  final isSelected = selectedSubcategory == sub;
                  return ListTile(
                    title: Text(sub, style: GoogleFonts.inter()),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: AppColors.primary)
                        : null,
                    onTap: () => onSelected(sub),
                  );
                }),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
