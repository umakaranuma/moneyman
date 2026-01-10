import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/sms_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../core/router/app_router.dart';
import 'transaction_filter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _refreshKey = 0; // Key to force FutureBuilder refresh
  String _searchQuery = '';
  TransactionFilter? _activeFilter;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tabs = ['Daily', 'Calendar', 'Monthly', 'Total', 'Note'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, refresh to get new SMS transactions
      setState(() {
        _refreshKey++;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible (e.g., returning from SMS screen)
    // Use a small delay to avoid unnecessary refreshes during initial build
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _refreshKey++;
        });
      }
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;

    if (_tabController.index == 4) {
      // Note tab - use GoRouter
      context.goToNotes();
      Future.delayed(const Duration(milliseconds: 100), () {
        _tabController.animateTo(0);
        setState(() {
          _refreshKey++; // Force FutureBuilder to refresh
        });
      });
    } else {
      setState(() {
        _refreshKey++; // Force FutureBuilder to refresh
      });
    }
  }

  Future<List<Transaction>> _getFilteredTransactions() async {
    // Get manually added transactions
    final manualTransactions = StorageService.getAllTransactions();

    if (manualTransactions.isNotEmpty) {
      manualTransactions.take(3).forEach((t) {});
    }

    // Get SMS transactions and convert them to Transaction objects
    final smsTransactions = await _getSmsTransactionsAsTransactions();

    // Remove duplicates (if any SMS transaction was already imported)
    // Use transaction ID as the key to ensure edited transactions replace old ones
    final uniqueTransactions = <String, Transaction>{};

    // First, add all manual transactions (these are edited/imported, so they take precedence)
    for (var t in manualTransactions) {
      uniqueTransactions[t.id] = t;
    }

    // Then, add SMS transactions only if they don't already exist in manual storage
    // This ensures that edited transactions replace the original SMS versions
    for (var t in smsTransactions) {
      if (!uniqueTransactions.containsKey(t.id)) {
        uniqueTransactions[t.id] = t;
      }
    }

    var combinedTransactions = uniqueTransactions.values.toList();

    // Apply date filter based on tab
    switch (_tabController.index) {
      case 0: // Daily - show all transactions for current month grouped by date
      case 2: // Monthly - same as daily but for selected month
        combinedTransactions = combinedTransactions.where((t) {
          return t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month;
        }).toList();
        break;
      case 3: // Total
        // No date filter for total
        break;
      default:
        combinedTransactions = combinedTransactions.where((t) {
          return t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month;
        }).toList();
    }

    // Apply active filter if any
    if (_activeFilter != null) {
      print(
        'Applying filter: Income categories: ${_activeFilter!.selectedIncomeCategories}, Expense categories: ${_activeFilter!.selectedExpenseCategories}, Account types: ${_activeFilter!.selectedAccountTypes}',
      );
      print('Has active filters: ${_activeFilter!.hasActiveFilters}');
      print('Transactions before filter: ${combinedTransactions.length}');
      if (_activeFilter!.hasActiveFilters) {
        combinedTransactions = _activeFilter!.apply(combinedTransactions);
        print('Transactions after filter: ${combinedTransactions.length}');
      }
    }

    // Apply search query if any
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      combinedTransactions = combinedTransactions.where((t) {
        return t.title.toLowerCase().contains(query) ||
            (t.category?.toLowerCase().contains(query) ?? false) ||
            (t.note?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return combinedTransactions;
  }

  Future<List<Transaction>> _getSmsTransactionsAsTransactions() async {
    try {
      final hasPermission = await SmsService.hasSmsPermission();
      if (!hasPermission) {
        return [];
      }

      // Fetch SMS transactions
      final smsTransactions = await SmsService.fetchAndParseSmsMessages(
        fetchAll: false,
      );

      // Convert ParsedSmsTransaction to Transaction
      return smsTransactions.map((smsT) {
        // Detect if this is a transfer (ATM withdrawal, cash deposit, bank-to-bank transfer) vs actual expense/income
        final isTransfer = _isSmsTransactionTransfer(smsT);

        // Extract account information for transfers
        String? fromAccount;
        String? toAccount;

        if (isTransfer) {
          if (smsT.isCredit) {
            // Money coming in (cash deposit to bank, or transfer received)
            toAccount = smsT.accountNumber ?? 'Bank Account';
            fromAccount = 'Cash'; // Default for cash deposits
          } else {
            // Money going out (ATM withdrawal, or transfer to another account)
            fromAccount = smsT.accountNumber ?? 'Bank Account';
            // Check if it's a bank-to-bank transfer (has "TO ACCOUNT" or similar)
            final upperMessage = smsT.rawMessage.toUpperCase();
            if (upperMessage.contains('TO ACCOUNT') ||
                upperMessage.contains('TRANSFERRED TO') ||
                upperMessage.contains('NEFT') ||
                upperMessage.contains('RTGS') ||
                upperMessage.contains('IMPS') ||
                upperMessage.contains('UPI')) {
              // Bank-to-bank transfer - try to extract recipient account
              toAccount =
                  _extractRecipientAccount(smsT.rawMessage) ?? 'Other Account';
            } else {
              // ATM withdrawal
              toAccount = 'Cash';
            }
          }
        }

        return Transaction(
          id: 'sms_${smsT.id}',
          title: isTransfer
              ? (smsT.isCredit
                    ? '${smsT.bankName} Deposit'
                    : (smsT.rawMessage.toUpperCase().contains('TO ACCOUNT') ||
                              smsT.rawMessage.toUpperCase().contains(
                                'TRANSFERRED TO',
                              ) ||
                              smsT.rawMessage.toUpperCase().contains('NEFT') ||
                              smsT.rawMessage.toUpperCase().contains('RTGS') ||
                              smsT.rawMessage.toUpperCase().contains('IMPS')
                          ? '${smsT.bankName} Transfer'
                          : '${smsT.bankName} Withdrawal'))
              : '${smsT.bankName} ${smsT.isCredit ? "Credit" : "Debit"}',
          amount: smsT.amount,
          type: isTransfer
              ? TransactionType.transfer
              : (smsT.isCredit
                    ? TransactionType.income
                    : TransactionType.expense),
          date: smsT.date,
          category: isTransfer
              ? 'Transfer'
              : (smsT.isCredit ? 'Bank Transfer' : 'Bank Transaction'),
          note:
              'From SMS: ${smsT.rawMessage.substring(0, smsT.rawMessage.length > 50 ? 50 : smsT.rawMessage.length)}${smsT.rawMessage.length > 50 ? "..." : ""}',
          accountType: AccountType.bank,
          fromAccount: fromAccount,
          toAccount: toAccount,
        );
      }).toList();
    } catch (e) {
      // If there's an error, just return empty list
      return [];
    }
  }

  /// Detect if SMS transaction is a transfer (ATM withdrawal/cash deposit) vs actual expense/income
  ///
  /// Rule: Not all debits are expenses!
  /// - Debit = Transfer (ATM withdrawal) → NOT an expense (just moving money)
  /// - Debit = Actual Expense (payment, purchase, bill) → IS an expense (money spent)
  /// - Credit = Bank Deposit (money received) → IS income (not a transfer)
  /// - Credit = Cash Deposit to Bank → IS transfer (moving money)
  bool _isSmsTransactionTransfer(ParsedSmsTransaction smsT) {
    final upperMessage = smsT.rawMessage.toUpperCase();

    // If it's a credit (money coming in), check if it's a bank deposit (income) or cash deposit (transfer)
    if (smsT.isCredit) {
      // Bank deposit (money credited to account) = Income, NOT transfer
      // Cash deposit (depositing cash to bank) = Transfer

      // Check if it's a cash deposit (transfer from cash to bank)
      final cashDepositKeywords = [
        'CASH DEPOSIT',
        'CASH DEPOSITED',
        'DEPOSIT CASH',
        'CASH DEPOSITED TO',
      ];

      final isCashDeposit = cashDepositKeywords.any(
        (keyword) => upperMessage.contains(keyword),
      );

      // If it's a cash deposit, it's a transfer
      // Otherwise, bank deposits are income (money received)
      return isCashDeposit;
    }

    // For debits (money going out)
    // First, check if it's clearly an actual expense/payment
    final expenseKeywords = [
      'PAYMENT',
      'PAID',
      'PURCHASE',
      'PURCHASED',
      'BILL',
      'MERCHANT',
      'POS',
      'DEBIT CARD',
      'CREDIT CARD',
      'ONLINE',
      'SHOPPING',
      'RESTAURANT',
      'FOOD',
      'GROCERY',
      'FUEL',
      'PETROL',
      'DIESEL',
      'TAXI',
      'UBER',
      'OLA',
      'RENT',
      'SALARY',
      'SERVICE',
      'CHARGE',
      'FEE',
      'TAX',
    ];

    // FIRST: Check for transfers/withdrawals BEFORE checking for expenses
    // This ensures withdrawals are correctly identified even if they contain expense keywords

    // ATM withdrawals - must have both "ATM" AND "WITHDRAWAL/WITHDRAWN"
    // Check this FIRST to catch messages like "HNB ATM Withdrawal e-Receipt"
    if (upperMessage.contains('ATM') &&
        (upperMessage.contains('WITHDRAWAL') ||
            upperMessage.contains('WITHDRAWN'))) {
      return true;
    }

    // Also check for "ATM WITHDRAWAL" or "ATM WITHDRAWN" as a phrase
    if (RegExp(
      r'ATM\s+WITHDRAW(?:AL|N)',
      caseSensitive: false,
    ).hasMatch(upperMessage)) {
      return true;
    }

    // Cash withdrawals - must have "CASH WITHDRAWAL" or "CASH WITHDRAWN" (exact phrases)
    if (upperMessage.contains('CASH WITHDRAWAL') ||
        upperMessage.contains('CASH WITHDRAWN')) {
      return true;
    }

    // Check for standalone "WITHDRAWAL" or "WITHDRAWN" with account patterns
    // This catches messages like "Withdrawal Rs X From A/C No XXXX"
    if ((upperMessage.contains('WITHDRAWAL') ||
            upperMessage.contains('WITHDRAWN')) &&
        (upperMessage.contains('FROM ACCOUNT') ||
            upperMessage.contains('FROM A/C') ||
            upperMessage.contains('FROM AC') ||
            RegExp(
              r'FROM\s+[A/C\s]*NO',
              caseSensitive: false,
            ).hasMatch(upperMessage) ||
            upperMessage.contains('A/C NO') ||
            upperMessage.contains('ACCOUNT NO') ||
            upperMessage.contains('A/C:'))) {
      return true;
    }

    // Bank-to-bank transfers - must have NEFT/RTGS/IMPS/UPI AND "TO ACCOUNT" or "DEBITED TO AC" pattern
    if ((upperMessage.contains('NEFT') ||
            upperMessage.contains('RTGS') ||
            upperMessage.contains('IMPS') ||
            upperMessage.contains('UPI')) &&
        (upperMessage.contains('TO ACCOUNT') ||
            upperMessage.contains('TO A/C') ||
            upperMessage.contains('TO AC') ||
            RegExp(
              r'DEBITED\s+TO\s+(?:AC|ACCOUNT|A/C)',
              caseSensitive: false,
            ).hasMatch(upperMessage) ||
            RegExp(
              r'TO\s+(?:AC|ACCOUNT|A/C)\s+NO',
              caseSensitive: false,
            ).hasMatch(upperMessage))) {
      return true;
    }

    // Check for "TRANSFER" with account number patterns (bank-to-bank transfers)
    if (upperMessage.contains('TRANSFER') &&
        (upperMessage.contains('TO ACCOUNT') ||
            upperMessage.contains('TO A/C') ||
            upperMessage.contains('TO AC') ||
            upperMessage.contains('FROM ACCOUNT') ||
            upperMessage.contains('FROM A/C') ||
            upperMessage.contains('FROM AC') ||
            RegExp(
              r'TO\s+[A/C\s]*NO',
              caseSensitive: false,
            ).hasMatch(upperMessage) ||
            RegExp(
              r'FROM\s+[A/C\s]*NO',
              caseSensitive: false,
            ).hasMatch(upperMessage))) {
      return true;
    }

    // NOW check for expenses - if it's clearly an expense, it's NOT a transfer
    final isActualExpense = expenseKeywords.any(
      (keyword) => upperMessage.contains(keyword),
    );

    // If it's clearly an expense, it's NOT a transfer
    if (isActualExpense) {
      return false;
    }

    // Default: If unclear, treat debit as expense (safer assumption)
    // But user can manually change it later
    return false;
  }

  /// Extract recipient account number from SMS message for bank-to-bank transfers
  String? _extractRecipientAccount(String message) {
    final upperMessage = message.toUpperCase();

    // Patterns to find recipient account in transfer messages
    final patterns = [
      // "TO ACCOUNT XXXX" or "TO A/C XXXX"
      RegExp(
        r'TO\s+(?:ACCOUNT|A/C|ACCT)[:\s]*[X*]*([0-9]{4,})',
        caseSensitive: false,
      ),
      // "TRANSFERRED TO XXXX"
      RegExp(r'TRANSFERRED\s+TO[:\s]*[X*]*([0-9]{4,})', caseSensitive: false),
      // "BENEFICIARY XXXX" or "BEN XXXX"
      RegExp(r'BEN(?:EFICIARY)?[:\s]*[X*]*([0-9]{4,})', caseSensitive: false),
      // UPI: "TO XXXX@bank"
      RegExp(r'TO\s+([A-Z0-9]+@[A-Z]+)', caseSensitive: false),
      // Account number after "TO" keyword
      RegExp(r'TO[:\s]+[A-Z\s]*([0-9]{4,})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(upperMessage);
      if (match != null && match.group(1) != null) {
        final account = match.group(1)!;
        // If it's a UPI ID, return as is, otherwise mask it
        if (account.contains('@')) {
          return account;
        } else {
          return '****${account.length > 4 ? account.substring(account.length - 4) : account}';
        }
      }
    }

    return null;
  }

  Map<DateTime, List<Transaction>> _groupTransactionsByDate(
    List<Transaction> transactions,
  ) {
    final grouped = <DateTime, List<Transaction>>{};
    for (var transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      grouped.putIfAbsent(date, () => []).add(transaction);
    }
    return grouped;
  }

  void _previousMonth() {
    setState(() {
      if (_tabController.index == 2) {
        // Monthly view - navigate by year
        _selectedMonth = DateTime(
          _selectedMonth.year - 1,
          _selectedMonth.month,
        );
      } else {
        _selectedMonth = DateTime(
          _selectedMonth.year,
          _selectedMonth.month - 1,
        );
      }
      _refreshKey++; // Force FutureBuilder to refresh
    });
  }

  void _nextMonth() {
    setState(() {
      if (_tabController.index == 2) {
        // Monthly view - navigate by year
        _selectedMonth = DateTime(
          _selectedMonth.year + 1,
          _selectedMonth.month,
        );
      } else {
        _selectedMonth = DateTime(
          _selectedMonth.year,
          _selectedMonth.month + 1,
        );
      }
      _refreshKey++; // Force FutureBuilder to refresh
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<Transaction>>(
          key: ValueKey(_refreshKey), // Force refresh when key changes
          future: _getFilteredTransactions(),
          builder: (context, snapshot) {
            final transactions = snapshot.data ?? [];
            final summary = _getSummaryFromTransactions(transactions);
            final groupedTransactions = _groupTransactionsByDate(transactions);
            final sortedDates = groupedTransactions.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return Column(
              children: [
                // Header with Month Selector
                _buildHeader(),

                // Tabs
                _buildTabs(),

                // Summary Bar
                _buildSummaryBar(summary),

                // Content based on selected tab
                Expanded(
                  child: _buildContentForTab(
                    transactions,
                    groupedTransactions,
                    sortedDates,
                    summary,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Map<String, double> _getSummaryFromTransactions(
    List<Transaction> transactions,
  ) {
    // Only count actual income and expenses, exclude transfers
    // Transfers just move money between accounts, they don't affect net balance

    final incomeTransactions = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    final expenseTransactions = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final transferTransactions = transactions
        .where((t) => t.type == TransactionType.transfer)
        .toList();

    final income = incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final expense = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final total = income - expense;

    // Print first few transactions of each type for debugging
    if (expenseTransactions.isNotEmpty) {
      expenseTransactions.take(3).forEach((t) {});
    }
    if (transferTransactions.isNotEmpty) {
      transferTransactions.take(3).forEach((t) {});
    }

    return {'income': income, 'expense': expense, 'total': total};
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      child: GestureDetector(
        onTap: () async {
          final result = await context.goToAddTransaction<bool>();
          if (result == true) {
            // Transaction was saved, refresh the screen
            setState(() {
              _refreshKey++; // Force FutureBuilder to refresh
            });
          }
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Show year only in Monthly view, month + year otherwise
    final headerText = _tabController.index == 2
        ? '${_selectedMonth.year}'
        : DateFormat('MMMM yyyy').format(_selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          _buildCircleButton(
            icon: Icons.chevron_left_rounded,
            onTap: _previousMonth,
          ),
          const SizedBox(width: 8),
          Text(
            headerText,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          _buildCircleButton(
            icon: Icons.chevron_right_rounded,
            onTap: _nextMonth,
          ),
          const Spacer(),
          _buildGlassButton(
            icon: Icons.sms_outlined,
            color: AppColors.income,
            onTap: () => context.goToSmsTransactions(),
          ),
          const SizedBox(width: 8),
          _buildGlassButton(
            icon: Icons.search_rounded,
            color: _searchQuery.isNotEmpty
                ? AppColors.primary
                : AppColors.textSecondary,
            onTap: () => _showSearchDialog(),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              _buildGlassButton(
                icon: Icons.tune_rounded,
                color: _activeFilter?.hasActiveFilters == true
                    ? AppColors.primary
                    : AppColors.textSecondary,
                onTap: () => _showFilterDialog(),
              ),
              if (_activeFilter?.hasActiveFilters == true)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          if (_searchQuery.isNotEmpty ||
              _activeFilter?.hasActiveFilters == true)
            const SizedBox(width: 8),
          if (_searchQuery.isNotEmpty ||
              _activeFilter?.hasActiveFilters == true)
            _buildGlassButton(
              icon: Icons.clear_all_rounded,
              color: AppColors.error,
              onTap: () {
                setState(() {
                  _searchQuery = '';
                  _activeFilter = null;
                  _searchController.clear();
                  _refreshKey++;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceVariant, width: 1),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _showSearchDialog() {
    _searchController.text = _searchQuery;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Search Transactions',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search by title, category, or note...',
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: AppColors.textMuted),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.surfaceVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.surfaceVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.background,
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.pop(context);
              setState(() {
                _refreshKey++;
              });
            },
            child: Text(
              'Clear',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text.trim();
              });
              Navigator.pop(context);
              setState(() {
                _refreshKey++;
              });
            },
            child: Text(
              'Search',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFilterScreen(
          selectedMonth: _selectedMonth,
          initialFilter: _activeFilter,
        ),
      ),
    );

    if (result != null) {
      final filter = result['filter'] as TransactionFilter?;
      print('Filter received from dialog: $filter');
      if (filter != null) {
        print(
          'Filter details: Income: ${filter.selectedIncomeCategories}, Expense: ${filter.selectedExpenseCategories}, Accounts: ${filter.selectedAccountTypes}',
        );
        print('Has active filters: ${filter.hasActiveFilters}');
      }
      setState(() {
        _activeFilter = filter;
        if (result['month'] != null) {
          _selectedMonth = result['month'] as DateTime;
        }
        _refreshKey++; // Force refresh to apply filters
      });
    }
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        tabs: _tabs.map((tab) => Tab(text: tab, height: 40)).toList(),
      ),
    );
  }

  Widget _buildSummaryBar(Map<String, double> summary) {
    return Container(
      margin: const EdgeInsets.all(16),
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
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem(
            'Income',
            summary['income']!,
            AppColors.income,
            Icons.arrow_downward_rounded,
          ),
          Container(width: 1, height: 40, color: AppColors.surfaceVariant),
          _buildSummaryItem(
            'Expenses',
            summary['expense']!,
            AppColors.expense,
            Icons.arrow_upward_rounded,
          ),
          Container(width: 1, height: 40, color: AppColors.surfaceVariant),
          _buildSummaryItem(
            'Balance',
            summary['total']!,
            AppColors.textSecondary, // Light gray color for balance
            Icons.account_balance_wallet_rounded,
            showSign: true, // Show minus sign for negative balance
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double value,
    Color color,
    IconData icon, {
    bool showSign = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 12),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            showSign && value < 0
                ? '-Rs. ${_formatCurrency(value.abs())}'
                : 'Rs. ${_formatCurrency(value.abs())}',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentForTab(
    List<Transaction> transactions,
    Map<DateTime, List<Transaction>> groupedTransactions,
    List<DateTime> sortedDates,
    Map<String, double> summary,
  ) {
    switch (_tabController.index) {
      case 1: // Calendar
        return _buildCalendarView(transactions);
      case 2: // Monthly
        return _buildMonthlyView(transactions);
      case 3: // Total
        return _buildTotalView(summary);
      default: // Daily (0) and others
        if (transactions.isEmpty) {
          return _buildEmptyState();
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dayTransactions = groupedTransactions[date]!
              ..sort((a, b) => b.date.compareTo(a.date));
            return _buildDateGroup(date, dayTransactions);
          },
        );
    }
  }

  // Monthly View
  Widget _buildMonthlyView(List<Transaction> allTransactions) {
    final yearlyData = _getYearlyData(allTransactions);

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // Current month with weekly breakdown
        _buildCurrentMonthSection(allTransactions),
        // Previous months
        ...yearlyData.entries.map(
          (entry) => _buildMonthRow(entry.key, entry.value),
        ),
      ],
    );
  }

  Map<String, Map<String, double>> _getYearlyData(
    List<Transaction> allTransactions,
  ) {
    final months = <String, Map<String, double>>{};
    final now = DateTime.now();

    // Get data for all months of the selected year (excluding current month)
    for (int month = 12; month >= 1; month--) {
      if (_selectedMonth.year == now.year && month >= now.month) continue;
      if (_selectedMonth.year > now.year) continue;

      final monthTransactions = allTransactions
          .where(
            (t) => t.date.year == _selectedMonth.year && t.date.month == month,
          )
          .toList();

      if (monthTransactions.isEmpty &&
          month > now.month &&
          _selectedMonth.year == now.year) {
        continue;
      }

      final income = monthTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);
      final expense = monthTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      final monthName = DateFormat(
        'MMM',
      ).format(DateTime(_selectedMonth.year, month));
      months[monthName] = {
        'income': income,
        'expense': expense,
        'total': income - expense,
      };
    }

    return months;
  }

  Widget _buildCurrentMonthSection(List<Transaction> allTransactions) {
    final now = DateTime.now();
    final currentMonthTransactions = allTransactions
        .where(
          (t) =>
              t.date.year == _selectedMonth.year && t.date.month == now.month,
        )
        .toList();

    final income = currentMonthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = currentMonthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final total = income - expense;

    final monthName = DateFormat('MMM').format(now);
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    // Build weekly breakdown
    final weeks = _getWeeklyBreakdown(
      currentMonthTransactions,
      firstDay,
      lastDay,
    );

    return Column(
      children: [
        // Month header
        _buildMonthRowContent(
          monthName,
          '${now.month}.1 ~ ${now.month}.${lastDay.day}',
          income,
          expense,
          total,
          isHighlighted: false,
        ),
        // Weekly breakdown
        ...weeks.map((week) => _buildWeekRow(week)),
      ],
    );
  }

  List<Map<String, dynamic>> _getWeeklyBreakdown(
    List<Transaction> transactions,
    DateTime firstDay,
    DateTime lastDay,
  ) {
    final weeks = <Map<String, dynamic>>[];

    // Calculate week ranges
    var weekStart = lastDay;
    while (weekStart.isAfter(firstDay) ||
        weekStart.isAtSameMomentAs(firstDay)) {
      var weekEnd = weekStart;
      weekStart = weekStart.subtract(const Duration(days: 6));

      // Adjust if week start is before month start
      if (weekStart.isBefore(firstDay)) {
        weekStart = firstDay;
      }

      final weekTransactions = transactions.where((t) {
        final date = DateTime(t.date.year, t.date.month, t.date.day);
        return !date.isBefore(weekStart) && !date.isAfter(weekEnd);
      }).toList();

      final income = weekTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);
      final expense = weekTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      weeks.add({
        'startDay': weekStart.day,
        'startMonth': weekStart.month,
        'endDay': weekEnd.day,
        'endMonth': weekEnd.month,
        'income': income,
        'expense': expense,
        'total': income - expense,
      });

      weekStart = weekStart.subtract(const Duration(days: 1));
      if (weekStart.isBefore(firstDay)) break;
    }

    return weeks;
  }

  Widget _buildWeekRow(Map<String, dynamic> week) {
    final startStr =
        '${week['startMonth']}.${week['startDay'].toString().padLeft(2, '0')}';
    final endStr =
        '${week['endMonth']}.${week['endDay'].toString().padLeft(2, '0')}';
    final isHighlighted = _isCurrentWeek(week);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$startStr  ~  $endStr',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isHighlighted
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Rs. ${_formatCurrency(week['income'])}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.income,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. ${_formatCurrency(week['expense'])}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.expense,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Rs. ${_formatCurrency(week['total'])}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: week['total'] >= 0
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentWeek(Map<String, dynamic> week) {
    final now = DateTime.now();
    final weekStart = DateTime(
      _selectedMonth.year,
      week['startMonth'],
      week['startDay'],
    );
    final weekEnd = DateTime(
      _selectedMonth.year,
      week['endMonth'],
      week['endDay'],
    );
    return !now.isBefore(weekStart) && !now.isAfter(weekEnd);
  }

  Widget _buildMonthRow(String monthName, Map<String, double> data) {
    return _buildMonthRowContent(
      monthName,
      '',
      data['income']!,
      data['expense']!,
      data['total']!,
      isHighlighted: false,
    );
  }

  Widget _buildMonthRowContent(
    String label,
    String dateRange,
    double income,
    double expense,
    double total, {
    required bool isHighlighted,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (dateRange.isNotEmpty)
                  Text(
                    dateRange,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              'Rs. ${_formatCurrency(income)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.income,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. ${_formatCurrency(expense)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.expense,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Rs. ${_formatCurrency(total)}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: total >= 0
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Total View
  Widget _buildTotalView(Map<String, double> summary) {
    final allTransactions = StorageService.getAllTransactions();
    final monthTransactions = allTransactions
        .where(
          (t) =>
              t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month,
        )
        .toList();

    // Calculate expenses by account type
    final cashExpenses = monthTransactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              (t.accountType == AccountType.cash ||
                  t.accountType == AccountType.bank),
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    final cardExpenses = monthTransactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.accountType == AccountType.card,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    final transfers = monthTransactions
        .where((t) => t.type == TransactionType.transfer)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Calculate comparison with last month
    final lastMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    final lastMonthExpenses = allTransactions
        .where(
          (t) =>
              t.date.year == lastMonth.year &&
              t.date.month == lastMonth.month &&
              t.type == TransactionType.expense,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final comparisonPercent = lastMonthExpenses > 0
        ? ((summary['expense']! / lastMonthExpenses) * 100).round()
        : 0;

    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final dateRangeStr =
        '${_selectedMonth.month}.1.${_selectedMonth.year % 100}  ~  ${_selectedMonth.month}.${lastDay.day}.${_selectedMonth.year % 100}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Budget Section
        _buildBudgetSection(),
        const SizedBox(height: 16),

        // Accounts Section
        Container(
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
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Accounts',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dateRangeStr,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.surfaceVariant),

              // Stats
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Compared Expenses',
                      '(Last month)',
                      '$comparisonPercent%',
                      isPercentage: true,
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      'Expenses',
                      '(Cash, Accounts)',
                      'Rs. ${_formatCurrency(cashExpenses)}',
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      'Expenses',
                      '(Card)',
                      'Rs. ${_formatCurrency(cardExpenses)}',
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      'Transfer',
                      '(Cash, Accounts→)',
                      'Rs. ${_formatCurrency(transfers)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Export Button
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.income.withValues(alpha: 0.1),
                AppColors.income.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.income.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon!')),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.table_chart_rounded,
                    color: AppColors.income,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Export data to Excel',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.income,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildBudgetSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Budget',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Budget settings coming soon!')),
              );
            },
            child: Row(
              children: [
                Text(
                  'Budget Setting',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String sublabel,
    String value, {
    bool isPercentage = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              sublabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isPercentage
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPercentage ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first transaction',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // Calendar view methods
  Map<DateTime, List<Transaction>> _getTransactionsByDate(
    List<Transaction> transactions,
  ) {
    final map = <DateTime, List<Transaction>>{};

    for (var transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      map.putIfAbsent(date, () => []).add(transaction);
    }

    return map;
  }

  Map<String, double> _getDayTotals(
    DateTime day,
    List<Transaction> allTransactions,
  ) {
    final transactionsByDate = _getTransactionsByDate(allTransactions);
    final date = DateTime(day.year, day.month, day.day);
    final transactions = transactionsByDate[date] ?? [];

    double income = 0.0;
    double expense = 0.0;

    for (var transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        income += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        expense += transaction.amount;
      }
    }

    return {'income': income, 'expense': expense};
  }

  List<Transaction> _getTransactionsForDay(
    DateTime day,
    List<Transaction> allTransactions,
  ) {
    final transactionsByDate = _getTransactionsByDate(allTransactions);
    final date = DateTime(day.year, day.month, day.day);
    return transactionsByDate[date] ?? [];
  }

  Widget _buildCalendarView(List<Transaction> allTransactions) {
    final transactionsByDate = _getTransactionsByDate(allTransactions);
    final selectedDayTransactions = _getTransactionsForDay(
      _selectedDay,
      allTransactions,
    );

    return Column(
      children: [
        // Calendar Grid
        Expanded(
          child: _buildCalendarGrid(transactionsByDate, allTransactions),
        ),
        // Selected Day Transactions
        if (selectedDayTransactions.isNotEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.primaryLight.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM dd, yyyy').format(_selectedDay),
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: selectedDayTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionItem(
                        selectedDayTransactions[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarGrid(
    Map<DateTime, List<Transaction>> transactionsByDate,
    List<Transaction> allTransactions,
  ) {
    // Get the first day of the month and calculate calendar grid
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    // Days of week header
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      children: [
        // Week day headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: weekDays.map((day) {
              final isWeekend = day == 'Sun' || day == 'Sat';
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isWeekend
                          ? AppColors.secondary
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Calendar grid
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.65,
              ),
              itemCount: 42, // 6 weeks x 7 days
              itemBuilder: (context, index) {
                final dayOffset = index - firstWeekday;

                if (dayOffset < 0 || dayOffset >= daysInMonth) {
                  // Previous or next month days
                  DateTime otherDate;
                  if (dayOffset < 0) {
                    final prevMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month,
                      0,
                    );
                    otherDate = DateTime(
                      prevMonth.year,
                      prevMonth.month,
                      prevMonth.day + dayOffset + 1,
                    );
                  } else {
                    otherDate = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month,
                      dayOffset + 1,
                    );
                  }

                  final dayTotals = _getDayTotals(otherDate, allTransactions);

                  return _buildCalendarDay(
                    otherDate.day,
                    dayTotals['income']!,
                    dayTotals['expense']!,
                    isCurrentMonth: false,
                    isToday: false,
                    isSelected: false,
                    isSunday: index % 7 == 0,
                    onTap: null,
                  );
                }

                final currentDate = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month,
                  dayOffset + 1,
                );
                final dayTotals = _getDayTotals(currentDate, allTransactions);
                final isToday = _isToday(currentDate);
                final isSelected = _isSameDay(currentDate, _selectedDay);

                return _buildCalendarDay(
                  dayOffset + 1,
                  dayTotals['income']!,
                  dayTotals['expense']!,
                  isCurrentMonth: true,
                  isToday: isToday,
                  isSelected: isSelected,
                  isSunday: index % 7 == 0,
                  onTap: () {
                    setState(() {
                      _selectedDay = currentDate;
                    });
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildCalendarDay(
    int day,
    double income,
    double expense, {
    required bool isCurrentMonth,
    required bool isToday,
    required bool isSelected,
    required bool isSunday,
    VoidCallback? onTap,
  }) {
    final formatter = NumberFormat('#,##0', 'en_US');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryLight],
                )
              : isToday
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primaryLight.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected || isToday
              ? null
              : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isToday
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.surfaceVariant.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day number
            Text(
              '$day',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isToday || isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : !isCurrentMonth
                    ? AppColors.textMuted.withValues(alpha: 0.3)
                    : isSunday
                    ? AppColors.secondary
                    : AppColors.textPrimary,
              ),
            ),
            // Income and expense amounts
            if (isCurrentMonth) ...[
              if (income > 0)
                Text(
                  formatter.format(income),
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.income,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (expense > 0)
                Text(
                  formatter.format(expense),
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.expense,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateGroup(DateTime date, List<Transaction> transactions) {
    // Sort transactions by time (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    final dayIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final dayExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final dayName = DateFormat('E').format(date); // Thu, Wed, etc.
    final dateStr = DateFormat('MM.yyyy').format(date); // 12.2025
    final dayNumber = date.day;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header with Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Date Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dayNumber $dayName $dateStr',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Daily Total (show expense if any, otherwise show income)
                Text(
                  dayExpense > 0
                      ? 'Rs. ${_formatCurrency(dayExpense)}'
                      : dayIncome > 0
                      ? 'Rs. ${_formatCurrency(dayIncome)}'
                      : 'Rs. 0.00',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: dayExpense > 0
                        ? AppColors.expense
                        : dayIncome > 0
                        ? AppColors.income
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Transactions List
          ...transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;
            final isLast = index == transactions.length - 1;
            return _buildTransactionItemInCard(transaction, isLast: isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionItemInCard(
    Transaction transaction, {
    bool isLast = false,
  }) {
    final emoji = DefaultCategories.getCategoryEmoji(
      transaction.category,
      isIncome: transaction.type == TransactionType.income,
    );

    final accountLabel = _getAccountLabel(transaction);

    return InkWell(
      onTap: () async {
        final result = await context.goToEditTransaction<bool>(transaction);

        if (result == true) {
          // Add small delay to ensure storage update completes
          await Future.delayed(const Duration(milliseconds: 100));

          // Verify transaction was updated
          StorageService.getTransaction(transaction.id);

          setState(() {
            _refreshKey++; // Force FutureBuilder to refresh
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            // Category Icon/Emoji
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: transaction.type == TransactionType.income
                    ? AppColors.income.withValues(alpha: 0.1)
                    : transaction.type == TransactionType.expense
                    ? AppColors.expense.withValues(alpha: 0.1)
                    : AppColors.transfer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: emoji.isNotEmpty
                    ? Text(emoji, style: const TextStyle(fontSize: 18))
                    : Icon(
                        transaction.type == TransactionType.income
                            ? Icons.arrow_downward_rounded
                            : transaction.type == TransactionType.expense
                            ? Icons.arrow_upward_rounded
                            : Icons.swap_horiz_rounded,
                        color: transaction.type == TransactionType.income
                            ? AppColors.income
                            : transaction.type == TransactionType.expense
                            ? AppColors.expense
                            : AppColors.transfer,
                        size: 18,
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Description and Account
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category name (e.g., "Food snacks", "Vehicle Fuel")
                  Text(
                    transaction.category ?? 'Other',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Description (title)
                  Text(
                    transaction.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Account type
                  Text(
                    accountLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              'Rs. ${_formatCurrency(transaction.amount)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: transaction.type == TransactionType.income
                    ? AppColors.income
                    : AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final emoji = DefaultCategories.getCategoryEmoji(
      transaction.category,
      isIncome: transaction.type == TransactionType.income,
    );

    final subcategory = _getSubcategory(transaction);

    return InkWell(
      onTap: () async {
        final result = await context.goToEditTransaction<bool>(transaction);

        if (result == true) {
          // Add small delay to ensure storage update completes
          await Future.delayed(const Duration(milliseconds: 100));

          // Verify transaction was updated
          StorageService.getTransaction(transaction.id);

          setState(() {
            _refreshKey++; // Force FutureBuilder to refresh
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.surfaceVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: transaction.type == TransactionType.income
                    ? AppColors.income.withValues(alpha: 0.1)
                    : transaction.type == TransactionType.expense
                    ? AppColors.expense.withValues(alpha: 0.1)
                    : AppColors.transfer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: emoji.isNotEmpty
                    ? Text(emoji, style: const TextStyle(fontSize: 20))
                    : Icon(
                        transaction.type == TransactionType.income
                            ? Icons.arrow_downward_rounded
                            : transaction.type == TransactionType.expense
                            ? Icons.arrow_upward_rounded
                            : Icons.swap_horiz_rounded,
                        color: transaction.type == TransactionType.income
                            ? AppColors.income
                            : transaction.type == TransactionType.expense
                            ? AppColors.expense
                            : AppColors.transfer,
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
                    transaction.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        transaction.category ?? 'Other',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (subcategory.isNotEmpty) ...[
                        Text(
                          ' • $subcategory',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              'Rs. ${_formatCurrency(transaction.amount)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: transaction.type == TransactionType.income
                    ? AppColors.income
                    : AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubcategory(Transaction transaction) {
    // Try to match category to get subcategory hint
    if (transaction.category == null) return '';

    final category = DefaultCategories.getCategoryByName(
      transaction.category!,
      isIncome: transaction.type == TransactionType.income,
    );

    if (category != null && category.subcategories.isNotEmpty) {
      // Return first matching subcategory or empty
      return category.subcategories.first;
    }
    return '';
  }

  String _getAccountLabel(Transaction transaction) {
    if (transaction.type == TransactionType.transfer) {
      return '${transaction.fromAccount ?? ''} → ${transaction.toAccount ?? ''}';
    }

    switch (transaction.accountType) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.card:
        return 'Card';
      case AccountType.bank:
        return 'Accounts';
      case AccountType.other:
        return 'Accounts';
    }
  }
}
