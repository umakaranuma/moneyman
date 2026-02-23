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
    final hasFilters = _filter.hasActiveFilters;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
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
            _buildTabs(),
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
            _buildBottomActions(hasFilters),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Filters",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: _previousMonth,
            child: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMM yyyy').format(_selectedMonth),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _nextMonth,
            child: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(Map<String, double> summary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Monthly Overview",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Rs. ${_formatAmount(summary['total']!)}",
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat(
                "Income",
                summary['income']!,
                AppColors.income,
              ),
              const SizedBox(width: 16),
              _miniStat(
                "Expense",
                summary['expense']!,
                AppColors.error,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _miniStat(String label, double value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs. ${_formatAmount(value)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildSegment("Income", 0),
          _buildSegment("Expenses", 1),
          _buildSegment("Accounts", 2),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, int index) {
    final isSelected = _tabController.index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected
                ? AppColors.primary
                : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeTab() {
    final categories = CategoryService.getCategories(isIncome: true);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: categories.map((category) {
          final isSelected =
              _filter.selectedIncomeCategories.contains(category.name);

          return _buildChip(
            category.name,
            isSelected,
            () {
              setState(() {
                if (isSelected) {
                  _filter.selectedIncomeCategories.remove(category.name);
                } else {
                  _filter.selectedIncomeCategories.add(category.name);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpensesTab() {
    final categories = CategoryService.getCategories(isIncome: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: categories.map((category) {
          final isSelected =
              _filter.selectedExpenseCategories.contains(category.name);

          return _buildChip(
            category.name,
            isSelected,
            () {
              setState(() {
                if (isSelected) {
                  _filter.selectedExpenseCategories.remove(category.name);
                } else {
                  _filter.selectedExpenseCategories.add(category.name);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Transfers",
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildChip(
                "Income Transfer-In",
                _filter.includeIncomeTransfers,
                () {
                  setState(() {
                    _filter.includeIncomeTransfers =
                        !_filter.includeIncomeTransfers;
                  });
                },
              ),
              _buildChip(
                "Expenses Transfer-Out",
                _filter.includeExpenseTransfers,
                () {
                  setState(() {
                    _filter.includeExpenseTransfers =
                        !_filter.includeExpenseTransfers;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Account types",
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildChip(
                "Cash",
                _filter.selectedAccountTypes.contains(AccountType.cash),
                () {
                  setState(() {
                    if (_filter.selectedAccountTypes.contains(AccountType.cash)) {
                      _filter.selectedAccountTypes.remove(AccountType.cash);
                    } else {
                      _filter.selectedAccountTypes.add(AccountType.cash);
                    }
                  });
                },
              ),
              _buildChip(
                "Accounts",
                _filter.selectedAccountTypes.contains(AccountType.bank),
                () {
                  setState(() {
                    if (_filter.selectedAccountTypes.contains(AccountType.bank)) {
                      _filter.selectedAccountTypes.remove(AccountType.bank);
                    } else {
                      _filter.selectedAccountTypes.add(AccountType.bank);
                    }
                  });
                },
              ),
              _buildChip(
                "Card",
                _filter.selectedAccountTypes.contains(AccountType.card),
                () {
                  setState(() {
                    if (_filter.selectedAccountTypes.contains(AccountType.card)) {
                      _filter.selectedAccountTypes.remove(AccountType.card);
                    } else {
                      _filter.selectedAccountTypes.add(AccountType.card);
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _applyFilter() {
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
    Navigator.pop(context, {
      'filter': filterToReturn,
      'month': _selectedMonth,
    });
  }

  Widget _buildBottomActions(bool hasFilters) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'Clear',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _applyFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Apply Filters',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##,##0.00').format(amount);
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

    // Income: only show selected income categories; if none selected, show no income
    filtered = filtered.where((t) {
      if (t.type == TransactionType.income) {
        if (selectedIncomeCategories.isEmpty) return false;
        if (t.category == null) return false;
        return selectedIncomeCategories.any((cat) =>
            cat.toLowerCase() == t.category!.toLowerCase());
      }
      return true;
    }).toList();

    // Expense: only show selected expense categories; if none selected, show no expense
    filtered = filtered.where((t) {
      if (t.type == TransactionType.expense) {
        if (selectedExpenseCategories.isEmpty) return false;
        if (t.category == null) return false;
        return selectedExpenseCategories.any((cat) =>
            cat.toLowerCase() == t.category!.toLowerCase());
      }
      return true;
    }).toList();

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

