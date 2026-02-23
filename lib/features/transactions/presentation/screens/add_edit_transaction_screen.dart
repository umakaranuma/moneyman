// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/transaction.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/category_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/helpers.dart';
import '../../../../screens/categories_screen.dart';
import '../../../../screens/calculator_screen.dart';

import '../widgets/transaction_type_selector.dart';
import '../widgets/amount_section.dart';
import '../widgets/transaction_details_section.dart';
import '../widgets/transfer_section.dart';
import '../widgets/description_section.dart';
import '../widgets/attachment_section.dart';
import '../widgets/save_buttons.dart';
import '../bottom_sheets/account_picker_sheet.dart';
import '../bottom_sheets/category_picker_sheet.dart';

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
  late TransactionType _type;
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

  Color get _activeColor {
    switch (_type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.primary;
      case TransactionType.transfer:
        return AppColors.secondary;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _titleController = TextEditingController(text: t.title);
      _amountController = TextEditingController(text: t.amount.toString());
      _noteController = TextEditingController(text: t.note ?? '');
      _type = t.type;
      _accountType = t.accountType;
      _selectedCategory = t.category;
      _selectedDate = t.date;
      _selectedTime = TimeOfDay.fromDateTime(t.date);
      _fromAccount = t.fromAccount;
      _toAccount = t.toAccount;
      _imagePaths = List<String>.from(t.imagePaths);

      if (_selectedCategory != null && _type != TransactionType.transfer) {
        final valid = CategoryService.getCategoryByName(
          _selectedCategory!,
          isIncome: _type == TransactionType.income,
        ) != null;
        if (!valid) {
          _selectedCategory = null;
          _selectedSubcategory = null;
        }
      } else if (_type == TransactionType.transfer) {
        _selectedCategory = null;
        _selectedSubcategory = null;
      }
    } else {
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _type = widget.initialType ?? TransactionType.expense;
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

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      _categoryError = false;
      if (_selectedCategory != null && type != TransactionType.transfer) {
        final valid = CategoryService.getCategoryByName(
          _selectedCategory!,
          isIncome: type == TransactionType.income,
        ) != null;
        if (!valid) {
          _selectedCategory = null;
          _selectedSubcategory = null;
        }
      } else {
        _selectedCategory = null;
        _selectedSubcategory = null;
      }
    });
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CategoryPickerSheet(
        isIncome: _type == TransactionType.income,
        selectedCategory: _selectedCategory,
        selectedSubcategory: _selectedSubcategory,
        onSelected: (category, subcategory) {
          setState(() {
            _selectedCategory = category;
            _selectedSubcategory = subcategory;
            _categoryError = false;
          });
        },
        onManageCategories: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoriesScreen(
                isExpense: _type == TransactionType.expense,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAccountPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AccountPickerSheet(
        selected: _accountType,
        onSelected: (type) => setState(() => _accountType = type),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
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
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text('Take photo', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text('Choose from gallery', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final images = await _imagePicker.pickMultiImage(imageQuality: 85);
      for (final x in images) {
        final path = await _persistImage(x);
        if (path != null && mounted) setState(() => _imagePaths.add(path));
      }
    } else {
      final x = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (x != null) {
        final path = await _persistImage(x);
        if (path != null && mounted) setState(() => _imagePaths.add(path));
      }
    }
  }

  Future<String?> _persistImage(XFile file) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${dir.path}/transaction_images');
      if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
      final ext = file.path.lastIndexOf('.') >= 0
          ? file.path.substring(file.path.lastIndexOf('.'))
          : '.jpg';
      final path = '${imagesDir.path}/txn_${DateTime.now().millisecondsSinceEpoch}_${Helpers.generateId()}$ext';
      await File(file.path).copy(path);
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openCalculator() async {
    final current = _amountController.text.trim();
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CalculatorScreen(
          initialValue: current.isEmpty ? null : current,
        ),
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _amountController.text = result);
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

  Future<void> _saveTransaction() async {
    setState(() => _hasAttemptedSave = true);

    if (!_formKey.currentState!.validate()) return;

    if (_type == TransactionType.transfer) {
      if (_fromAccount == null || _fromAccount!.trim().isEmpty ||
          _toAccount == null || _toAccount!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter both From and To accounts')),
        );
        return;
      }
    } else {
      if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
        setState(() => _categoryError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }
    }

    final t = Transaction(
      id: widget.transaction?.id ?? Helpers.generateId(),
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      type: _type,
      date: _selectedDate,
      category: _selectedCategory,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      accountType: _accountType,
      fromAccount: _type == TransactionType.transfer ? _fromAccount?.trim() : null,
      toAccount: _type == TransactionType.transfer ? _toAccount?.trim() : null,
      isBookmarked: widget.transaction?.isBookmarked ?? false,
      imagePaths: List<String>.from(_imagePaths),
    );

    if (widget.transaction != null) {
      await StorageService.updateTransaction(t);
    } else {
      await StorageService.addTransaction(t);
    }

    if (StorageService.getTransaction(t.id) == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transaction != null ? 'Updated' : 'Saved',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.surface,
        ),
      );
      context.pop(true);
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
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
        title: Text(
          widget.transaction != null ? 'Edit Transaction' : 'New Transaction',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TransactionTypeSelector(
                selectedType: _type,
                onChanged: _onTypeChanged,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      AmountSection(
                        controller: _amountController,
                        color: _activeColor,
                        type: _type,
                        onCalculatorTap: _openCalculator,
                      ),
                      const SizedBox(height: 20),
                      TransactionDetailsSection(
                        type: _type,
                        activeColor: _activeColor,
                        selectedCategory: _selectedCategory,
                        selectedSubcategory: _selectedSubcategory,
                        accountType: _accountType,
                        selectedDate: _selectedDate,
                        dateTimeLabel: '$dateStr  •  $timeStr',
                        categoryError: _categoryError && _hasAttemptedSave,
                        onCategoryTap: _showCategoryPicker,
                        onAccountTap: _showAccountPicker,
                        onDateTap: () async {
                          await _selectDate();
                          await _selectTime();
                        },
                        getAccountLabel: _getAccountLabel,
                      ),
                      if (_type == TransactionType.transfer) ...[
                        const SizedBox(height: 20),
                        TransferSection(
                          fromAccount: _fromAccount,
                          toAccount: _toAccount,
                          onFromChanged: (v) => setState(() => _fromAccount = v),
                          onToChanged: (v) => setState(() => _toAccount = v),
                        ),
                      ],
                      const SizedBox(height: 20),
                      DescriptionSection(
                        titleController: _titleController,
                        noteController: _noteController,
                        color: _activeColor,
                      ),
                      const SizedBox(height: 20),
                      AttachmentSection(
                        imagePaths: _imagePaths,
                        onAddTap: _showImageSourceSheet,
                        onRemove: (i) => setState(() => _imagePaths.removeAt(i)),
                      ),
                      const SizedBox(height: 24),
                      SaveTransactionButton(
                        color: _activeColor,
                        onTap: _saveTransaction,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
