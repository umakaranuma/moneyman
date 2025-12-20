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
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  String _periodType = 'Monthly'; // Monthly, Weekly, Daily

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 1; // Start on Expenses tab
    _tabController.addListener(() => setState(() {}));
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

  Future<List<Transaction>> _getFilteredTransactions() async {
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

    final combinedTransactions = uniqueTransactions.values.toList();

    // Filter by selected month
    return combinedTransactions.where((t) {
      return t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month;
    }).toList();
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
    return FutureBuilder<List<Transaction>>(
      future: _getFilteredTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        final transactions = snapshot.data ?? [];

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
