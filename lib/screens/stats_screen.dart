import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
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

  // Category colors matching the UI
  static const List<Color> _categoryColors = [
    Color(0xFFFF6B6B), // Coral red - Bike
    Color(0xFFFFB347), // Orange - Social Life
    Color(0xFFFFD93D), // Yellow - Apparel
    Color(0xFF9ACD32), // Yellow-green - Package
    Color(0xFF6BCB77), // Green - Food
    Color(0xFF4ECDC4), // Teal - Health
    Color(0xFF45B7D1), // Light blue - Household
    Color(0xFF4A9DFF), // Blue
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 1; // Start on Expenses tab
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

  List<Transaction> _getFilteredTransactions() {
    final allTransactions = StorageService.getAllTransactions();
    return allTransactions.where((t) {
      return t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month;
    }).toList();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _getFilteredTransactions();

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
            (categoryExpenses[transaction.category!] ?? 0) + transaction.amount;
      }
    }

    // Category breakdown for income
    final categoryIncome = <String, double>{};
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.income &&
          transaction.category != null) {
        categoryIncome[transaction.category!] =
            (categoryIncome[transaction.category!] ?? 0) + transaction.amount;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
  }

  Widget _buildHeader() {
    final monthYear = DateFormat('MMM yyyy').format(_selectedMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            onPressed: _previousMonth,
          ),
          Text(
            monthYear,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.textMuted),
              borderRadius: BorderRadius.circular(4),
            ),
            child: InkWell(
              onTap: () {
                _showPeriodPicker();
              },
              child: Row(
                children: [
                  Text(
                    _periodType,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textPrimary,
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

  void _showPeriodPicker() {
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
            children: [
              ListTile(
                title: const Text('Daily',
                    style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  setState(() => _periodType = 'Daily');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Weekly',
                    style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  setState(() => _periodType = 'Weekly');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Monthly',
                    style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  setState(() => _periodType = 'Monthly');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar(double income, double expense) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _tabController.animateTo(0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _tabController.index == 0
                          ? AppColors.income
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Income',
                      style: TextStyle(
                        color: _tabController.index == 0
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${_formatCurrency(income)}',
                      style: TextStyle(
                        color: _tabController.index == 0
                            ? AppColors.income
                            : AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _tabController.animateTo(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _tabController.index == 1
                          ? AppColors.expense
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Expenses',
                      style: TextStyle(
                        color: _tabController.index == 1
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${_formatCurrency(expense)}',
                      style: TextStyle(
                        color: _tabController.index == 1
                            ? AppColors.expense
                            : AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
      Map<String, double> categoryData, double total, bool isIncome) {
    if (categoryData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isIncome ? 'income' : 'expense'} data for this period',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      child: Column(
        children: [
          // Pie Chart
          SizedBox(
            height: 280,
            child: _buildPieChart(sortedEntries, total),
          ),

          // Category List
          ...sortedEntries.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            final percentage = (entry.value / total * 100);
            final color = _categoryColors[index % _categoryColors.length];
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
            );
          }),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPieChart(
      List<MapEntry<String, double>> entries, double total) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 70,
            sections: entries.asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final entry = mapEntry.value;
              final percentage = (entry.value / total * 100);
              final color = _categoryColors[index % _categoryColors.length];
              final emoji = DefaultCategories.getCategoryEmoji(entry.key);

              return PieChartSectionData(
                value: entry.value,
                title: '',
                color: color,
                radius: 80,
                badgeWidget: _buildChartBadge(emoji, entry.key, percentage),
                badgePositionPercentageOffset: 1.3,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChartBadge(String emoji, String name, double percentage) {
    // Only show badge for significant slices
    if (percentage < 5) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (emoji.isNotEmpty)
          Text(
            emoji,
            style: const TextStyle(fontSize: 12),
          ),
        Text(
          name.length > 8 ? '${name.substring(0, 6)}...' : name,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(1)} %',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Percentage Badge
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${percentage.toInt()}%',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Emoji and Name
          if (emoji.isNotEmpty)
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
          if (emoji.isNotEmpty) const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),

          const Spacer(),

          // Amount
          Text(
            'Rs. ${_formatCurrency(amount)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

