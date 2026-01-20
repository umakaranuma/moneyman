// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import 'categories_screen.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
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
  List<String> _imagePaths = [];
  bool _categoryError = false;
  bool _hasAttemptedSave = false;
  bool _isEditMode = false; // false for view mode, true for edit mode

  @override
  void initState() {
    super.initState();
    // If viewing an existing transaction, start in view mode
    // If creating new transaction, start in edit mode
    _isEditMode = widget.transaction == null;
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
      _imagePaths = List<String>.from(widget.transaction!.imagePaths);

      // Validate category - if it's not in saved categories, reset it
      // This handles SMS transactions with categories like "Bank Transaction" or "Transfer"
      if (_selectedCategory != null &&
          _transactionType != TransactionType.transfer) {
        final isValidCategory =
            CategoryService.getCategoryByName(
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
      _imagePaths = [];
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

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: Text('Take photo', style: GoogleFonts.inter()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text('Choose from gallery', style: GoogleFonts.inter()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImagesFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return;

    final savedPath = await _persistImage(image);
    if (savedPath == null || !mounted) return;

    setState(() {
      _imagePaths.add(savedPath);
    });
  }

  Future<void> _pickImagesFromGallery() async {
    final images = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;

    final savedPaths = <String>[];
    for (final image in images) {
      final savedPath = await _persistImage(image);
      if (savedPath != null) {
        savedPaths.add(savedPath);
      }
    }

    if (!mounted || savedPaths.isEmpty) return;
    setState(() {
      _imagePaths.addAll(savedPaths);
    });
  }

  String _getFileExtension(String path) {
    final index = path.lastIndexOf('.');
    if (index == -1) return '.jpg';
    return path.substring(index);
  }

  Future<String?> _persistImage(XFile image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/transaction_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final extension = _getFileExtension(image.path);
      final filename =
          'txn_${DateTime.now().millisecondsSinceEpoch}_${Helpers.generateId()}$extension';
      final newPath = '${imagesDir.path}/$filename';
      final savedFile = await File(image.path).copy(newPath);
      return savedFile.path;
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add image'),
          backgroundColor: AppColors.expense,
        ),
      );
      return null;
    }
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
    // Load categories from storage (includes custom categories)
    final categories = CategoryService.getCategories(
      isIncome: _transactionType == TransactionType.income,
    );

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
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Close category picker
                            // Navigate to categories screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoriesScreen(
                                  isExpense:
                                      _transactionType ==
                                      TransactionType.expense,
                                ),
                              ),
                            ).then((_) {
                              // Reload categories when returning from categories screen
                              setState(() {
                                // Categories will be reloaded when picker is opened again
                              });
                            });
                          },
                          child: Container(
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
                            _categoryError =
                                false; // Clear error when category is selected
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
    final categories = CategoryService.getCategories(
      isIncome: _transactionType == TransactionType.income,
    );
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
                            _categoryError =
                                false; // Clear error when category is selected
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
                              _categoryError =
                                  false; // Clear error when category is selected
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
    setState(() {
      _hasAttemptedSave = true;
    });

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
      } else {
        // Validate category for Income and Expense transactions
        if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
          setState(() {
            _categoryError = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a category')),
          );
          return;
        }
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
        isBookmarked: widget.transaction?.isBookmarked ?? false,
        imagePaths: List<String>.from(_imagePaths),
      );

      if (widget.transaction != null) {
        await StorageService.updateTransaction(transaction);
      } else {
        await StorageService.addTransaction(transaction);
      }

      // Verify the transaction was saved correctly
      final savedTransaction = StorageService.getTransaction(transaction.id);

      if (savedTransaction == null) {
        // Transaction wasn't saved properly
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save transaction'),
              backgroundColor: AppColors.expense,
            ),
          );
        }
        return;
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.income,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.transaction != null
                      ? 'Transaction updated'
                      : 'Transaction saved',
                  style: GoogleFonts.inter(),
                ),
              ],
            ),
            backgroundColor: AppColors.surface,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Return to previous screen with success indicator
      // This will trigger refresh in home screen
      if (mounted) {
        context.pop(true); // Return true to indicate transaction was saved
      }
    }
  }

  void _saveAndContinue() {
    setState(() {
      _hasAttemptedSave = true;
    });

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
      } else {
        // Validate category for Income and Expense transactions
        if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
          setState(() {
            _categoryError = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a category')),
          );
          return;
        }
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
        imagePaths: List<String>.from(_imagePaths),
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
        _imagePaths = [];
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
          _isEditMode
              ? (widget.transaction != null
                    ? 'Edit Transaction'
                    : 'New Transaction')
              : (widget.transaction!.type == TransactionType.income
                    ? 'Income'
                    : widget.transaction!.type == TransactionType.expense
                    ? 'Expense'
                    : 'Transfer'),
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [],
      ),
      body: _isEditMode
          ? Form(
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
            )
          : _buildViewMode(),
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
        onTap: _isEditMode
            ? () {
                setState(() {
                  _transactionType = type;
                  _categoryError = false; // Clear error when type changes
                  // Reset category when type changes
                  // Also validate if current category is valid for new type
                  if (_selectedCategory != null &&
                      type != TransactionType.transfer) {
                    final isValidCategory =
                        CategoryService.getCategoryByName(
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
              }
            : null, // Disable tap in view mode
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
                Builder(
                  builder: (context) {
                    final padding = _getResponsivePadding(context);
                    final showError = _categoryError && _hasAttemptedSave;
                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: showError ? padding * 0.3 : 0,
                        vertical: showError ? padding * 0.3 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: showError
                            ? AppColors.expense.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(padding * 0.75),
                        border: Border.all(
                          color: showError
                              ? AppColors.expense
                              : Colors.transparent,
                          width: showError ? 1.5 : 0,
                        ),
                      ),
                      child: _buildDetailRow(
                        icon: Icons.category_rounded,
                        label: 'Category',
                        value: _selectedCategory != null
                            ? (_selectedSubcategory != null
                                  ? '$_selectedCategory • $_selectedSubcategory'
                                  : _selectedCategory!)
                            : 'Select category',
                        valueColor: _selectedCategory != null
                            ? _activeColor
                            : (showError ? AppColors.expense : null),
                        emoji: _selectedCategory != null
                            ? CategoryService.getCategoryEmoji(
                                _selectedCategory,
                                isIncome:
                                    _transactionType == TransactionType.income,
                              )
                            : null,
                        onTap: _showCategoryPicker,
                        hasError: showError,
                      ),
                    );
                  },
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
              if (_imagePaths.isNotEmpty) ...[
                Container(
                  height: 1,
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                ),
                _buildAttachmentsRow(
                  imagePaths: _imagePaths,
                  editable: true,
                ),
              ],
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
    bool hasError = false,
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
                          color: hasError
                              ? AppColors.expense.withValues(alpha: 0.1)
                              : _activeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(padding * 0.5),
                        ),
                        child: Icon(
                          icon,
                          color: hasError ? AppColors.expense : _activeColor,
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
                              color: hasError
                                  ? AppColors.expense
                                  : AppColors.textMuted,
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
                                    color: hasError
                                        ? AppColors.expense
                                        : (valueColor ?? AppColors.textPrimary),
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
                          if (hasError)
                            Padding(
                              padding: EdgeInsets.only(top: padding * 0.4),
                              child: Text(
                                'Category is required',
                                style: GoogleFonts.inter(
                                  color: AppColors.expense,
                                  fontSize: _getResponsiveFontSize(context, 11),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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

  Widget _buildAttachmentsRow({
    required List<String> imagePaths,
    required bool editable,
  }) {
    if (imagePaths.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _activeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.image_rounded, color: _activeColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attachments',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imagePaths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final path = imagePaths[index];
                      return _buildAttachmentThumbnail(
                        path,
                        removable: editable,
                        onRemove: () {
                          setState(() {
                            _imagePaths.removeAt(index);
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentThumbnail(
    String path, {
    required bool removable,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: () => _showImagePreview(path),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(path),
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.broken_image_rounded),
              ),
            ),
          ),
          if (removable)
            Positioned(
              right: -6,
              top: -6,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.cancel_rounded, size: 18),
                color: AppColors.expense,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
        ],
      ),
    );
  }

  void _showImagePreview(String path) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(24),
                child: const Icon(Icons.broken_image_rounded, size: 48),
              ),
            ),
          ),
        );
      },
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
                onTap: _showImageSourceSheet,
                child: Container(
                  padding: EdgeInsets.all(padding * 0.6),
                  decoration: BoxDecoration(
                    color: _imagePaths.isNotEmpty
                        ? _activeColor.withValues(alpha: 0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(padding * 0.6),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color:
                        _imagePaths.isNotEmpty ? _activeColor : AppColors.textMuted,
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

  Widget _buildViewMode() {
    if (widget.transaction == null) return const SizedBox.shrink();

    final transaction = widget.transaction!;
    final dateStr = DateFormat('MMM dd, yyyy').format(transaction.date);
    final timeStr = DateFormat('h:mm a').format(transaction.date);
    final emoji = CategoryService.getCategoryEmoji(
      transaction.category,
      isIncome: transaction.type == TransactionType.income,
    );

    return Column(
      children: [
        // Transaction Type Selector (tappable to edit)
        GestureDetector(
          onTap: () {
            setState(() {
              _isEditMode = true;
            });
          },
          child: Builder(
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
          ),
        ),

        Expanded(
          child: Builder(
            builder: (context) {
              final padding = _getResponsivePadding(context);
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    // Amount Card (read-only)
                    _buildViewAmountCard(transaction),
                    SizedBox(height: padding),

                    // Details Card (read-only)
                    _buildViewDetailsCard(transaction, dateStr, timeStr, emoji),
                    SizedBox(height: padding),

                    // Transfer specific fields
                    if (transaction.type == TransactionType.transfer)
                      _buildViewTransferCard(transaction),

                    // Description Card (read-only)
                    _buildViewDescriptionCard(transaction),
                    SizedBox(height: padding * 1.5),

                    // Action Buttons (Copy, Bookmark, Delete)
                    _buildActionButtons(transaction),
                    SizedBox(height: padding * 2),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewAmountCard(Transaction transaction) {
    return Builder(
      builder: (context) {
        final padding = _getResponsivePadding(context);
        final typeColor = _getTypeColor(transaction.type);
        return GestureDetector(
          onTap: () {
            setState(() {
              _isEditMode = true;
            });
          },
          child: Container(
            padding: EdgeInsets.all(padding * 1.2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  typeColor.withValues(alpha: 0.15),
                  typeColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(padding * 1.2),
              border: Border.all(
                color: typeColor.withValues(alpha: 0.2),
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
                            color: typeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(padding * 0.5),
                          ),
                          child: Icon(
                            transaction.type == TransactionType.income
                                ? Icons.arrow_downward_rounded
                                : transaction.type == TransactionType.expense
                                ? Icons.arrow_upward_rounded
                                : Icons.swap_horiz_rounded,
                            color: typeColor,
                            size: _getResponsiveSize(context, 16),
                          ),
                        ),
                      ),
                      SizedBox(width: padding * 0.4),
                      Text(
                        'Amount',
                        style: GoogleFonts.inter(
                          color: typeColor,
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
                      color: typeColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Rs. ',
                        style: GoogleFonts.inter(
                          color: typeColor,
                          fontSize: _getResponsiveFontSize(context, 20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatCurrency(transaction.amount),
                        style: GoogleFonts.inter(
                          color: typeColor,
                          fontSize: _getResponsiveFontSize(context, 32),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewDetailsCard(
    Transaction transaction,
    String dateStr,
    String timeStr,
    String emoji,
  ) {
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
              _buildViewDetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: '$dateStr  •  $timeStr',
              ),
              Container(
                height: 1,
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              ),

              // Category (only show for Income and Expense, not for Transfer)
              if (transaction.type != TransactionType.transfer) ...[
                _buildViewDetailRow(
                  icon: Icons.category_rounded,
                  label: 'Category',
                  value: transaction.category ?? 'N/A',
                  emoji: emoji.isNotEmpty ? emoji : null,
                ),
                Container(
                  height: 1,
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                ),
              ],

              // Account
              _buildViewDetailRow(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Account',
                value: _getAccountLabel(transaction.accountType),
              ),
              Container(
                height: 1,
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              ),

              // Note
              _buildViewNoteRow(transaction),
              if (transaction.imagePaths.isNotEmpty) ...[
                Container(
                  height: 1,
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                ),
                _buildAttachmentsRow(
                  imagePaths: transaction.imagePaths,
                  editable: false,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewDetailRow({
    required IconData icon,
    required String label,
    required String value,
    String? emoji,
    VoidCallback? onTap,
  }) {
    return Builder(
      builder: (context) {
        final padding = _getResponsivePadding(context);
        final typeColor = widget.transaction != null
            ? _getTypeColor(widget.transaction!.type)
            : AppColors.primary;
        return GestureDetector(
          onTap:
              onTap ??
              () {
                setState(() {
                  _isEditMode = true;
                });
              },
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                SizedBox(
                  width: _getResponsiveSize(context, 16) + padding * 1.0,
                  height: _getResponsiveSize(context, 16) + padding * 1.0,
                  child: Container(
                    padding: EdgeInsets.all(padding * 0.5),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(padding * 0.5),
                    ),
                    child: Icon(
                      icon,
                      color: typeColor,
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
                                fontSize: _getResponsiveFontSize(context, 16),
                              ),
                            ),
                            SizedBox(width: padding * 0.375),
                          ],
                          Expanded(
                            child: Text(
                              value,
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: _getResponsiveFontSize(context, 14),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewNoteRow(Transaction transaction) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditMode = true;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getTypeColor(transaction.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.note_rounded,
                color: _getTypeColor(transaction.type),
                size: 18,
              ),
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
                    width: double.infinity,
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
                    child: Text(
                      transaction.note ?? 'No note',
                      style: GoogleFonts.inter(
                        color: transaction.note != null
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewTransferCard(Transaction transaction) {
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
              _buildViewTransferField(
                'From Account',
                transaction.fromAccount ?? 'N/A',
              ),
              Container(
                height: 1,
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              ),
              _buildViewTransferField(
                'To Account',
                transaction.toAccount ?? 'N/A',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewTransferField(String label, String value) {
    return Builder(
      builder: (context) {
        final padding = _getResponsivePadding(context);
        return GestureDetector(
          onTap: () {
            setState(() {
              _isEditMode = true;
            });
          },
          child: Padding(
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
                      Text(
                        value,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: _getResponsiveFontSize(context, 13),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewDescriptionCard(Transaction transaction) {
    return Builder(
      builder: (context) {
        final padding = _getResponsivePadding(context);
        return GestureDetector(
          onTap: () {
            setState(() {
              _isEditMode = true;
            });
          },
          child: Container(
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
                    color: _getTypeColor(
                      transaction.type,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(padding * 0.6),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: _getTypeColor(transaction.type),
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
                      Text(
                        transaction.title,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: _getResponsiveFontSize(context, 13),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(Transaction transaction) {
    return Builder(
      builder: (context) {
        final padding = _getResponsivePadding(context);
        return Row(
          children: [
            // Delete Button
            Expanded(
              child: GestureDetector(
                onTap: () => _showDeleteConfirmation(transaction),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: padding * 1.1),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(padding * 1.0),
                    border: Border.all(
                      color: AppColors.expense.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.expense,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Delete',
                        style: GoogleFonts.inter(
                          color: AppColors.expense,
                          fontSize: _getResponsiveFontSize(context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: padding * 0.75),
            // Copy Button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final transactionText =
                      '${transaction.title}\n'
                      'Rs. ${_formatCurrency(transaction.amount)}\n'
                      '${DateFormat('MMM dd, yyyy - hh:mm a').format(transaction.date)}\n'
                      '${transaction.category ?? 'N/A'}';
                  Clipboard.setData(ClipboardData(text: transactionText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Transaction copied',
                            style: GoogleFonts.inter(),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.surface,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: padding * 1.1),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(padding * 1.0),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Copy',
                        style: GoogleFonts.inter(
                          color: AppColors.secondary,
                          fontSize: _getResponsiveFontSize(context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: padding * 0.75),
            // Bookmark Button
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final updatedTransaction = Transaction(
                    id: transaction.id,
                    title: transaction.title,
                    amount: transaction.amount,
                    type: transaction.type,
                    date: transaction.date,
                    category: transaction.category,
                    note: transaction.note,
                    accountType: transaction.accountType,
                    fromAccount: transaction.fromAccount,
                    toAccount: transaction.toAccount,
                    isBookmarked: !transaction.isBookmarked,
                    imagePaths: transaction.imagePaths,
                  );
                  await StorageService.updateTransaction(updatedTransaction);
                  setState(() {
                    widget.transaction!.isBookmarked =
                        !transaction.isBookmarked;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.income,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            transaction.isBookmarked
                                ? 'Bookmark removed'
                                : 'Transaction bookmarked',
                            style: GoogleFonts.inter(),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.surface,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: padding * 1.1),
                  decoration: BoxDecoration(
                    color: transaction.isBookmarked
                        ? AppColors.income.withValues(alpha: 0.15)
                        : AppColors.income.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(padding * 1.0),
                    border: Border.all(
                      color: AppColors.income.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        transaction.isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: AppColors.income,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bookmark',
                        style: GoogleFonts.inter(
                          color: AppColors.income,
                          fontSize: _getResponsiveFontSize(context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Transaction',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await StorageService.deleteTransaction(transaction.id);
              Navigator.pop(context);
              if (mounted) {
                context.pop(true);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.expense.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: AppColors.expense,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00').format(amount);
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
