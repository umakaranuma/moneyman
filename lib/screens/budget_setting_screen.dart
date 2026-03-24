import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../services/category_service.dart';
import '../services/budget_service.dart';

class BudgetSettingScreen extends StatefulWidget {
  /// Initial month to show; defaults to current month.
  final DateTime? initialMonth;

  const BudgetSettingScreen({super.key, this.initialMonth});

  @override
  State<BudgetSettingScreen> createState() => _BudgetSettingScreenState();
}

class _BudgetSettingScreenState extends State<BudgetSettingScreen> {
  late int _selectedYear;
  late int _selectedMonth;
  List<Category> _expenseCategories = [];
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _previousAmount = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth ?? DateTime.now();
    _selectedYear = initial.year;
    _selectedMonth = initial.month;
    _loadData();
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final categories =
          CategoryService.getCategories(isIncome: false);
      final existingBudgets =
          BudgetService.getBudgetsForMonth(_selectedYear, _selectedMonth);

      for (var c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
      _previousAmount.clear();

      for (var cat in categories) {
        Budget? budget;
        try {
          budget = existingBudgets.firstWhere((b) => b.category == cat.name);
        } catch (_) {
          budget = null;
        }
        final amount = budget?.amount ?? 0.0;
        _controllers[cat.name] = TextEditingController(
          text: amount > 0 ? amount.toStringAsFixed(0) : '',
        );
        if (budget != null) {
          _previousAmount[cat.name] = budget.id;
        }
      }

      if (mounted) {
        setState(() {
          _expenseCategories = categories;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _expenseCategories = [];
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _budgetId(String category) {
    return '${category}_${_selectedYear}_$_selectedMonth';
  }

  Future<void> _saveBudgets() async {
    setState(() => _saving = true);
    try {
      for (var cat in _expenseCategories) {
        final controller = _controllers[cat.name];
        final text = controller?.text.trim() ?? '';
        final amount = double.tryParse(text) ?? 0.0;
        final id = _budgetId(cat.name);

        if (amount > 0) {
          final budget = Budget(
            id: id,
            category: cat.name,
            amount: amount,
            year: _selectedYear,
            month: _selectedMonth,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await BudgetService.addBudget(budget);
        } else {
          await BudgetService.deleteBudget(id);
        }
      }

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budgets saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _buildModernHeader(),
                  _buildModernMonthSelector(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _expenseCategories.length,
                      itemBuilder: (context, index) {
                        final cat = _expenseCategories[index];
                        return _buildModernBudgetRow(cat);
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : _saveBudgets,
              backgroundColor: AppColors.primary,
              label: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Budgets'),
              icon: const Icon(Icons.check_rounded),
            ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Budget Planner',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Set your monthly limits for $_selectedYear',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMonthSelector() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Year',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: List.generate(5, (i) {
              final y = DateTime.now().year - 2 + i;
              final isSelected = y == _selectedYear;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedYear = y);
                  _loadData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    '$y',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Month',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: 12,
            itemBuilder: (context, index) {
              final monthIndex = index + 1;
              final isSelected = monthIndex == _selectedMonth;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedMonth = monthIndex);
                  _loadData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    _monthNames[index],
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernBudgetRow(Category category) {
    final spent = BudgetService.getSpentForCategory(
      category.name,
      _selectedYear,
      _selectedMonth,
    );

    final controller = _controllers[category.name];
    final amountStr = controller?.text.trim() ?? '';
    final budgetAmount = double.tryParse(amountStr) ?? 0.0;

    final progress =
        budgetAmount > 0 ? (spent / budgetAmount).clamp(0.0, 1.0) : 0.0;

    final remaining = budgetAmount - spent;
    final isOver = remaining < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Top Row
          Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  category.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              /// Budget Input
              SizedBox(
                width: 95,
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor:
                        AppColors.surfaceVariant.withValues(alpha: 0.35),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// Progress + Stats (Compact)
          if (budgetAmount > 0) ...[
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOver ? AppColors.error : AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent ${spent.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  isOver
                      ? 'Over ${remaining.abs().toStringAsFixed(0)}'
                      : 'Left ${remaining.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOver ? AppColors.error : AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

}
