// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../../utils/helpers.dart';
import '../../../../models/transaction.dart';
import '../../../../services/budget_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/total_export_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/router/app_router.dart';


class TotalView extends StatelessWidget {
  final DateTime selectedMonth;
  final Map<String, double> summary;

  /// All transactions (for Total tab parent passes full list). We filter by month inside.
  final List<Transaction> transactions;

  const TotalView({
    super.key,
    required this.selectedMonth,
    required this.summary,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final monthTransactions = transactions
        .where(
          (t) =>
              t.date.year == selectedMonth.year &&
              t.date.month == selectedMonth.month,
        )
        .toList();
    if (StorageService.getConfigCarryOverEnabled()) {
      final carryAmount = _calculateCarryOverAmount(selectedMonth, transactions);
      if (carryAmount != 0) {
        monthTransactions.add(_buildCarryOverTransaction(selectedMonth, carryAmount));
      }
    }
    final lastMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    final lastMonthExpense = transactions
        .where(
          (t) =>
              t.date.year == lastMonth.year &&
              t.date.month == lastMonth.month &&
              t.type == TransactionType.expense,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

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

    final comparisonPercent = lastMonthExpense > 0
        ? ((summary['expense']! / lastMonthExpense) * 100).round()
        : 0;

    final budgets = BudgetService.getBudgetsForMonth(
      selectedMonth.year,
      selectedMonth.month,
    );
    final statuses = BudgetService.getBudgetStatuses(
      selectedMonth.year,
      selectedMonth.month,
    );
    final overCount = statuses.values.where((s) => s.isOverBudget).length;
    final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final dateRangeStr =
        '${selectedMonth.month}.1 ~ ${selectedMonth.month}.${lastDay.day}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _BudgetCard(
          budgetCount: budgets.length,
          overCount: overCount,
          onTap: () async {
            await context.goToBudgetSetting(initialMonth: selectedMonth);
          },
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Accounts',
          dateRange: dateRangeStr,
          children: [
            _StatRow(
              'Compared (last month)',
              '$comparisonPercent%',
              isPercent: true,
            ),
            const SizedBox(height: 12),
            _StatRow(
              'Expenses (Cash, Accounts)',
              Helpers.formatCurrency(cashExpenses),
            ),
            const SizedBox(height: 12),
            _StatRow(
              'Expenses (Card)',
              Helpers.formatCurrency(cardExpenses),
            ),
            const SizedBox(height: 12),
            _StatRow(
              'Transfers',
              Helpers.formatCurrency(transfers),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Material(
          color: AppColors.income.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (sheetContext) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Export data as',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.table_chart_rounded),
                          title: const Text('Excel (.xlsx)'),
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            try {
                              await TotalExportService.exportExcel(
                                selectedMonth: selectedMonth,
                                comparisonPercent: comparisonPercent,
                                cashExpenses: cashExpenses,
                                cardExpenses: cardExpenses,
                                transfers: transfers,
                                monthTransactions: monthTransactions,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Downloaded successfully'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Download failed'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.picture_as_pdf_rounded),
                          title: const Text('PDF (.pdf)'),
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            try {
                              await TotalExportService.exportPdf(
                                selectedMonth: selectedMonth,
                                comparisonPercent: comparisonPercent,
                                cashExpenses: cashExpenses,
                                cardExpenses: cardExpenses,
                                transfers: transfers,
                                monthTransactions: monthTransactions,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Downloaded successfully'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Download failed'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_chart_rounded,
                    color: AppColors.income,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Export data',
                    style: TextStyle(
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
      ],
    );
  }

  double _calculateCarryOverAmount(
    DateTime targetMonth,
    List<Transaction> allTransactions,
  ) {
    final monthStart = DateTime(targetMonth.year, targetMonth.month, 1);
    double income = 0;
    double expense = 0;

    for (final t in allTransactions) {
      if (!t.date.isBefore(monthStart)) continue;
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else if (t.type == TransactionType.expense) {
        expense += t.amount;
      }
    }
    return income - expense;
  }

  Transaction _buildCarryOverTransaction(DateTime month, double amount) {
    final isIncome = amount >= 0;
    return Transaction(
      id: 'carry_over_${month.year}_${month.month}',
      title: 'Carry-over',
      amount: amount.abs(),
      type: isIncome ? TransactionType.income : TransactionType.expense,
      date: DateTime(month.year, month.month, 1),
      category: 'Carry-over',
      note: 'Previous month balance carried forward',
      accountType: AccountType.cash,
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final int budgetCount;
  final int overCount;
  final VoidCallback onTap;

  const _BudgetCard({
    required this.budgetCount,
    required this.overCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Budget',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (budgetCount > 0)
                    Text(
                      overCount > 0
                          ? '$budgetCount set · $overCount over'
                          : '$budgetCount set for this month',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: onTap,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Budget Setting',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
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
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String dateRange;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.dateRange,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dateRange,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPercent;

  const _StatRow(this.label, this.value, {this.isPercent = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isPercent
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPercent ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
