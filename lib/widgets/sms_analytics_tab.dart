import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/sms_service.dart';
import '../services/sms_analytics_service.dart';
import '../theme/app_theme.dart';
import 'sms_analytics_charts.dart';

class SmsAnalyticsTab extends StatefulWidget {
  final List<ParsedSmsTransaction> transactions;

  const SmsAnalyticsTab({super.key, required this.transactions});

  @override
  State<SmsAnalyticsTab> createState() => _SmsAnalyticsTabState();
}

class _SmsAnalyticsTabState extends State<SmsAnalyticsTab> {
  TimePeriod _selectedPeriod = TimePeriod.monthly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  List<ParsedSmsTransaction> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _updateFilteredTransactions();
  }

  @override
  void didUpdateWidget(SmsAnalyticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions) {
      _updateFilteredTransactions();
    }
  }

  void _updateFilteredTransactions() {
    setState(() {
      if (_selectedPeriod == TimePeriod.custom &&
          _customStartDate != null &&
          _customEndDate != null) {
        _filteredTransactions = SmsAnalyticsService.filterByDateRange(
          widget.transactions,
          _customStartDate!,
          _customEndDate!,
        );
      } else {
        // Filter by selected period (Daily/Weekly/Monthly)
        final now = DateTime.now();
        DateTime startDate;
        
        switch (_selectedPeriod) {
          case TimePeriod.daily:
            // Show last 30 days
            startDate = now.subtract(const Duration(days: 30));
            break;
          case TimePeriod.weekly:
            // Show last 12 weeks
            startDate = now.subtract(const Duration(days: 84));
            break;
          case TimePeriod.monthly:
            // Show last 12 months
            startDate = DateTime(now.year - 1, now.month, 1);
            break;
          case TimePeriod.custom:
            _filteredTransactions = List.from(widget.transactions);
            return;
        }
        
        _filteredTransactions = widget.transactions.where((t) {
          return t.date.isAfter(startDate.subtract(const Duration(days: 1)));
        }).toList();
      }
    });
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
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
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedPeriod = TimePeriod.custom;
        _updateFilteredTransactions();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use filtered transactions for all analytics
    final transactionsToAnalyze = _filteredTransactions;
    
    if (transactionsToAnalyze.isEmpty) {
      return _buildEmptyState();
    }

    final summaryStats = SmsAnalyticsService.getSummaryStats(transactionsToAnalyze);
    final bankBreakdown = SmsAnalyticsService.getBankBreakdown(transactionsToAnalyze);
    final creditDebitTrends = SmsAnalyticsService.getCreditDebitTrends(
      transactionsToAnalyze,
      _selectedPeriod,
    );
    final balanceOverTime = SmsAnalyticsService.getBalanceOverTime(
      transactionsToAnalyze,
      _selectedPeriod,
    );
    final transactionVolume = SmsAnalyticsService.getTransactionVolume(
      transactionsToAnalyze,
      _selectedPeriod,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Period Selector
          _buildTimePeriodSelector(),
          const SizedBox(height: 16),

          // Summary Cards
          _buildSummaryCards(summaryStats),
          const SizedBox(height: 20),

          // Bank Breakdown
          if (bankBreakdown.isNotEmpty) ...[
            BankBreakdownPieChart(bankData: bankBreakdown),
            const SizedBox(height: 20),
          ],

          // Credit vs Debit Trends
          if (creditDebitTrends.isNotEmpty) ...[
            CreditDebitTrendsChart(
              trends: creditDebitTrends,
              period: _selectedPeriod,
            ),
            const SizedBox(height: 20),
          ],

          // Balance Over Time
          if (balanceOverTime.isNotEmpty) ...[
            BalanceOverTimeChart(
              balanceData: balanceOverTime,
              period: _selectedPeriod,
            ),
            const SizedBox(height: 20),
          ],

          // Transaction Volume
          if (transactionVolume.isNotEmpty) ...[
            TransactionVolumeChart(
              volume: transactionVolume,
              period: _selectedPeriod,
            ),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTimePeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Daily', TimePeriod.daily),
          _buildPeriodButton('Weekly', TimePeriod.weekly),
          _buildPeriodButton('Monthly', TimePeriod.monthly),
          _buildPeriodButton('Custom', TimePeriod.custom),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, TimePeriod period) {
    final isSelected = _selectedPeriod == period;
    final isCustom = period == TimePeriod.custom &&
        _customStartDate != null &&
        _customEndDate != null;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (period == TimePeriod.custom) {
            _selectCustomDateRange();
          } else {
            setState(() {
              _selectedPeriod = period;
              _customStartDate = null;
              _customEndDate = null;
              _updateFilteredTransactions();
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              if (isCustom)
                Text(
                  '${DateFormat('MMM dd').format(_customStartDate!)} - ${DateFormat('MMM dd').format(_customEndDate!)}',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Credits',
            stats['totalCredits'] as double,
            AppColors.income,
            Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Debits',
            stats['totalDebits'] as double,
            AppColors.primary,
            Icons.trending_down_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Net Balance',
            stats['netBalance'] as double,
            AppColors.secondary,
            Icons.account_balance_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatCurrency(amount),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 56,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No transaction data',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Import SMS transactions to see analytics',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final sign = amount >= 0 ? '' : '-';
    return '$sign Rs. ${formatter.format(amount.abs())}';
  }
}

