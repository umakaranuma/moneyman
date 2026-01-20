import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/sms_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  final bool showGraphsView;

  const StatsScreen({super.key, this.showGraphsView = false});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  String _periodType = 'Monthly'; // Monthly, Weekly, Daily
  int _refreshKey = 0; // Key to force FutureBuilder refresh
  Map<String, Map<String, double>> _cachedMonthlyData = {};
  List<Transaction> _cachedTransactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 1; // Start on Expenses tab
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, refresh to get new transactions
      setState(() {
        _refreshKey++;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible (e.g., returning from other screens)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _refreshKey++;
        });
      }
    });
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

  Future<List<Transaction>> _getAllTransactions() async {
    // Get manually added transactions
    final manualTransactions = StorageService.getAllTransactions();

    // Get SMS transactions and convert them to Transaction objects
    final smsTransactions = await _getSmsTransactionsAsTransactions();

    // Combine both lists using the same logic as home screen
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

    return uniqueTransactions.values.toList();
  }

  Future<List<Transaction>> _getFilteredTransactions() async {
    final allTransactions = await _getAllTransactions();

    // Filter by selected month
    return allTransactions.where((t) {
      return t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month;
    }).toList();
  }

  Future<Map<String, Map<String, double>>> _getMonthlyData() async {
    final allTransactions = await _getAllTransactions();

    // Get last 6 months of data
    final now = DateTime.now();
    final monthlyData = <String, Map<String, double>>{};
    double cumulativeBalance = 0.0;

    // Process months in chronological order (oldest first)
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM yyyy').format(monthDate);

      final monthTransactions = allTransactions.where((t) {
        return t.date.year == monthDate.year && t.date.month == monthDate.month;
      }).toList();

      double income = 0;
      double expense = 0;

      // Calculate income and expenses for this month
      for (var t in monthTransactions) {
        if (t.type == TransactionType.income) {
          income += t.amount;
          cumulativeBalance += t.amount;
        } else if (t.type == TransactionType.expense) {
          expense += t.amount;
          cumulativeBalance -= t.amount;
        }
      }

      monthlyData[monthKey] = {
        'income': income,
        'expense': expense,
        'balance': cumulativeBalance,
      };
    }

    return monthlyData;
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

      // Convert ParsedSmsTransaction to Transaction using the same logic as home screen
      return smsTransactions.map((smsT) {
        // Use the same transfer detection logic as home screen
        final isTransfer = _isSmsTransactionTransfer(smsT);

        // Extract account information for transfers
        String? fromAccount;
        String? toAccount;

        if (isTransfer) {
          if (smsT.isCredit) {
            toAccount = smsT.accountNumber ?? 'Bank Account';
            fromAccount = 'Cash';
          } else {
            fromAccount = smsT.accountNumber ?? 'Bank Account';
            final upperMessage = smsT.rawMessage.toUpperCase();
            if (upperMessage.contains('TO ACCOUNT') ||
                upperMessage.contains('TRANSFERRED TO') ||
                upperMessage.contains('NEFT') ||
                upperMessage.contains('RTGS') ||
                upperMessage.contains('IMPS') ||
                upperMessage.contains('UPI')) {
              toAccount =
                  _extractRecipientAccount(smsT.rawMessage) ?? 'Other Account';
            } else {
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
      return [];
    }
  }

  /// Detect if SMS transaction is a transfer (same logic as home screen)
  bool _isSmsTransactionTransfer(ParsedSmsTransaction smsT) {
    final upperMessage = smsT.rawMessage.toUpperCase();

    if (smsT.isCredit) {
      final cashDepositKeywords = [
        'CASH DEPOSIT',
        'CASH DEPOSITED',
        'DEPOSIT CASH',
        'CASH DEPOSITED TO',
      ];
      return cashDepositKeywords.any(
        (keyword) => upperMessage.contains(keyword),
      );
    }

    // For debits - check for transfers FIRST
    if (upperMessage.contains('ATM') &&
        (upperMessage.contains('WITHDRAWAL') ||
            upperMessage.contains('WITHDRAWN'))) {
      return true;
    }

    if (RegExp(
      r'ATM\s+WITHDRAW(?:AL|N)',
      caseSensitive: false,
    ).hasMatch(upperMessage)) {
      return true;
    }

    if (upperMessage.contains('CASH WITHDRAWAL') ||
        upperMessage.contains('CASH WITHDRAWN')) {
      return true;
    }

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

    // Check for expenses
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

    final isActualExpense = expenseKeywords.any(
      (keyword) => upperMessage.contains(keyword),
    );
    if (isActualExpense) {
      return false;
    }

    return false;
  }

  /// Extract recipient account number from SMS message
  String? _extractRecipientAccount(String message) {
    final upperMessage = message.toUpperCase();
    final patterns = [
      RegExp(
        r'TO\s+(?:ACCOUNT|A/C|ACCT)[:\s]*[X*]*([0-9]{4,})',
        caseSensitive: false,
      ),
      RegExp(r'TRANSFERRED\s+TO[:\s]*[X*]*([0-9]{4,})', caseSensitive: false),
      RegExp(r'BEN(?:EFICIARY)?[:\s]*[X*]*([0-9]{4,})', caseSensitive: false),
      RegExp(r'TO\s+([A-Z0-9]+@[A-Z]+)', caseSensitive: false),
      RegExp(r'TO[:\s]+[A-Z\s]*([0-9]{4,})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(upperMessage);
      if (match != null && match.group(1) != null) {
        final account = match.group(1)!;
        if (account.contains('@')) {
          return account;
        } else {
          return '****${account.length > 4 ? account.substring(account.length - 4) : account}';
        }
      }
    }
    return null;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Show graphs view if showGraphsView is true
    if (widget.showGraphsView) {
      return FutureBuilder<Map<String, Map<String, double>>>(
        key: ValueKey(_refreshKey), // Force refresh when key changes
        future: _getMonthlyData(),
        builder: (context, snapshot) {
          final hasCachedData = _cachedMonthlyData.isNotEmpty;
          final isWaiting =
              snapshot.connectionState == ConnectionState.waiting;
          if (isWaiting && !snapshot.hasData && !hasCachedData) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                bottom: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            _cachedMonthlyData = snapshot.data ?? {};
          }
          final monthlyData = snapshot.data ?? _cachedMonthlyData;

          // Get current month data for balance display
          final currentMonthKey = DateFormat('MMM yyyy').format(_selectedMonth);
          final currentMonthData = monthlyData[currentMonthKey] ?? {};
          final balance = currentMonthData['balance'] ?? 0.0;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Header
                  _buildTotalStatsHeader(balance),

                  // Graphs Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Balance Line Graph
                          _buildBalanceLineGraph(monthlyData),
                          const SizedBox(height: 24),
                          // Income vs Expenses Bar Chart
                          _buildIncomeExpenseBarChart(monthlyData),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Show analytics view (pie chart) for bottom navigation
    return FutureBuilder<List<Transaction>>(
      key: ValueKey(_refreshKey), // Force refresh when key changes
      future: _getFilteredTransactions(),
      builder: (context, snapshot) {
        final hasCachedData = _cachedTransactions.isNotEmpty;
        final isWaiting =
            snapshot.connectionState == ConnectionState.waiting;
        if (isWaiting && !snapshot.hasData && !hasCachedData) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              bottom: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          _cachedTransactions = snapshot.data ?? [];
        }
        final transactions = snapshot.data ?? _cachedTransactions;

        final income = transactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);

        final expense = transactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);

        // Category breakdown for expenses
        final categoryExpenses = <String, double>{};
        for (var transaction in transactions) {
          if (transaction.type == TransactionType.expense &&
              transaction.category != null) {
            categoryExpenses[transaction.category!] =
                (categoryExpenses[transaction.category!] ?? 0) +
                transaction.amount;
          }
        }

        // Category breakdown for income
        final categoryIncome = <String, double>{};
        for (var transaction in transactions) {
          if (transaction.type == TransactionType.income &&
              transaction.category != null) {
            categoryIncome[transaction.category!] =
                (categoryIncome[transaction.category!] ?? 0) +
                transaction.amount;
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Income/Expenses Tab Bar
                _buildTabBar(income, expense),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Income Tab
                      _buildStatsContent(categoryIncome, income, true),
                      // Expenses Tab
                      _buildStatsContent(categoryExpenses, expense, false),
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

  Widget _buildHeader() {
    final monthYear = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildCircleButton(
            icon: Icons.chevron_left_rounded,
            onTap: _previousMonth,
          ),
          const SizedBox(width: 8),
          Text(
            monthYear,
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
          GestureDetector(
            onTap: _showPeriodPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primaryLight.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _periodType,
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalStatsHeader(double balance) {
    final monthYear = DateFormat('MMM yyyy').format(_selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceVariant, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Total Stats',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _buildCircleButton(
                icon: Icons.chevron_left_rounded,
                onTap: _previousMonth,
              ),
              const SizedBox(width: 8),
              Text(
                monthYear,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                icon: Icons.chevron_right_rounded,
                onTap: _nextMonth,
              ),
            ],
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

  void _showPeriodPicker() {
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
                'Select Period',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _buildPeriodOption('Daily', Icons.today_rounded),
              _buildPeriodOption('Weekly', Icons.view_week_rounded),
              _buildPeriodOption('Monthly', Icons.calendar_month_rounded),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(String period, IconData icon) {
    final isSelected = _periodType == period;
    return GestureDetector(
      onTap: () {
        setState(() => _periodType = period);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primaryLight.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              period,
              style: GoogleFonts.inter(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(double income, double expense) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _tabController.index == 0
                      ? LinearGradient(
                          colors: [
                            AppColors.income.withValues(alpha: 0.15),
                            AppColors.income.withValues(alpha: 0.05),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _tabController.index == 0
                                ? AppColors.income
                                : AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Income',
                          style: GoogleFonts.inter(
                            color: _tabController.index == 0
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: _tabController.index == 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rs. ${_formatCurrency(income)}',
                      style: GoogleFonts.inter(
                        color: _tabController.index == 0
                            ? AppColors.income
                            : AppColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _tabController.index == 1
                      ? LinearGradient(
                          colors: [
                            AppColors.expense.withValues(alpha: 0.15),
                            AppColors.expense.withValues(alpha: 0.05),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _tabController.index == 1
                                ? AppColors.expense
                                : AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Expenses',
                          style: GoogleFonts.inter(
                            color: _tabController.index == 1
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: _tabController.index == 1
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rs. ${_formatCurrency(expense)}',
                      style: GoogleFonts.inter(
                        color: _tabController.index == 1
                            ? AppColors.expense
                            : AppColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(
    Map<String, double> categoryData,
    double total,
    bool isIncome,
  ) {
    if (categoryData.isEmpty) {
      return _buildEmptyState(isIncome);
    }

    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Pie Chart
          _buildPieChartSection(sortedEntries, total, isIncome),

          const SizedBox(height: 24),

          // Category breakdown header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isIncome
                          ? [
                              AppColors.income,
                              AppColors.income.withValues(alpha: 0.7),
                            ]
                          : [
                              AppColors.expense,
                              AppColors.expense.withValues(alpha: 0.7),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Category Breakdown',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Category List
          ...sortedEntries.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            final percentage = (entry.value / total * 100);
            final color = AppColors
                .categoryColors[index % AppColors.categoryColors.length];
            final emoji = DefaultCategories.getCategoryEmoji(
              entry.key,
              isIncome: isIncome,
            );

            return _buildCategoryItem(
              emoji: emoji,
              name: entry.key,
              amount: entry.value,
              percentage: percentage,
              color: color,
              index: index,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isIncome) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isIncome
                    ? [
                        AppColors.income.withValues(alpha: 0.15),
                        AppColors.income.withValues(alpha: 0.05),
                      ]
                    : [
                        AppColors.expense.withValues(alpha: 0.15),
                        AppColors.expense.withValues(alpha: 0.05),
                      ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pie_chart_outline_rounded,
              size: 56,
              color: isIncome
                  ? AppColors.income.withValues(alpha: 0.5)
                  : AppColors.expense.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No ${isIncome ? 'income' : 'expense'} data',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your ${isIncome ? 'income' : 'expenses'}',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceLineGraph(Map<String, Map<String, double>> monthlyData) {
    final months = monthlyData.keys.toList();
    if (months.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
          ),
        ),
      );
    }

    final balances = months
        .map((m) => monthlyData[m]!['balance'] ?? 0.0)
        .toList();
    final maxBalance = balances.isEmpty
        ? 1000.0
        : (balances.reduce((a, b) => a > b ? a : b) * 1.2).clamp(
            100.0,
            double.infinity,
          );
    final minBalance = balances.isEmpty
        ? 0.0
        : balances.reduce((a, b) => a < b ? a : b) * 0.8;

    // Create spots for the line chart
    final spots = balances.asMap().entries.map((entry) {
      final index = entry.key;
      final balance = entry.value;
      return FlSpot(index.toDouble(), balance);
    }).toList();

    // Calculate horizontal interval, ensuring it's never zero
    final horizontalInterval = (maxBalance / 4).clamp(1.0, double.infinity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.surfaceVariant,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _formatCurrency(value),
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < months.length) {
                          final month = months[value.toInt()];
                          return Text(
                            month.split(' ')[0],
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: AppColors.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minY: minBalance < 0 ? minBalance : 0,
                maxY: maxBalance,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Balance values below graph
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: months.asMap().entries.map((entry) {
              final index = entry.key;
              final month = entry.value;
              final balance = balances[index];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${month.split(' ')[0]}: ',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    _formatCurrency(balance),
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseBarChart(
    Map<String, Map<String, double>> monthlyData,
  ) {
    final months = monthlyData.keys.toList();
    if (months.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
          ),
        ),
      );
    }

    final incomes = months
        .map((m) => monthlyData[m]!['income'] ?? 0.0)
        .toList();
    final expenses = months
        .map((m) => monthlyData[m]!['expense'] ?? 0.0)
        .toList();
    final allValues = [...incomes, ...expenses];
    final maxValue = allValues.isEmpty
        ? 1000.0
        : (allValues.reduce((a, b) => a > b ? a : b) * 1.2).clamp(
            100.0,
            double.infinity,
          );

    // Calculate horizontal interval, ensuring it's never zero
    final horizontalInterval = (maxValue / 7).clamp(1.0, double.infinity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Income vs Expenses',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.surfaceVariant,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _formatCurrency(value),
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < months.length) {
                          final month = months[value.toInt()];
                          return Text(
                            month.split(' ')[0],
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: months.asMap().entries.map((entry) {
                  final index = entry.key;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: incomes[index],
                        color: AppColors.income,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: expenses[index],
                        color: AppColors.expense,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }).toList(),
                maxY: maxValue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Income and Expense values below graph
          Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: months.asMap().entries.map((entry) {
                  final index = entry.key;
                  final month = entry.value;
                  final income = incomes[index];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.income,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${month.split(' ')[0]}: ',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _formatCurrency(income),
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: months.asMap().entries.map((entry) {
                  final index = entry.key;
                  final month = entry.value;
                  final expense = expenses[index];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.expense,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${month.split(' ')[0]}: ',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _formatCurrency(expense),
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(
    List<MapEntry<String, double>> entries,
    double total,
    bool isIncome,
  ) {
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isIncome ? AppColors.income : AppColors.expense).withValues(
            alpha: 0.1,
          ),
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
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 65,
                    sections: entries.asMap().entries.map((mapEntry) {
                      final index = mapEntry.key;
                      final entry = mapEntry.value;
                      final color =
                          AppColors.categoryColors[index %
                              AppColors.categoryColors.length];

                      return PieChartSectionData(
                        value: entry.value,
                        title: '',
                        color: color,
                        radius: 60,
                        badgeWidget: null,
                      );
                    }).toList(),
                  ),
                ),
                // Center content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isIncome ? AppColors.income : AppColors.expense)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIncome
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: isIncome ? AppColors.income : AppColors.expense,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rs. ${_formatCurrency(total)}',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Total ${isIncome ? 'Income' : 'Expense'}',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: entries.take(5).toList().asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final entry = mapEntry.value;
              final percentage = (entry.value / total * 100);
              final color = AppColors
                  .categoryColors[index % AppColors.categoryColors.length];

              return _buildLegendItem(entry.key, percentage, color);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, double percentage, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${label.length > 8 ? '${label.substring(0, 6)}...' : label} ${percentage.toStringAsFixed(0)}%',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem({
    required String emoji,
    required String name,
    required double amount,
    required double percentage,
    required Color color,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Emoji
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: emoji.isNotEmpty
                  ? Text(emoji, style: const TextStyle(fontSize: 20))
                  : Icon(Icons.category_rounded, color: color, size: 20),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Amount and Percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${_formatCurrency(amount)}',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
