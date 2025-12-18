import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../core/router/app_router.dart';

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
      // Note tab - use GoRouter
      context.goToNotes();
      Future.delayed(const Duration(milliseconds: 100), () {
        _tabController.animateTo(0);
        setState(() {});
      });
    }
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
        bottom: false,
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
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      child: GestureDetector(
        onTap: () {
          context.goToAddTransaction();
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
            color: AppColors.textSecondary,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _buildGlassButton(
            icon: Icons.tune_rounded,
            color: AppColors.textSecondary,
            onTap: () {},
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
            AppColors.textPrimary, // White for Balance
            Icons.account_balance_wallet_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
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
            'Rs. ${_formatCurrency(value.abs())}',
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
  Widget _buildMonthlyView() {
    final allTransactions = StorageService.getAllTransactions();
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
    final dayIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final dayExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final dayName = DateFormat('E').format(date);
    final dateStr = DateFormat('MM.yyyy').format(date);
    final isToday = _isToday(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isToday
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primaryLight.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            color: isToday ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: isToday
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isToday
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        )
                      : null,
                  color: isToday ? null : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isToday ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isToday ? 'Today' : dayName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.income,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Rs. ${_formatCurrency(dayIncome)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.income,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.expense,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Rs. ${_formatCurrency(dayExpense)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
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
        context.goToEditTransaction(transaction);
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
            // Category with emoji
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

            // Title and Account
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

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                Text(
                  _getAccountLabel(transaction),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
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
