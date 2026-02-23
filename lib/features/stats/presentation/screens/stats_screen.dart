import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/transaction.dart';
import '../../../../models/category.dart';
import '../helpers/stats_calculator.dart';
import '../helpers/stats_data_source.dart';
import '../widgets/stats_header.dart';
import '../widgets/income_expense_segment.dart';
import '../widgets/pie_chart_card.dart';
import '../widgets/balance_line_chart_card.dart';
import '../widgets/income_expense_bar_chart_card.dart';
import '../widgets/category_item_tile.dart';
import '../widgets/empty_stats_view.dart';

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
  int _refreshKey = 0;
  Map<String, Map<String, double>> _cachedMonthlyData = {};
  List<Transaction> _cachedTransactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 1;
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
      setState(() => _refreshKey++);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: widget.showGraphsView
            ? _GraphsView(
                selectedMonth: _selectedMonth,
                refreshKey: _refreshKey,
                cachedMonthlyData: _cachedMonthlyData,
                onPreviousMonth: _previousMonth,
                onNextMonth: _nextMonth,
                onData: (data) => _cachedMonthlyData = data,
              )
            : _AnalyticsView(
                selectedMonth: _selectedMonth,
                controller: _tabController,
                refreshKey: _refreshKey,
                cachedTransactions: _cachedTransactions,
                onPreviousMonth: _previousMonth,
                onNextMonth: _nextMonth,
                onData: (list) => _cachedTransactions = list,
              ),
      ),
    );
  }
}

class _GraphsView extends StatelessWidget {
  final DateTime selectedMonth;
  final int refreshKey;
  final Map<String, Map<String, double>> cachedMonthlyData;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final void Function(Map<String, Map<String, double>>) onData;

  const _GraphsView({
    required this.selectedMonth,
    required this.refreshKey,
    required this.cachedMonthlyData,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onData,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, double>>>(
      key: ValueKey(refreshKey),
      future: StatsDataSource.getMonthlyData(),
      builder: (context, snapshot) {
        if (snapshot.hasData) onData(snapshot.data!);
        final monthlyData = cachedMonthlyData.isNotEmpty
            ? cachedMonthlyData
            : (snapshot.data ?? {});
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatsHeader(
              title: 'Total Stats',
              month: selectedMonth,
              onPrevious: onPreviousMonth,
              onNext: onNextMonth,
              showBackButton: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 88,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    BalanceLineChartCard(monthlyData: monthlyData),
                    const SizedBox(height: 24),
                    IncomeExpenseBarChartCard(monthlyData: monthlyData),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  final DateTime selectedMonth;
  final TabController controller;
  final int refreshKey;
  final List<Transaction> cachedTransactions;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final void Function(List<Transaction>) onData;

  const _AnalyticsView({
    required this.selectedMonth,
    required this.controller,
    required this.refreshKey,
    required this.cachedTransactions,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onData,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Transaction>>(
      key: ValueKey('$refreshKey-${selectedMonth.year}-${selectedMonth.month}'),
      future: StatsDataSource.getFilteredTransactions(selectedMonth),
      builder: (context, snapshot) {
        if (snapshot.hasData) onData(snapshot.data!);
        final transactions = cachedTransactions.isNotEmpty
            ? cachedTransactions
            : (snapshot.data ?? <Transaction>[]);
        final totals = StatsCalculator.calculateIncomeExpense(transactions);
        final income = totals['income'] ?? 0.0;
        final expense = totals['expense'] ?? 0.0;

        return Column(
          children: [
            StatsHeader(
              title: 'Stats',
              month: selectedMonth,
              onPrevious: onPreviousMonth,
              onNext: onNextMonth,
              showBackButton: false,
            ),
            IncomeExpenseSegment(
              controller: controller,
              income: income,
              expense: expense,
            ),
            Expanded(
              child: TabBarView(
                controller: controller,
                children: [
                  _AnalyticsTabContent(
                    transactions: transactions,
                    isIncome: true,
                  ),
                  _AnalyticsTabContent(
                    transactions: transactions,
                    isIncome: false,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnalyticsTabContent extends StatelessWidget {
  final List<Transaction> transactions;
  final bool isIncome;

  const _AnalyticsTabContent({
    required this.transactions,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final categoryData = StatsCalculator.categoryBreakdown(
      transactions,
      isIncome: isIncome,
    );
    final total = isIncome
        ? transactions
              .where((t) => t.type == TransactionType.income)
              .fold(0.0, (s, t) => s + t.amount)
        : transactions
              .where((t) => t.type == TransactionType.expense)
              .fold(0.0, (s, t) => s + t.amount);

    if (categoryData.isEmpty) {
      return EmptyStatsView(isIncome: isIncome);
    }

    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sections = buildPieSections(sortedEntries, total);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 88,
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          PieChartCard(total: total, sections: sections, isIncome: isIncome),
          const SizedBox(height: 24),
          _buildCategoryBreakdownHeader(),
          const SizedBox(height: 12),
          ...sortedEntries.asMap().entries.map((e) {
            final index = e.key;
            final entry = e.value;
            final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
            final color = AppColors
                .categoryColors[index % AppColors.categoryColors.length];
            final emoji = DefaultCategories.getCategoryEmoji(
              entry.key,
              isIncome: isIncome,
            );
            return CategoryItemTile(
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

  Widget _buildCategoryBreakdownHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(
            Icons.category_rounded,
            color: isIncome ? AppColors.income : AppColors.expense,
            size: 22,
          ),
          const SizedBox(width: 12),
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
