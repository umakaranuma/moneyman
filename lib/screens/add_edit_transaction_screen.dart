import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      _titleController =
          TextEditingController(text: widget.transaction!.title);
      _amountController =
          TextEditingController(text: widget.transaction!.amount.toString());
      _noteController =
          TextEditingController(text: widget.transaction!.note ?? '');
      _transactionType = widget.transaction!.type;
      _accountType = widget.transaction!.accountType;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = widget.transaction!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.transaction!.date);
      _fromAccount = widget.transaction!.fromAccount;
      _toAccount = widget.transaction!.toAccount;
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.fab,
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
            colorScheme: const ColorScheme.dark(
              primary: AppColors.fab,
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom:
                          BorderSide(color: AppColors.surfaceVariant, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.textMuted),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: AppColors.textMuted),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Categories List
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final hasSubcategories =
                          category.subcategories.isNotEmpty;

                      return ListTile(
                        leading: category.emoji.isNotEmpty
                            ? Text(
                                category.emoji,
                                style: const TextStyle(fontSize: 20),
                              )
                            : null,
                        title: Text(
                          category.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        trailing: hasSubcategories
                            ? const Icon(
                                Icons.chevron_right,
                                color: AppColors.textMuted,
                              )
                            : null,
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
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSubcategoryPicker(Category category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button
              Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  if (category.emoji.isNotEmpty)
                    Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  if (category.emoji.isNotEmpty) const SizedBox(width: 8),
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceVariant),

              // Select main category option
              ListTile(
                title: Text(
                  '${category.emoji} ${category.name}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedCategory = category.name;
                    _selectedSubcategory = null;
                  });
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),

              // Subcategories
              ...category.subcategories.map((sub) {
                return ListTile(
                  title: Text(
                    sub,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category.name;
                      _selectedSubcategory = sub;
                    });
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showAccountPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Account',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...AccountType.values.map((type) {
                String label;
                IconData icon;

                switch (type) {
                  case AccountType.cash:
                    label = 'Cash';
                    icon = Icons.money;
                    break;
                  case AccountType.card:
                    label = 'Card';
                    icon = Icons.credit_card;
                    break;
                  case AccountType.bank:
                    label = 'Accounts';
                    icon = Icons.account_balance;
                    break;
                  case AccountType.other:
                    label = 'Other';
                    icon = Icons.account_circle;
                    break;
                }

                return ListTile(
                  leading: Icon(icon, color: AppColors.textSecondary),
                  title: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  trailing: _accountType == type
                      ? const Icon(Icons.check, color: AppColors.fab)
                      : null,
                  onTap: () {
                    setState(() {
                      _accountType = type;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      if (_transactionType == TransactionType.transfer) {
        if (_fromAccount == null ||
            _fromAccount!.trim().isEmpty ||
            _toAccount == null ||
            _toAccount!.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Please enter both From and To accounts for transfer'),
            ),
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
      );

      if (widget.transaction != null) {
        StorageService.updateTransaction(transaction);
      } else {
        StorageService.addTransaction(transaction);
      }

      Navigator.pop(context);
    }
  }

  void _saveAndContinue() {
    if (_formKey.currentState!.validate()) {
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
      );

      StorageService.addTransaction(transaction);

      // Clear fields for next entry
      setState(() {
        _titleController.clear();
        _amountController.clear();
        _noteController.clear();
        _selectedCategory = null;
        _selectedSubcategory = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction saved'),
          duration: Duration(seconds: 1),
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
        return 'Accounts';
      case AccountType.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MM/dd/yy (E)').format(_selectedDate);
    final timeStr = DateFormat('h:mm a').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _transactionType == TransactionType.expense
              ? 'Expense'
              : _transactionType == TransactionType.income
                  ? 'Income'
                  : 'Transfer',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.download_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Transaction Type Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildTypeButton(
                    'Income',
                    TransactionType.income,
                    AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  _buildTypeButton(
                    'Expense',
                    TransactionType.expense,
                    AppColors.expense,
                  ),
                  const SizedBox(width: 8),
                  _buildTypeButton(
                    'Transfer',
                    TransactionType.transfer,
                    AppColors.textPrimary,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Date and Time Row
                    _buildFormRow(
                      'Date',
                      InkWell(
                        onTap: () async {
                          await _selectDate();
                          await _selectTime();
                        },
                        child: Row(
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: InkWell(
                        onTap: () {},
                        child: const Column(
                          children: [
                            Icon(Icons.refresh,
                                color: AppColors.textMuted, size: 18),
                            Text(
                              'Rep/Inst.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Amount Row
                    _buildFormRow(
                      'Amount',
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter amount';
                            }
                            if (double.tryParse(value.trim()) == null ||
                                double.parse(value.trim()) <= 0) {
                              return 'Invalid amount';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),

                    // Category Row
                    _buildFormRow(
                      'Category',
                      Expanded(
                        child: InkWell(
                          onTap: _showCategoryPicker,
                          child: Row(
                            children: [
                              if (_selectedCategory != null)
                                Text(
                                  DefaultCategories.getCategoryEmoji(
                                    _selectedCategory,
                                    isIncome: _transactionType ==
                                        TransactionType.income,
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              if (_selectedCategory != null)
                                const SizedBox(width: 8),
                              Text(
                                _selectedCategory ??
                                    (_selectedSubcategory != null
                                        ? '$_selectedCategory > $_selectedSubcategory'
                                        : ''),
                                style: TextStyle(
                                  color: _selectedCategory != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      showBorder: true,
                      borderColor: AppColors.expense,
                    ),

                    // Account Row
                    _buildFormRow(
                      'Account',
                      Expanded(
                        child: InkWell(
                          onTap: _showAccountPicker,
                          child: Text(
                            _getAccountLabel(_accountType),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Transfer specific fields
                    if (_transactionType == TransactionType.transfer) ...[
                      _buildFormRow(
                        'From',
                        Expanded(
                          child: TextFormField(
                            initialValue: _fromAccount,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'From account',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              _fromAccount = value;
                            },
                          ),
                        ),
                      ),
                      _buildFormRow(
                        'To',
                        Expanded(
                          child: TextFormField(
                            initialValue: _toAccount,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'To account',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              _toAccount = value;
                            },
                          ),
                        ),
                      ),
                    ],

                    // Note Row
                    _buildFormRow(
                      'Note',
                      Expanded(
                        child: TextFormField(
                          controller: _noteController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description with camera
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _titleController,
                              style:
                                  const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Description',
                                hintStyle:
                                    TextStyle(color: AppColors.textMuted),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter description';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt_outlined,
                                color: AppColors.textMuted),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _saveTransaction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.fab,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saveAndContinue,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(
                                    color: AppColors.surfaceVariant),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(
      String label, TransactionType type, Color activeColor) {
    final isSelected = _transactionType == type;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _transactionType = type;
            _selectedCategory = null;
            _selectedSubcategory = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected ? AppColors.surface : Colors.transparent,
            border: Border.all(
              color: isSelected ? activeColor : AppColors.surfaceVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : AppColors.textMuted,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormRow(
    String label,
    Widget content, {
    Widget? trailing,
    bool showBorder = false,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: showBorder
                ? (borderColor ?? AppColors.surfaceVariant)
                : AppColors.surfaceVariant,
            width: showBorder ? 2 : 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
          content,
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
