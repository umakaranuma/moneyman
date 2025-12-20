import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/sms_analytics_service.dart';
import '../theme/app_theme.dart';

/// Helper function to ensure horizontalInterval is never zero
double _ensureNonZeroInterval(double value) {
  if (value <= 0 || !value.isFinite || value.isNaN) {
    return 1000.0;
  }
  return value < 1.0 ? 1000.0 : value;
}

/// Bank Breakdown Pie Chart
class BankBreakdownPieChart extends StatelessWidget {
  final Map<String, Map<String, double>> bankData;

  const BankBreakdownPieChart({super.key, required this.bankData});

  @override
  Widget build(BuildContext context) {
    if (bankData.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = bankData.entries.toList()
      ..sort((a, b) {
        final aTotal = a.value['credits']! + a.value['debits']!;
        final bTotal = b.value['credits']! + b.value['debits']!;
        return bTotal.compareTo(aTotal);
      });

    final total = entries.fold<double>(
      0.0,
      (sum, entry) => sum + entry.value['credits']! + entry.value['debits']!,
    );

    return Container(
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
          color: AppColors.surfaceVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Bank Breakdown',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                      final bankData = entry.value;
                      final bankTotal =
                          bankData['credits']! + bankData['debits']!;
                      final percentage = (bankTotal / total * 100);
                      final color =
                          AppColors.categoryColors[index %
                              AppColors.categoryColors.length];

                      return PieChartSectionData(
                        value: bankTotal,
                        title: '${percentage.toStringAsFixed(1)}%',
                        color: color,
                        radius: 60,
                        titleStyle: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(total),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          ...entries.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            final bankName = entry.key;
            final bankTotal = entry.value['credits']! + entry.value['debits']!;
            final color = AppColors
                .categoryColors[index % AppColors.categoryColors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bankName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _formatCurrency(bankTotal),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return 'Rs. ${formatter.format(amount)}';
  }
}

/// Credit vs Debit Trends Line Chart
class CreditDebitTrendsChart extends StatelessWidget {
  final List<Map<String, dynamic>> trends;
  final TimePeriod period;

  const CreditDebitTrendsChart({
    super.key,
    required this.trends,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxAmount = trends.fold<double>(
      0.0,
      (max, item) => (item['credits'] as double) > (item['debits'] as double)
          ? (item['credits'] as double) > max
                ? item['credits'] as double
                : max
          : (item['debits'] as double) > max
          ? item['debits'] as double
          : max,
    );
    // Ensure maxAmount is not zero
    final safeMaxAmount = maxAmount > 0 ? maxAmount : 1000.0;
    final horizontalInterval = safeMaxAmount / 5;

    return Container(
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
          color: AppColors.surfaceVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.income,
                      AppColors.income.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Credit vs Debit Trends',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval > 0
                      ? horizontalInterval
                      : null,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: trends.length > 7 ? 2 : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < trends.length) {
                          final date = trends[index]['date'] as DateTime;
                          return _getBottomTitle(date, period);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: horizontalInterval > 0
                          ? horizontalInterval
                          : null,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatShortCurrency(value),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Credit line
                  LineChartBarData(
                    spots: trends.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['credits'] as double,
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.income,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Debit line
                  LineChartBarData(
                    spots: trends.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['debits'] as double,
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                minX: 0,
                maxX: (trends.length - 1).toDouble(),
                minY: 0,
                maxY: safeMaxAmount * 1.1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Credits', AppColors.income),
              const SizedBox(width: 24),
              _buildLegendItem('Debits', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _getBottomTitle(DateTime date, TimePeriod period) {
    String label;
    switch (period) {
      case TimePeriod.daily:
        label = DateFormat('MMM dd').format(date);
        break;
      case TimePeriod.weekly:
        label = DateFormat('MMM dd').format(date);
        break;
      case TimePeriod.monthly:
        label = DateFormat('MMM yyyy').format(date);
        break;
      case TimePeriod.custom:
        label = DateFormat('MMM dd').format(date);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
      ),
    );
  }

  static String _formatShortCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

/// Balance Over Time Line Chart
class BalanceOverTimeChart extends StatelessWidget {
  final List<Map<String, dynamic>> balanceData;
  final TimePeriod period;

  const BalanceOverTimeChart({
    super.key,
    required this.balanceData,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (balanceData.isEmpty) {
      return const SizedBox.shrink();
    }

    final balances = balanceData.map((d) => d['balance'] as double).toList();
    final minBalance = balances.reduce((a, b) => a < b ? a : b);
    final maxBalance = balances.reduce((a, b) => a > b ? a : b);
    final range = maxBalance - minBalance;

    // Calculate horizontalInterval with ABSOLUTE guarantee it's never zero
    double calculatedInterval;

    if (range.abs() >= 1.0) {
      calculatedInterval = range.abs() / 5.0;
    } else if (maxBalance.abs() >= 1.0) {
      calculatedInterval = maxBalance.abs() / 5.0;
    } else {
      calculatedInterval = 1000.0;
    }

    // Use helper function to guarantee non-zero value
    final safeHorizontalInterval = _ensureNonZeroInterval(calculatedInterval);

    return Container(
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
          color: AppColors.surfaceVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary,
                      AppColors.secondary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Balance Over Time',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      safeHorizontalInterval, // Already guaranteed to be > 0
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: balanceData.length > 7 ? 2 : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < balanceData.length) {
                          final date = balanceData[index]['date'] as DateTime;
                          return _getBottomTitle(date, period);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval:
                          safeHorizontalInterval, // Already guaranteed to be > 0
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatShortCurrency(value),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: balanceData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['balance'] as double,
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.secondary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.secondary,
                          strokeWidth: 2,
                          strokeColor: AppColors.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.secondary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minX: 0,
                maxX: (balanceData.length - 1).toDouble(),
                minY: range > 0
                    ? minBalance - (range * 0.1)
                    : (minBalance > 0 ? minBalance * 0.9 : minBalance - 100),
                maxY: range > 0
                    ? maxBalance + (range * 0.1)
                    : (maxBalance > 0 ? maxBalance * 1.1 : maxBalance + 100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getBottomTitle(DateTime date, TimePeriod period) {
    String label;
    switch (period) {
      case TimePeriod.daily:
        label = DateFormat('MMM dd').format(date);
        break;
      case TimePeriod.weekly:
        label = DateFormat('MMM dd').format(date);
        break;
      case TimePeriod.monthly:
        label = DateFormat('MMM yyyy').format(date);
        break;
      case TimePeriod.custom:
        label = DateFormat('MMM dd').format(date);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
      ),
    );
  }

  static String _formatShortCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

/// Transaction Volume Bar Chart
class TransactionVolumeChart extends StatelessWidget {
  final List<Map<String, dynamic>> volume;
  final TimePeriod period;

  const TransactionVolumeChart({
    super.key,
    required this.volume,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (volume.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxCount = volume.fold<int>(
      0,
      (max, item) => (item['total'] as int) > max ? item['total'] as int : max,
    );
    // Ensure maxCount is not zero
    final safeMaxCount = maxCount > 0 ? maxCount : 1;
    final horizontalInterval = (safeMaxCount > 5 ? safeMaxCount / 5.0 : 1.0);

    return Container(
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
          color: AppColors.surfaceVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.expense,
                      AppColors.expense.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Transaction Volume',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: volume.length > 7 ? 2 : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < volume.length) {
                          final date = volume[index]['date'] as DateTime;
                          return _getBottomTitle(date, period);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: horizontalInterval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: volume.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (item['credits'] as int).toDouble(),
                        color: AppColors.income,
                        width: 8,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: (item['debits'] as int).toDouble(),
                        color: AppColors.primary,
                        width: 8,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                maxY: safeMaxCount * 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Credits', AppColors.income),
              const SizedBox(width: 24),
              _buildLegendItem('Debits', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _getBottomTitle(DateTime date, TimePeriod period) {
    String label;
    switch (period) {
      case TimePeriod.daily:
        label = DateFormat('MMM dd').format(date);
        break;
      case TimePeriod.weekly:
        label = DateFormat('MMM dd').format(date);
        break;
      case TimePeriod.monthly:
        label = DateFormat('MMM yyyy').format(date);
        break;
      case TimePeriod.custom:
        label = DateFormat('MMM dd').format(date);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
      ),
    );
  }
}
