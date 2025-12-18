import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../models/transaction.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final balances = _calculateBalances();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Accounts',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Summary Header
            _buildSummaryHeader(balances),

            const SizedBox(height: 16),

            // Cash Section
            _buildAccountSection(
              title: 'Cash',
              accounts: [
                _AccountItem(
                  name: 'Cash',
                  currency: 'Rs.',
                  balance: balances['cash_inr'] ?? 0.0,
                  color: AppColors.expense,
                ),
                _AccountItem(
                  name: 'Cash',
                  currency: '\$',
                  balance: balances['cash_usd'] ?? 0.0,
                  color: AppColors.textPrimary,
                  isBold: true,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Bank Accounts Section
            _buildAccountSection(
              title: 'Bank',
              accounts: [
                _AccountItem(
                  name: 'Accounts',
                  currency: 'Rs.',
                  balance: balances['bank_inr'] ?? 0.0,
                  color: AppColors.expense,
                ),
                _AccountItem(
                  name: 'Accounts',
                  currency: '\$',
                  balance: balances['bank_usd'] ?? 0.0,
                  color: AppColors.expense,
                  isBold: true,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Card Section
            _buildCardSection(balances),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateBalances() {
    final transactions = StorageService.getAllTransactions();
    final balances = <String, double>{
      'cash_inr': 0.0,
      'cash_usd': 0.0,
      'bank_inr': 0.0,
      'bank_usd': 0.0,
      'card_inr': 0.0,
      'card_usd': 0.0,
      'total_assets': 0.0,
      'total_liabilities': 0.0,
    };

    for (var t in transactions) {
      double amount = t.amount;
      if (t.type == TransactionType.expense) {
        amount = -amount;
      } else if (t.type == TransactionType.transfer) {
        continue; // Skip transfers for balance calculation
      }

      switch (t.accountType) {
        case AccountType.cash:
          balances['cash_inr'] = balances['cash_inr']! + amount;
          break;
        case AccountType.bank:
        case AccountType.other:
          balances['bank_inr'] = balances['bank_inr']! + amount;
          break;
        case AccountType.card:
          balances['card_inr'] = balances['card_inr']! + amount;
          break;
      }

      if (amount > 0) {
        balances['total_assets'] = balances['total_assets']! + amount;
      } else {
        balances['total_liabilities'] =
            balances['total_liabilities']! + amount.abs();
      }
    }

    return balances;
  }

  String _formatCurrency(double amount, {String prefix = ''}) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$prefix${formatter.format(amount.abs())}';
  }

  Widget _buildSummaryHeader(Map<String, double> balances) {
    final totalAssets =
        (balances['cash_inr'] ?? 0.0) + (balances['bank_inr'] ?? 0.0);
    final totalLiabilities = balances['total_liabilities'] ?? 0.0;
    final total = totalAssets - totalLiabilities;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeaderItem('Assets', totalAssets, AppColors.income),
          _buildHeaderItem('Liabilities', totalLiabilities, AppColors.expense),
          _buildHeaderItem('Total', total, AppColors.textPrimary),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(value),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection({
    required String title,
    required List<_AccountItem> accounts,
  }) {
    return Column(
      children: accounts.map((account) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Text(
                account.name,
                style: TextStyle(
                  color: account.isBold
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight:
                      account.isBold ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const Spacer(),
              Text(
                _formatCurrency(account.balance, prefix: '${account.currency} '),
                style: TextStyle(
                  color: account.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardSection(Map<String, double> balances) {
    return Column(
      children: [
        // INR Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Card',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Balance Payable',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    _formatCurrency(0.0, prefix: 'Rs. '),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Outst. Balance',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    _formatCurrency(0.0, prefix: 'Rs. '),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // USD Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Card',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(0.0, prefix: '\$ '),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(0.0, prefix: '\$ '),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountItem {
  final String name;
  final String currency;
  final double balance;
  final Color color;
  final bool isBold;

  const _AccountItem({
    required this.name,
    required this.currency,
    required this.balance,
    required this.color,
    this.isBold = false,
  });
}

