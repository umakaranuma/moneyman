import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../services/category_service.dart';
import '../services/storage_service.dart';
import '../services/sms_service.dart';

class TransactionFilterScreen extends StatefulWidget {
  final DateTime selectedMonth;
  final TransactionFilter? initialFilter;

  const TransactionFilterScreen({
    super.key,
    required this.selectedMonth,
    this.initialFilter,
  });

  @override
  State<TransactionFilterScreen> createState() =>
      _TransactionFilterScreenState();
}

class _TransactionFilterScreenState extends State<TransactionFilterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TransactionFilter _filter;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.selectedMonth;
    if (widget.initialFilter != null) {
      _filter = TransactionFilter()
        ..selectedIncomeCategories =
            widget.initialFilter!.selectedIncomeCategories.toSet()
        ..selectedExpenseCategories =
            widget.initialFilter!.selectedExpenseCategories.toSet()
        ..selectedAccountTypes =
            widget.initialFilter!.selectedAccountTypes.toSet()
        ..includeIncomeTransfers = widget.initialFilter!.includeIncomeTransfers
        ..includeExpenseTransfers =
            widget.initialFilter!.includeExpenseTransfers;
    } else {
      _filter = TransactionFilter();
    }
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  Future<Map<String, double>> _getSummary() async {
    // Get manually added transactions
    final manualTransactions = StorageService.getAllTransactions();

    // Get SMS transactions
    List<Transaction> smsTransactions = [];
    try {
      final hasPermission = await SmsService.hasSmsPermission();
      if (hasPermission) {
        final smsParsed = await SmsService.fetchAndParseSmsMessages(
          fetchAll: false,
        );
        // Convert to Transaction objects (simplified version)
        smsTransactions = smsParsed.map((smsT) {
          final isTransfer = smsT.rawMessage.toUpperCase().contains('ATM') ||
              smsT.rawMessage.toUpperCase().contains('WITHDRAWAL') ||
              smsT.rawMessage.toUpperCase().contains('DEPOSIT');
          
          return Transaction(
            id: 'sms_${smsT.id}',
            title: '${smsT.bankName} ${smsT.isCredit ? "Credit" : "Debit"}',
            amount: smsT.amount,
            type: isTransfer
                ? TransactionType.transfer
                : (smsT.isCredit
                    ? TransactionType.income
                    : TransactionType.expense),
            date: smsT.date,
            category: 'Bank Transaction',
            accountType: AccountType.bank,
          );
        }).toList();
      }
    } catch (e) {
      // Ignore errors
    }

    // Combine transactions (manual take precedence)
    final uniqueTransactions = <String, Transaction>{};
    for (var t in manualTransactions) {
      uniqueTransactions[t.id] = t;
    }
    for (var t in smsTransactions) {
      if (!uniqueTransactions.containsKey(t.id)) {
        uniqueTransactions[t.id] = t;
      }
    }

    // Filter by month
    final transactions = uniqueTransactions.values
        .where((t) {
          return t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month;
        })
        .toList();

    double income = 0;
    double expense = 0;

    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else if (t.type == TransactionType.expense) {
        expense += t.amount;
      }
    }

    final total = income - expense;
    final totalAbs = (income + expense).abs();
    final incomePercent = totalAbs > 0 ? (income / totalAbs * 100) : 0;
    final expensePercent = totalAbs > 0 ? (expense / totalAbs * 100) : 0;

    return {
      'income': income.toDouble(),
      'expense': expense.toDouble(),
      'total': total.toDouble(),
      'incomePercent': incomePercent.toDouble(),
      'expensePercent': expensePercent.toDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Summary Section
            FutureBuilder<Map<String, double>>(
              future: _getSummary(),
              builder: (context, snapshot) {
                final summary = snapshot.data ?? {
                  'income': 0.0,
                  'expense': 0.0,
                  'total': 0.0,
                  'incomePercent': 0.0,
                  'expensePercent': 0.0,
                };
                return _buildSummarySection(summary);
              },
            ),

            // Tabs
            _buildTabs(),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIncomeTab(),
                  _buildExpensesTab(),
                  _buildAccountTab(),
                ],
              ),
            ),

            // Apply Button
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Close button row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select items that you want to filter',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Month Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _previousMonth,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('MMM yyyy').format(_selectedMonth),
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _nextMonth,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(Map<String, double> summary) {
    final incomePercent = summary['incomePercent']!.clamp(0.0, 100.0);
    final expensePercent = summary['expensePercent']!.clamp(0.0, 100.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Row(
        children: [
          // Income Circle
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: incomePercent / 100,
                        strokeWidth: 8,
                        backgroundColor: AppColors.income.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.income,
                        ),
                      ),
                      Text(
                        '${incomePercent.toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Income',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${_formatAmount(summary['income']!)}',
                  style: GoogleFonts.inter(
                    color: AppColors.income,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Expenses Circle
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: expensePercent / 100,
                        strokeWidth: 8,
                        backgroundColor: AppColors.error.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.error,
                        ),
                      ),
                      Text(
                        '${expensePercent.toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Expenses',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${_formatAmount(summary['expense']!)}',
                  style: GoogleFonts.inter(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Total
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  'Total',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${_formatAmount(summary['total']!)}',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _buildTab('INCOME', 0),
          const SizedBox(width: 8),
          _buildTab('EXPENSES', 1),
          const SizedBox(width: 8),
          _buildTab('ACCOUNT', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.error : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isSelected ? AppColors.error : AppColors.textMuted,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeTab() {
    final incomeCategories = CategoryService.getCategories(isIncome: true);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        _buildCheckboxItem(
          'All',
          _filter.selectedIncomeCategories.isEmpty ||
              _filter.selectedIncomeCategories.length == incomeCategories.length,
          (value) {
            setState(() {
              if (value == true) {
                _filter.selectedIncomeCategories =
                    incomeCategories.map((c) => c.name).toSet();
              } else {
                _filter.selectedIncomeCategories.clear();
              }
            });
          },
        ),
        const SizedBox(height: 8),
        ...incomeCategories.map((category) => _buildCheckboxItem(
              category.name,
              _filter.selectedIncomeCategories.contains(category.name),
              (value) {
                setState(() {
                  if (value == true) {
                    _filter.selectedIncomeCategories.add(category.name);
                  } else {
                    _filter.selectedIncomeCategories.remove(category.name);
                  }
                });
              },
            )),
      ],
    );
  }

  Widget _buildExpensesTab() {
    final expenseCategories = CategoryService.getCategories(isIncome: false);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        _buildCheckboxItem(
          'All',
          _filter.selectedExpenseCategories.isEmpty ||
              _filter.selectedExpenseCategories.length ==
                  expenseCategories.length,
          (value) {
            setState(() {
              if (value == true) {
                _filter.selectedExpenseCategories =
                    expenseCategories.map((c) => c.name).toSet();
              } else {
                _filter.selectedExpenseCategories.clear();
              }
            });
          },
        ),
        const SizedBox(height: 8),
        ...expenseCategories.map((category) => _buildCheckboxItem(
              category.name,
              _filter.selectedExpenseCategories.contains(category.name),
              (value) {
                setState(() {
                  if (value == true) {
                    _filter.selectedExpenseCategories.add(category.name);
                  } else {
                    _filter.selectedExpenseCategories.remove(category.name);
                  }
                });
              },
            )),
      ],
    );
  }

  Widget _buildAccountTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        // Transfer options
        _buildTransferOption('Income Transfer-In', AppColors.income, isIncome: true),
        const SizedBox(height: 12),
        _buildTransferOption('Expenses Transfer-Out', AppColors.error, isIncome: false),
        const SizedBox(height: 24),
        // Account types
        _buildSectionHeader('Cash'),
        _buildCheckboxItem(
          'All',
          _filter.selectedAccountTypes.isEmpty ||
              _filter.selectedAccountTypes.contains(AccountType.cash),
          (value) {
            setState(() {
              if (value == true) {
                _filter.selectedAccountTypes.add(AccountType.cash);
              } else {
                _filter.selectedAccountTypes.remove(AccountType.cash);
              }
            });
          },
        ),
        _buildCheckboxItem(
          'Cash',
          _filter.selectedAccountTypes.contains(AccountType.cash),
          (value) {
            setState(() {
              if (value == true) {
                _filter.selectedAccountTypes.add(AccountType.cash);
              } else {
                _filter.selectedAccountTypes.remove(AccountType.cash);
              }
            });
          },
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('Accounts'),
        _buildCheckboxItem(
          'All',
          _filter.selectedAccountTypes.isEmpty ||
              _filter.selectedAccountTypes.contains(AccountType.bank),
          (value) {
            setState(() {
              if (value == true) {
                _filter.selectedAccountTypes.add(AccountType.bank);
              } else {
                _filter.selectedAccountTypes.remove(AccountType.bank);
              }
            });
          },
        ),
        _buildCheckboxItem(
          'Accounts',
          _filter.selectedAccountTypes.contains(AccountType.bank),
          (value) {
            setState(() {
              if (value == true) {
                _filter.selectedAccountTypes.add(AccountType.bank);
              } else {
                _filter.selectedAccountTypes.remove(AccountType.bank);
              }
            });
          },
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('Card'),
        _buildCheckboxItem(
          'All',
          _filter.selectedAccountTypes.isEmpty ||
              _filter.selectedAccountTypes.contains(AccountType.card),
          (value) {
            setState(() {
              if (value == true) {
                _filter.selectedAccountTypes.add(AccountType.card);
              } else {
                _filter.selectedAccountTypes.remove(AccountType.card);
              }
            });
          },
        ),
        _buildCheckboxItem(
          'Card',
          _filter.selectedAccountTypes.contains(AccountType.card),
          (value) {
            setState(() {
              if (value == true) {
                _filter.selectedAccountTypes.add(AccountType.card);
              } else {
                _filter.selectedAccountTypes.remove(AccountType.card);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildTransferOption(String label, Color color, {required bool isIncome}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isIncome) {
            _filter.includeIncomeTransfers = !_filter.includeIncomeTransfers;
          } else {
            _filter.includeExpenseTransfers =
                !_filter.includeExpenseTransfers;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isIncome
                    ? _filter.includeIncomeTransfers
                    : _filter.includeExpenseTransfers)
                ? color
                : AppColors.surfaceVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: (isIncome
                        ? _filter.includeIncomeTransfers
                        : _filter.includeExpenseTransfers)
                    ? color
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                color: (isIncome
                        ? _filter.includeIncomeTransfers
                        : _filter.includeExpenseTransfers)
                    ? color
                    : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCheckboxItem(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    final hasFilters = _filter.hasActiveFilters;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (hasFilters) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _filter = TransactionFilter();
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: AppColors.error, width: 1.5),
                ),
                child: Text(
                  'Clear All',
                  style: GoogleFonts.inter(
                    color: AppColors.error,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Create a new filter instance to ensure proper state
                TransactionFilter? filterToReturn;
                if (_filter.hasActiveFilters) {
                  filterToReturn = TransactionFilter()
                    ..selectedIncomeCategories = _filter.selectedIncomeCategories.toSet()
                    ..selectedExpenseCategories = _filter.selectedExpenseCategories.toSet()
                    ..selectedAccountTypes = _filter.selectedAccountTypes.toSet()
                    ..includeIncomeTransfers = _filter.includeIncomeTransfers
                    ..includeExpenseTransfers = _filter.includeExpenseTransfers;
                } else {
                  filterToReturn = null;
                }
                
                print('Applying filter - Has active: ${_filter.hasActiveFilters}');
                print('Income categories: ${_filter.selectedIncomeCategories}');
                print('Expense categories: ${_filter.selectedExpenseCategories}');
                print('Account types: ${_filter.selectedAccountTypes}');
                
                Navigator.pop(context, {
                  'filter': filterToReturn,
                  'month': _selectedMonth,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Apply Filter',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount.abs() < 1000) {
      return amount.toStringAsFixed(2);
    } else if (amount.abs() < 100000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }
  }
}

class TransactionFilter {
  Set<String> selectedIncomeCategories = {};
  Set<String> selectedExpenseCategories = {};
  Set<AccountType> selectedAccountTypes = {};
  bool includeIncomeTransfers = true;
  bool includeExpenseTransfers = true;

  bool get hasActiveFilters {
    return selectedIncomeCategories.isNotEmpty ||
        selectedExpenseCategories.isNotEmpty ||
        selectedAccountTypes.isNotEmpty ||
        !includeIncomeTransfers ||
        !includeExpenseTransfers;
  }

  List<Transaction> apply(List<Transaction> transactions) {
    var filtered = List<Transaction>.from(transactions);

    // Filter by income categories
    if (selectedIncomeCategories.isNotEmpty) {
      filtered = filtered.where((t) {
        // If it's an income transaction, it must match one of the selected categories
        if (t.type == TransactionType.income) {
          if (t.category == null) return false;
          final matches = selectedIncomeCategories.any((cat) =>
              cat.toLowerCase() == t.category!.toLowerCase());
          print('Income transaction "${t.title}" with category "${t.category}" matches: $matches');
          return matches;
        }
        // Keep non-income transactions (they'll be filtered by expense categories if needed)
        return true;
      }).toList();
      print('After income filter: ${filtered.length} transactions');
    }

    // Filter by expense categories
    if (selectedExpenseCategories.isNotEmpty) {
      filtered = filtered.where((t) {
        // If it's an expense transaction, it must match one of the selected categories
        if (t.type == TransactionType.expense) {
          if (t.category == null) return false;
          final matches = selectedExpenseCategories.any((cat) =>
              cat.toLowerCase() == t.category!.toLowerCase());
          print('Expense transaction "${t.title}" with category "${t.category}" matches: $matches');
          return matches;
        }
        // Keep non-expense transactions
        return true;
      }).toList();
      print('After expense filter: ${filtered.length} transactions');
    }

    // Filter by account types
    if (selectedAccountTypes.isNotEmpty) {
      filtered = filtered.where((t) {
        return selectedAccountTypes.contains(t.accountType);
      }).toList();
    }

    // Filter transfers
    filtered = filtered.where((t) {
      if (t.type == TransactionType.transfer) {
        if (t.amount > 0) {
          return includeIncomeTransfers;
        } else {
          return includeExpenseTransfers;
        }
      }
      return true;
    }).toList();

    return filtered;
  }
}

