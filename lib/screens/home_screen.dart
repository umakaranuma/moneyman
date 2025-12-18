import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import 'add_edit_transaction_screen.dart';
import 'notes_screen.dart';
import 'sms_transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final List<String> _tabs = ['Daily', 'Calendar', 'Monthly', 'Total', 'Note'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;

    if (_tabController.index == 4) {
      // Note tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotesScreen()),
      ).then((_) {
        _tabController.animateTo(0);
        setState(() {});
      });
    }
    setState(() {});
  }

  void _refreshData() {
    setState(() {});
  }

  List<Transaction> _getFilteredTransactions() {
    final allTransactions = StorageService.getAllTransactions();

    switch (_tabController.index) {
      case 0: // Daily - show all transactions for current month grouped by date
      case 2: // Monthly - same as daily but for selected month
        return allTransactions.where((t) {
          return t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month;
        }).toList();
      case 3: // Total
        return allTransactions;
      default:
        return allTransactions.where((t) {
          return t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month;
        }).toList();
    }
  }

  Map<String, double> _getSummary() {
    List<Transaction> transactions;

    // For Monthly view, show yearly summary
    if (_tabController.index == 2) {
      final allTransactions = StorageService.getAllTransactions();
      transactions = allTransactions
          .where((t) => t.date.year == _selectedMonth.year)
          .toList();
    } else {
      transactions = _getFilteredTransactions();
    }

    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return {'income': income, 'expense': expense, 'total': income - expense};
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
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _getFilteredTransactions();
    final summary = _getSummary();
    final groupedTransactions = _groupTransactionsByDate(transactions);
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditTransactionScreen(),
            ),
          ).then((_) => _refreshData());
        },
        backgroundColor: AppColors.fab,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    // Show year only in Monthly view, month + year otherwise
    final headerText = _tabController.index == 2
        ? '${_selectedMonth.year}'
        : DateFormat('MMM yyyy').format(_selectedMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            onPressed: _previousMonth,
          ),
          Text(
            headerText,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            onPressed: _nextMonth,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppColors.income),
            tooltip: 'Import from SMS',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SmsTransactionsScreen(),
                ),
              ).then((_) => _refreshData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorColor: AppColors.tabIndicator,
        indicatorWeight: 3,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildSummaryBar(Map<String, double> summary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem(
            'Income',
            summary['income']!,
            AppColors.income,
            true,
          ),
          _buildSummaryItem(
            'Expenses',
            summary['expense']!,
            AppColors.expense,
            false,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrency(summary['total']!.abs()),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double value,
    Color color,
    bool isIncome,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          _formatCurrency(value),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
        return _buildCalendarView();
      case 2: // Monthly
        return _buildMonthlyView();
      case 3: // Total
        return _buildTotalView(summary);
      default: // Daily (0) and others
        if (transactions.isEmpty) {
          return _buildEmptyState();
        }
        return ListView.builder(
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
  Widget _buildMonthlyView() {
    final allTransactions = StorageService.getAllTransactions();
    final yearlyData = _getYearlyData(allTransactions);

    return ListView(
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
          _selectedMonth.year == now.year)
        continue;

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.surface : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$startStr  ~  $endStr',
              style: TextStyle(
                fontSize: 14,
                color: isHighlighted
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Rs. ${_formatCurrency(week['income'])}',
              style: const TextStyle(fontSize: 14, color: AppColors.income),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. ${_formatCurrency(week['expense'])}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.expense,
                  ),
                ),
                Text(
                  'Rs. ${_formatCurrency(week['total'])}',
                  style: TextStyle(
                    fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.surface : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
        ),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (dateRange.isNotEmpty)
                  Text(
                    dateRange,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              'Rs. ${_formatCurrency(income)}',
              style: const TextStyle(fontSize: 14, color: AppColors.income),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. ${_formatCurrency(expense)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.expense,
                  ),
                ),
                Text(
                  'Rs. ${_formatCurrency(total)}',
                  style: TextStyle(
                    fontSize: 11,
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Accounts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      dateRangeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.surfaceVariant),

              // Stats
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Compared Expenses',
                      '(Last month)',
                      '$comparisonPercent%',
                      isPercentage: true,
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow(
                      'Expenses',
                      '(Cash, Accounts)',
                      'Rs. ${_formatCurrency(cashExpenses)}',
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow(
                      'Expenses',
                      '(Card)',
                      'Rs. ${_formatCurrency(cardExpenses)}',
                    ),
                    const SizedBox(height: 12),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              // TODO: Implement export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon!')),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_chart_outlined,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Export data to Excel',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(
                Icons.pie_chart_outline,
                color: AppColors.textPrimary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Budget',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              // TODO: Navigate to budget settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Budget settings coming soon!')),
              );
            },
            child: const Row(
              children: [
                Text(
                  'Budget Setting',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
                Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
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
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              sublabel,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
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
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions',
            style: TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add your first transaction',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // Calendar view methods
  Map<DateTime, List<Transaction>> _getTransactionsByDate() {
    final transactions = StorageService.getAllTransactions();
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

  Map<String, double> _getDayTotals(DateTime day) {
    final transactionsByDate = _getTransactionsByDate();
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

  List<Transaction> _getTransactionsForDay(DateTime day) {
    final transactionsByDate = _getTransactionsByDate();
    final date = DateTime(day.year, day.month, day.day);
    return transactionsByDate[date] ?? [];
  }

  Widget _buildCalendarView() {
    final transactionsByDate = _getTransactionsByDate();
    final selectedDayTransactions = _getTransactionsForDay(_selectedDay);

    return Column(
      children: [
        // Calendar Grid
        Expanded(child: _buildCalendarGrid(transactionsByDate)),
        // Selected Day Transactions
        if (selectedDayTransactions.isNotEmpty)
          Container(
            height: 200,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.surfaceVariant, width: 1),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: AppColors.surfaceVariant,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDay),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: weekDays.map((day) {
              final isWeekend = day == 'Sun' || day == 'Sat';
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      color: isWeekend
                          ? AppColors.expense
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Calendar grid
        Expanded(
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

                final dayTotals = _getDayTotals(otherDate);

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
              final dayTotals = _getDayTotals(currentDate);
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
    final formatter = NumberFormat('#,##0.00', 'en_US');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.textPrimary
                : AppColors.surfaceVariant.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 0.5,
          ),
          color: isSelected ? AppColors.surface : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day number
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: !isCurrentMonth
                      ? AppColors.textMuted.withValues(alpha: 0.3)
                      : isSunday
                      ? AppColors.expense
                      : AppColors.textPrimary,
                ),
              ),
            ),
            // Income and expense amounts
            if (isCurrentMonth) ...[
              if (income > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 2, right: 2),
                  child: Text(
                    formatter.format(income),
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.income,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (expense > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 2, right: 2),
                  child: Text(
                    formatter.format(expense),
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.expense,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateGroup(DateTime date, List<Transaction> transactions) {
    final dayIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final dayExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final dayName = DateFormat('E').format(date);
    final dateStr = DateFormat('MM.yyyy').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surfaceVariant,
          child: Row(
            children: [
              Text(
                '${date.day}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dayName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Rs. ${_formatCurrency(dayIncome)}',
                style: const TextStyle(fontSize: 12, color: AppColors.income),
              ),
              const SizedBox(width: 24),
              Text(
                'Rs. ${_formatCurrency(dayExpense)}',
                style: const TextStyle(fontSize: 12, color: AppColors.expense),
              ),
            ],
          ),
        ),
        // Transactions
        ...transactions.map((t) => _buildTransactionItem(t)),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final emoji = DefaultCategories.getCategoryEmoji(
      transaction.category,
      isIncome: transaction.type == TransactionType.income,
    );

    final subcategory = _getSubcategory(transaction);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AddEditTransactionScreen(transaction: transaction),
          ),
        ).then((_) => _refreshData());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Category with emoji
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (emoji.isNotEmpty)
                        Text(emoji, style: const TextStyle(fontSize: 14)),
                      if (emoji.isNotEmpty) const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          transaction.category ?? 'Other',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (subcategory.isNotEmpty)
                    Text(
                      subcategory,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),

            // Title and Account
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _getAccountLabel(transaction),
                    style: const TextStyle(
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
