// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  final TransactionType? initialType;

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
    this.initialType,
  });

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TransactionType _transactionType;
  AccountType _accountType = AccountType.bank;
  String? _selectedCategory;
  String? _selectedSubcategory;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _fromAccount;
  String? _toAccount;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _titleController = TextEditingController(text: widget.transaction!.title);
      _amountController = TextEditingController(
        text: widget.transaction!.amount.toString(),
      );
      _noteController = TextEditingController(
        text: widget.transaction!.note ?? '',
      );
      _transactionType = widget.transaction!.type;
      _accountType = widget.transaction!.accountType;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = widget.transaction!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.transaction!.date);
      _fromAccount = widget.transaction!.fromAccount;
      _toAccount = widget.transaction!.toAccount;

      // Validate category - if it's not in default categories, reset it
      // This handles SMS transactions with categories like "Bank Transaction" or "Transfer"
      if (_selectedCategory != null &&
          _transactionType != TransactionType.transfer) {
        final isValidCategory =
            DefaultCategories.getCategoryByName(
              _selectedCategory!,
              isIncome: _transactionType == TransactionType.income,
            ) !=
            null;

        if (!isValidCategory) {
          // Category is not in default list (e.g., "Bank Transaction"), reset it
          _selectedCategory = null;
          _selectedSubcategory = null;
        }
      } else if (_transactionType == TransactionType.transfer) {
        // Transfers don't need categories
        _selectedCategory = null;
        _selectedSubcategory = null;
      }
    } else {
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _transactionType = widget.initialType ?? TransactionType.expense;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Dynamic color based on transaction type
  Color get _activeColor => _getTypeColor(_transactionType);

  // Type colors: Blue for Income, Orange-Red for Expense, Light Blue for Transfer
  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.income; // Blue
      case TransactionType.expense:
        return AppColors.primary; // Orange-Red (Premium Color)
      case TransactionType.transfer:
        return AppColors.secondary; // Light Blue
    }
  }

  // Responsive sizing helpers
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Use screen width for scaling, similar to font size
    final scaleFactor = screenWidth / 360.0; // Base on 360 width
    final scaled =
        baseSize *
        (scaleFactor < 0.8 ? 0.8 : (scaleFactor > 1.3 ? 1.3 : scaleFactor));
    // Ensure minimum and maximum bounds
    return scaled.clamp(baseSize * 0.8, baseSize * 1.3);
  }

  double _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Base padding 12, scale between 10-16 based on screen width (reduced for compact UI)
    return screenWidth < 360 ? 10.0 : (screenWidth > 420 ? 16.0 : 12.0);
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 360.0; // Base on 360 width
    // Reduced scaling for more compact UI (0.85 to 1.1 instead of 0.9 to 1.2)
    return baseSize *
        (scaleFactor < 0.85 ? 0.85 : (scaleFactor > 1.1 ? 1.1 : scaleFactor));
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _activeColor,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _activeColor,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _showCategoryPicker() {
    final categories = _transactionType == TransactionType.income
        ? DefaultCategories.incomeCategories
        : DefaultCategories.expenseCategories;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final bottomSheetHeight = screenHeight * 0.7;
        return Container(
          height: bottomSheetHeight,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.85,
            minHeight: screenHeight * 0.5,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(_getResponsiveSize(context, 28)),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
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
                          _transactionType == TransactionType.income
                              ? 'Choose your income source'
                              : 'Choose your expense category',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(height: 1, color: AppColors.surfaceVariant),

              // Categories List with colorful icons
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final hasSubcategories = category.subcategories.isNotEmpty;
                    final isSelected = _selectedCategory == category.name;
                    // Use vibrant color from categoryColors
                    final categoryColor =
                        AppColors.categoryColors[index %
                            AppColors.categoryColors.length];

                    return GestureDetector(
                      onTap: () {
                        if (hasSubcategories) {
                          _showSubcategoryPicker(category);
                        } else {
                          setState(() {
                            _selectedCategory = category.name;
                            _selectedSubcategory = null;
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    categoryColor.withValues(alpha: 0.15),
                                    categoryColor.withValues(alpha: 0.05),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected
                              ? Border.all(
                                  color: categoryColor.withValues(alpha: 0.4),
                                  width: 1,
                                )
                              : Border.all(
                                  color: categoryColor.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                        ),
                        child: Row(
                          children: [
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
                                    blurRadius: 6,
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
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (hasSubcategories)
                                    Text(
                                      '${category.subcategories.length} subcategories',
                                      style: GoogleFonts.inter(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (hasSubcategories)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: categoryColor,
                                  size: 18,
                                ),
                              ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      categoryColor,
                                      categoryColor.withValues(alpha: 0.8),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
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

  void _showSubcategoryPicker(Category category) {
    // Find parent category index for color
    final categories = _transactionType == TransactionType.income
        ? DefaultCategories.incomeCategories
        : DefaultCategories.expenseCategories;
    final categoryIndex = categories.indexWhere((c) => c.id == category.id);
    final categoryColor = AppColors
        .categoryColors[categoryIndex % AppColors.categoryColors.length];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Container(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.75,
            minHeight: screenHeight * 0.4,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(_getResponsiveSize(context, 28)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            categoryColor,
                            categoryColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: category.emoji.isNotEmpty
                          ? Text(
                              category.emoji,
                              style: const TextStyle(fontSize: 18),
                            )
                          : const Icon(
                              Icons.category_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category.name,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.surfaceVariant),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Select main category option
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category.name;
                            _selectedSubcategory = null;
                          });
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                categoryColor.withValues(alpha: 0.12),
                                categoryColor.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: categoryColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      categoryColor,
                                      categoryColor.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: category.emoji.isNotEmpty
                                      ? Text(
                                          category.emoji,
                                          style: const TextStyle(fontSize: 18),
                                        )
                                      : const Icon(
                                          Icons.category_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'All ${category.name}',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: categoryColor,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Subcategories with colorful styling
                      ...category.subcategories.asMap().entries.map((entry) {
                        final subIndex = entry.key;
                        final sub = entry.value;
                        final subColor =
                            AppColors.categoryColors[(categoryIndex +
                                    subIndex +
                                    1) %
                                AppColors.categoryColors.length];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category.name;
                              _selectedSubcategory = sub;
                            });
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: subColor.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: subColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: subColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    sub,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAccountPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Account',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...AccountType.values.map((type) {
                String label;
                IconData icon;
                List<Color> gradient;

                switch (type) {
                  case AccountType.cash:
                    label = 'Cash';
                    icon = Icons.payments_rounded;
                    gradient = [
                      AppColors.income,
                      AppColors.income.withValues(alpha: 0.7),
                    ];
                    break;
                  case AccountType.card:
                    label = 'Card';
                    icon = Icons.credit_card_rounded;
                    gradient = [AppColors.secondary, AppColors.primary];
                    break;
                  case AccountType.bank:
                    label = 'Bank Account';
                    icon = Icons.account_balance_rounded;
                    gradient = [AppColors.primary, AppColors.primaryLight];
                    break;
                  case AccountType.other:
                    label = 'Other';
                    icon = Icons.account_circle_rounded;
                    gradient = [
                      AppColors.textMuted,
                      AppColors.textMuted.withValues(alpha: 0.7),
                    ];
                    break;
                }

                final isSelected = _accountType == type;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _accountType = type;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                gradient[0].withValues(alpha: 0.15),
                                gradient[0].withValues(alpha: 0.05),
                              ],
                            )
                          : null,
                      color: isSelected ? null : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(
                              color: gradient[0].withValues(alpha: 0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradient),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: gradient[0],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_transactionType == TransactionType.transfer) {
        if (_fromAccount == null ||
            _fromAccount!.trim().isEmpty ||
            _toAccount == null ||
            _toAccount!.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please enter both From and To accounts for transfer',
              ),
            ),
          );
          return;
        }
      }

      // Category is required for income and expense transactions
      if (_transactionType != TransactionType.transfer &&
          (_selectedCategory == null || _selectedCategory!.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      final transaction = Transaction(
        id: widget.transaction?.id ?? Helpers.generateId(),
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        type: _transactionType,
        date: _selectedDate,
        category: _selectedCategory,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        accountType: _accountType,
        fromAccount: _transactionType == TransactionType.transfer
            ? _fromAccount?.trim()
            : null,
        toAccount: _transactionType == TransactionType.transfer
            ? _toAccount?.trim()
            : null,
      );

      if (widget.transaction != null) {
        await StorageService.updateTransaction(transaction);
      } else {
        await StorageService.addTransaction(transaction);
      }

      // Verify the transaction was saved correctly
      StorageService.getTransaction(transaction.id);

      context.pop(true); // Return true to indicate transaction was saved
    }
  }

  void _saveAndContinue() {
    if (_formKey.currentState!.validate()) {
      if (_transactionType == TransactionType.transfer) {
        if (_fromAccount == null ||
            _fromAccount!.trim().isEmpty ||
            _toAccount == null ||
            _toAccount!.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please enter both From and To accounts for transfer',
              ),
            ),
          );
          return;
        }
      }

      // Category is required for income and expense transactions
      if (_transactionType != TransactionType.transfer &&
          (_selectedCategory == null || _selectedCategory!.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      final transaction = Transaction(
        id: Helpers.generateId(),
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        type: _transactionType,
        date: _selectedDate,
        category: _selectedCategory,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        accountType: _accountType,
        fromAccount: _transactionType == TransactionType.transfer
            ? _fromAccount?.trim()
            : null,
        toAccount: _transactionType == TransactionType.transfer
            ? _toAccount?.trim()
            : null,
      );

      StorageService.addTransaction(transaction);

      // Clear fields for next entry
      setState(() {
        _titleController.clear();
        _amountController.clear();
        _noteController.clear();
        _selectedCategory = null;
        _selectedSubcategory = null;
        _fromAccount = null;
        _toAccount = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              const Text('Transaction saved'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.surface,
        ),
      );
    }
  }

  String _getAccountLabel(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.card:
        return 'Card';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(_selectedDate);
    final timeStr = DateFormat('h:mm a').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        title: Text(
          widget.transaction != null ? 'Edit Transaction' : 'New Transaction',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.download_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Transaction Type Selector
            _buildTypeSelector(),

            Expanded(
              child: Builder(
                builder: (context) {
                  final padding = _getResponsivePadding(context);
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      children: [
                        // Amount Card
                        _buildAmountCard(),
                        SizedBox(height: padding),

                        // Details Card
                        _buildDetailsCard(dateStr, timeStr),
                        SizedBox(height: padding),

                        // Transfer specific fields
                        if (_transactionType == TransactionType.transfer)
                          _buildTransferCard(),

                        // Description Card
                        _buildDescriptionCard(),
                        SizedBox(height: padding * 1.5),

                        // Save Buttons
                        _buildSaveButtons(),
                        SizedBox(height: padding * 2),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Builder(
      builder: (context) {
        final padding = _getResponsivePadding(context);
        return Container(
          margin: EdgeInsets.all(padding * 0.8),
          padding: EdgeInsets.all(padding * 0.2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(padding * 0.8),
            border: Border.all(color: AppColors.surfaceVariant, width: 1),
          ),
          child: Row(
            children: [
              _buildTypeButton(
                'Income',
                TransactionType.income,
                _getTypeColor(TransactionType.income),
              ),
              _buildTypeButton(
                'Expense',
                TransactionType.expense,
                _getTypeColor(TransactionType.expense),
              ),
              _buildTypeButton(
                'Transfer',
                TransactionType.transfer,
                _getTypeColor(TransactionType.transfer),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeButton(String label, TransactionType type, Color color) {
    final isSelected = _transactionType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _transactionType = type;
            // Reset category when type changes
            // Also validate if current category is valid for new type
            if (_selectedCategory != null && type != TransactionType.transfer) {
              final isValidCategory =
                  DefaultCategories.getCategoryByName(
                    _selectedCategory!,
                    isIncome: type == TransactionType.income,
                  ) !=
                  null;

              if (!isValidCategory) {
                // Category is not valid for new type, reset it
                _selectedCategory = null;
                _selectedSubcategory = null;
              }
            } else {
              // Transfer type or no category - reset
              _selectedCategory = null;
              _selectedSubcategory = null;
            }
          });
        },
        child: Builder(
          builder: (context) {
            final padding = _getResponsivePadding(context);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(vertical: padding * 0.6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [color, color.withValues(alpha: 0.8)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(padding * 0.6),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontSize: _getResponsiveFontSize(context, 13),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Builder(
      builder: (context) {
        final padding = _getResponsivePadding(context);
        return Container(
          padding: EdgeInsets.all(padding * 1.2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _activeColor.withValues(alpha: 0.15),
                _activeColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(padding * 1.2),
            border: Border.all(
              color: _activeColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: _getResponsiveSize(context, 16) + padding * 0.8,
                      height: _getResponsiveSize(context, 16) + padding * 0.8,
                      child: Container(
                        padding: EdgeInsets.all(padding * 0.4),
                        decoration: BoxDecoration(
                          color: _activeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(padding * 0.5),
                        ),
                        child: Icon(
                          _transactionType == TransactionType.income
                              ? Icons.arrow_downward_rounded
                              : _transactionType == TransactionType.expense
                              ? Icons.arrow_upward_rounded
                              : Icons.swap_horiz_rounded,
                          color: _activeColor,
                          size: _getResponsiveSize(context, 16),
                        ),
                      ),
                    ),
                    SizedBox(width: padding * 0.4),
                    Text(
                      'Amount',
                      style: GoogleFonts.inter(
                        color: _activeColor,
                        fontSize: _getResponsiveFontSize(context, 13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: padding * 0.8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: padding * 1.0,
                  vertical: padding * 0.8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(padding),
                  border: Border.all(
                    color: _activeColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rs. ',
                      style: GoogleFonts.inter(
                        color: _activeColor,
                        fontSize: _getResponsiveFontSize(context, 20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        style: GoogleFonts.inter(
                          color: _activeColor,
                          fontSize: _getResponsiveFontSize(context, 32),
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: GoogleFonts.inter(
                            color: _activeColor.withValues(alpha: 0.3),
                            fontSize: _getResponsiveFontSize(context, 32),
                            fontWeight: FontWeight.w700,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        textAlign: TextAlign.center,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value.trim()) == null ||
                              double.parse(value.trim()) <= 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailsCard(String dateStr, String timeStr) {
    return Builder(
      builder: (context) {
        final padding = _getResponsivePadding(context);
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(padding * 1.0),
            border: Border.all(color: AppColors.surfaceVariant, width: 1),
          ),
          child: Column(
            children: [
              // Date & Time
              _buildDetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Date & Time',
                value: '$dateStr  •  $timeStr',
                onTap: () async {
                  await _selectDate();
                  await _selectTime();
                },
              ),
              Container(
                height: 1,
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              ),

              // Category (only show for Income and Expense, not for Transfer)
              if (_transactionType != TransactionType.transfer) ...[
                _buildDetailRow(
                  icon: Icons.category_rounded,
                  label: 'Category *',
                  value: _selectedCategory != null
                      ? (_selectedSubcategory != null
                            ? '$_selectedCategory • $_selectedSubcategory'
                            : _selectedCategory!)
                      : 'Select category (Required)',
                  valueColor: _selectedCategory != null
                      ? _activeColor
                      : AppColors.expense,
                  emoji: _selectedCategory != null
                      ? DefaultCategories.getCategoryEmoji(
                          _selectedCategory,
                          isIncome: _transactionType == TransactionType.income,
                        )
                      : null,
                  onTap: _showCategoryPicker,
                ),
                Container(
                  height: 1,
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                ),
              ],

              // Account
              _buildDetailRow(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Account',
                value: _getAccountLabel(_accountType),
                onTap: _showAccountPicker,
              ),
              Container(
                height: 1,
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              ),

              // Note
              _buildNoteRow(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    String? emoji,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final padding = _getResponsivePadding(context);
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    SizedBox(
                      width: _getResponsiveSize(context, 16) + padding * 1.0,
                      height: _getResponsiveSize(context, 16) + padding * 1.0,
                      child: Container(
                        padding: EdgeInsets.all(padding * 0.5),
                        decoration: BoxDecoration(
                          color: _activeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(padding * 0.5),
                        ),
                        child: Icon(
                          icon,
                          color: _activeColor,
                          size: _getResponsiveSize(context, 16),
                        ),
                      ),
                    ),
                    SizedBox(width: padding * 0.875),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: _getResponsiveFontSize(context, 11),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (emoji != null && emoji.isNotEmpty) ...[
                                Text(
                                  emoji,
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      16,
                                    ),
                                  ),
                                ),
                                SizedBox(width: padding * 0.375),
                              ],
                              Expanded(
                                child: Text(
                                  value,
                                  style: GoogleFonts.inter(
                                    color: valueColor ?? AppColors.textPrimary,
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      14,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: padding * 0.4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: _getResponsiveSize(context, 18),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _activeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.note_rounded, color: _activeColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Note',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.surfaceVariant,
                      width: 1,
                    ),
                  ),
                  child: TextFormField(
                    controller: _noteController,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText: 'Add a note',
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferCard() {
    return Builder(
      builder: (context) {
        final padding = _getResponsivePadding(context);
        return Container(
          margin: EdgeInsets.only(bottom: padding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(padding * 1.0),
            border: Border.all(color: AppColors.surfaceVariant, width: 1),
          ),
          child: Column(
            children: [
              _buildTransferField('From Account', _fromAccount, (value) {
                _fromAccount = value;
              }),
              Container(
                height: 1,
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              ),
              _buildTransferField('To Account', _toAccount, (value) {
                _toAccount = value;
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransferField(
    String label,
    String? value,
    Function(String) onChanged,
  ) {
    return Builder(
      builder: (context) {
        final padding = _getResponsivePadding(context);
        return Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(padding * 0.6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(padding * 0.6),
                ),
                child: Icon(
                  label.startsWith('From')
                      ? Icons.arrow_circle_up_rounded
                      : Icons.arrow_circle_down_rounded,
                  color: AppColors.secondary,
                  size: _getResponsiveSize(context, 16),
                ),
              ),
              SizedBox(width: padding * 0.875),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: _getResponsiveFontSize(context, 11),
                      ),
                    ),
                    SizedBox(height: padding * 0.3),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: padding * 0.7,
                        vertical: padding * 0.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(padding * 0.75),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: TextFormField(
                        initialValue: value,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: _getResponsiveFontSize(context, 13),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          hintText: 'Enter $label',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: _getResponsiveFontSize(context, 13),
                            fontWeight: FontWeight.w400,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescriptionCard() {
    return Builder(
      builder: (context) {
        final padding = _getResponsivePadding(context);
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(padding * 1.0),
            border: Border.all(color: AppColors.surfaceVariant, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(padding * 0.6),
                decoration: BoxDecoration(
                  color: _activeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(padding * 0.6),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: _activeColor,
                  size: _getResponsiveSize(context, 16),
                ),
              ),
              SizedBox(width: padding * 0.875),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: _getResponsiveFontSize(context, 11),
                      ),
                    ),
                    SizedBox(height: padding * 0.4),
                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: _getResponsiveFontSize(context, 13),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: padding * 0.75,
                          vertical: padding * 0.6,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(padding * 0.75),
                          borderSide: BorderSide(
                            color: _activeColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(padding * 0.75),
                          borderSide: BorderSide(
                            color: _activeColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(padding * 0.75),
                          borderSide: BorderSide(
                            color: _activeColor,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(padding * 0.75),
                          borderSide: BorderSide(
                            color: AppColors.expense,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(padding * 0.75),
                          borderSide: BorderSide(
                            color: AppColors.expense,
                            width: 1.5,
                          ),
                        ),
                        hintText: 'What was this for?',
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: _getResponsiveFontSize(context, 13),
                          fontWeight: FontWeight.w400,
                        ),
                        isDense: true,
                        errorStyle: GoogleFonts.inter(
                          color: AppColors.expense,
                          fontSize: _getResponsiveFontSize(context, 11),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: padding * 0.5),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.all(padding * 0.6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(padding * 0.6),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.textMuted,
                    size: _getResponsiveSize(context, 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveButtons() {
    return Builder(
      builder: (context) {
        final padding = _getResponsivePadding(context);
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _saveTransaction,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: padding * 1.1),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _activeColor,
                        _activeColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(padding * 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: _activeColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Save Transaction',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: _getResponsiveFontSize(context, 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: padding * 0.75),
            Expanded(
              child: GestureDetector(
                onTap: _saveAndContinue,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: padding * 1.1),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(padding * 1.0),
                    border: Border.all(
                      color: _activeColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Save +',
                      style: GoogleFonts.inter(
                        color: _activeColor,
                        fontSize: _getResponsiveFontSize(context, 13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
