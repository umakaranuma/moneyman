import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/category.dart';
import '../../../../services/category_service.dart';
import '../../../../theme/app_theme.dart';

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
    final accent = isIncome ? AppColors.income : AppColors.expense;

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isIncome ? Icons.savings_rounded : Icons.receipt_long_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Category',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isIncome ? 'Choose your income source' : 'Choose your expense category',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onManageCategories != null)
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onManageCategories?.call();
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface.withValues(alpha: 0.7),
                        ),
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category.name;
                  return _CategoryTile(
                    category: category,
                    isSelected: isSelected,
                    selectedSubcategory: selectedSubcategory,
                    onTap: () => _onCategoryTap(context, category),
                    accent: accent,
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
  final Color accent;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    this.selectedSubcategory,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final categoryIcon = _CategoryIconResolver.resolve(category.name);
    final isSubcategorySelected = isSelected && selectedSubcategory != null;
    final hasEmoji = category.emoji.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? accent.withValues(alpha: 0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? accent.withValues(alpha: 0.45)
              : AppColors.surfaceVariant.withValues(alpha: 0.45),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: hasEmoji
              ? Center(
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                )
              : Icon(
                  categoryIcon,
                  color: isSelected ? accent : AppColors.textSecondary,
                  size: 21,
                ),
        ),
        minVerticalPadding: 8,
        horizontalTitleGap: 10,
        minLeadingWidth: 0,
        dense: false,
        visualDensity: const VisualDensity(vertical: -1),
        onTap: onTap,
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: accent, size: 22)
            : Icon(
                category.subcategories.isNotEmpty
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: AppColors.textMuted,
                size: category.subcategories.isNotEmpty ? 16 : 20,
              ),
        subtitle: Text(
          isSubcategorySelected
              ? selectedSubcategory!
              : category.subcategories.isNotEmpty
              ? '${category.subcategories.length} subcategories'
              : 'No subcategories',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),
        title: Text(
          category.name,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
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
    final accent = AppColors.primary;

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
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _CategoryIconResolver.resolve(category.name),
                            color: accent,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            category.name,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
                  _SubcategoryTile(
                    title: 'All ${category.name}',
                    icon: _CategoryIconResolver.resolve(category.name),
                    isSelected: selectedSubcategory == null,
                    accent: accent,
                    onTap: () => onSelected(null),
                  ),
                  ...category.subcategories.map((sub) {
                    return _SubcategoryTile(
                      title: sub,
                      icon: _SubcategoryIconResolver.resolve(
                        sub,
                        parentCategory: category.name,
                      ),
                      isSelected: selectedSubcategory == sub,
                      accent: accent,
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

class _SubcategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _SubcategoryTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? accent.withValues(alpha: 0.12) : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? accent.withValues(alpha: 0.35)
              : AppColors.surfaceVariant.withValues(alpha: 0.45),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? accent : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: accent, size: 21)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _CategoryIconResolver {
  static IconData resolve(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('food') || name.contains('restaurant') || name.contains('dining')) {
      return Icons.restaurant_rounded;
    }
    if (name.contains('grocer') || name.contains('supermarket') || name.contains('market')) {
      return Icons.local_grocery_store_rounded;
    }
    if (name.contains('grocery') || name.contains('supermarket')) {
      return Icons.shopping_cart_rounded;
    }
    if (name.contains('transport') || name.contains('travel') || name.contains('fuel')) {
      return Icons.directions_car_rounded;
    }
    if (name.contains('shopping') || name.contains('fashion') || name.contains('clothes')) {
      return Icons.shopping_bag_rounded;
    }
    if (name.contains('health') || name.contains('medical') || name.contains('pharmacy')) {
      return Icons.medical_services_rounded;
    }
    if (name.contains('education') || name.contains('study') || name.contains('school')) {
      return Icons.school_rounded;
    }
    if (name.contains('entertainment') || name.contains('movie') || name.contains('fun')) {
      return Icons.movie_rounded;
    }
    if (name.contains('subscription') || name.contains('netflix') || name.contains('spotify')) {
      return Icons.subscriptions_rounded;
    }
    if (name.contains('bill') || name.contains('utility') || name.contains('electric')) {
      return Icons.receipt_long_rounded;
    }
    if (name.contains('phone') || name.contains('mobile') || name.contains('telecom')) {
      return Icons.phone_android_rounded;
    }
    if (name.contains('internet') || name.contains('wifi') || name.contains('broadband')) {
      return Icons.wifi_rounded;
    }
    if (name.contains('salary') || name.contains('income') || name.contains('wage')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (name.contains('business') || name.contains('freelance') || name.contains('project')) {
      return Icons.work_rounded;
    }
    if (name.contains('gift') || name.contains('bonus')) {
      return Icons.card_giftcard_rounded;
    }
    if (name.contains('investment') || name.contains('stock')) {
      return Icons.trending_up_rounded;
    }
    if (name.contains('rent') || name.contains('house') || name.contains('home')) {
      return Icons.home_rounded;
    }
    if (name.contains('loan') || name.contains('emi') || name.contains('debt')) {
      return Icons.account_balance_rounded;
    }
    if (name.contains('insurance')) {
      return Icons.health_and_safety_rounded;
    }
    if (name.contains('tax')) {
      return Icons.request_quote_rounded;
    }
    return Icons.category_rounded;
  }
}

class _SubcategoryIconResolver {
  static IconData resolve(String subcategory, {String? parentCategory}) {
    final name = subcategory.toLowerCase();
    final parent = parentCategory?.toLowerCase() ?? '';

    if (name.contains('breakfast')) return Icons.free_breakfast_rounded;
    if (name.contains('lunch') || name.contains('dinner')) return Icons.ramen_dining_rounded;
    if (name.contains('snack')) return Icons.cookie_rounded;
    if (name.contains('bus')) return Icons.directions_bus_rounded;
    if (name.contains('train') || name.contains('metro')) return Icons.train_rounded;
    if (name.contains('taxi') || name.contains('uber')) return Icons.local_taxi_rounded;
    if (name.contains('petrol') || name.contains('diesel') || name.contains('fuel')) {
      return Icons.local_gas_station_rounded;
    }
    if (name.contains('medicine') || name.contains('doctor')) return Icons.healing_rounded;
    if (name.contains('internet') || name.contains('wifi')) return Icons.wifi_rounded;
    if (name.contains('electric') || name.contains('water')) return Icons.bolt_rounded;
    if (name.contains('phone') || name.contains('mobile')) return Icons.smartphone_rounded;
    if (name.contains('rent')) return Icons.apartment_rounded;
    if (name.contains('salary')) return Icons.payments_rounded;
    if (name.contains('bonus')) return Icons.workspace_premium_rounded;
    if (name.contains('interest') || name.contains('dividend')) return Icons.show_chart_rounded;

    if (parent.contains('food')) return Icons.restaurant_menu_rounded;
    if (parent.contains('transport')) return Icons.route_rounded;
    if (parent.contains('shopping')) return Icons.storefront_rounded;
    if (parent.contains('income') || parent.contains('salary')) return Icons.attach_money_rounded;
    return Icons.label_rounded;
  }
}
