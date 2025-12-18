import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            
            // Summary Cards
            SliverToBoxAdapter(
              child: _buildSummaryCards(balances),
            ),
            
            // Account Sections
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Cash Section
                    _buildAccountCard(
                      title: 'Cash',
                      icon: Icons.payments_rounded,
                      gradient: [AppColors.income, AppColors.income.withValues(alpha: 0.7)],
                      accounts: [
                        _AccountItem(
                          name: 'Cash',
                          currency: 'Rs.',
                          balance: balances['cash_inr'] ?? 0.0,
                          icon: Icons.monetization_on_rounded,
                        ),
                        _AccountItem(
                          name: 'Cash USD',
                          currency: '\$',
                          balance: balances['cash_usd'] ?? 0.0,
                          icon: Icons.attach_money_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bank Section
                    _buildAccountCard(
                      title: 'Bank Accounts',
                      icon: Icons.account_balance_rounded,
                      gradient: [AppColors.primary, AppColors.primaryLight],
                      accounts: [
                        _AccountItem(
                          name: 'Accounts',
                          currency: 'Rs.',
                          balance: balances['bank_inr'] ?? 0.0,
                          icon: Icons.savings_rounded,
                        ),
                        _AccountItem(
                          name: 'Accounts USD',
                          currency: '\$',
                          balance: balances['bank_usd'] ?? 0.0,
                          icon: Icons.account_balance_wallet_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Card Section
                    _buildCardSection(balances),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Accounts',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _buildHeaderButton(Icons.bar_chart_rounded),
          const SizedBox(width: 8),
          _buildHeaderButton(Icons.more_vert_rounded),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.surfaceVariant,
          width: 1,
        ),
      ),
      child: Icon(icon, color: AppColors.textSecondary, size: 20),
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

  Widget _buildSummaryCards(Map<String, double> balances) {
    final totalAssets =
        (balances['cash_inr'] ?? 0.0) + (balances['bank_inr'] ?? 0.0);
    final totalLiabilities = balances['total_liabilities'] ?? 0.0;
    final total = totalAssets - totalLiabilities;

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Assets',
              amount: totalAssets,
              icon: Icons.trending_up_rounded,
              gradient: [AppColors.income, AppColors.income.withValues(alpha: 0.7)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Liabilities',
              amount: totalLiabilities,
              icon: Icons.trending_down_rounded,
              gradient: [AppColors.expense, AppColors.expense.withValues(alpha: 0.7)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Net Worth',
              amount: total,
              icon: Icons.account_balance_rounded,
              gradient: [AppColors.textPrimary, AppColors.textSecondary], // White for balance
              isHighlighted: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required List<Color> gradient,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isHighlighted
            ? LinearGradient(colors: gradient)
            : LinearGradient(
                colors: [
                  AppColors.surface,
                  AppColors.surfaceVariant.withValues(alpha: 0.5),
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradient[0].withValues(alpha: isHighlighted ? 0 : 0.2),
          width: 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Colors.white.withValues(alpha: 0.2)
                  : gradient[0].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isHighlighted ? Colors.white : gradient[0],
              size: 18,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: isHighlighted
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatCurrency(amount, prefix: 'Rs. '),
                  style: GoogleFonts.inter(
                    color: isHighlighted ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required List<_AccountItem> accounts,
  }) {
    return Container(
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
          color: gradient[0].withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gradient[0].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${accounts.length} accounts',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: gradient[0],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: AppColors.surfaceVariant,
          ),
          
          // Accounts
          ...accounts.asMap().entries.map((entry) {
            final index = entry.key;
            final account = entry.value;
            final isLast = index == accounts.length - 1;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: !isLast
                    ? Border(
                        bottom: BorderSide(
                          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: gradient[0].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      account.icon,
                      color: gradient[0],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          account.currency,
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(account.balance, prefix: '${account.currency} '),
                        style: GoogleFonts.inter(
                          color: account.balance >= 0
                              ? AppColors.income
                              : AppColors.expense,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (account.balance >= 0
                                  ? AppColors.income
                                  : AppColors.expense)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          account.balance >= 0 ? 'Active' : 'Overdrawn',
                          style: GoogleFonts.inter(
                            color: account.balance >= 0
                                ? AppColors.income
                                : AppColors.expense,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCardSection(Map<String, double> balances) {
    return Container(
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
          color: AppColors.secondary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Text(
                  'Credit Cards',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: AppColors.surfaceVariant,
          ),
          
          // Card Items
          _buildCardItem(
            name: 'Credit Card',
            currency: 'Rs.',
            payable: 0.0,
            outstanding: 0.0,
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          ),
          _buildCardItem(
            name: 'Credit Card USD',
            currency: '\$',
            payable: 0.0,
            outstanding: 0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem({
    required String name,
    required String currency,
    required double payable,
    required double outstanding,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  currency,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Balance Payable',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              Text(
                _formatCurrency(payable, prefix: '$currency '),
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Outstanding',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              Text(
                _formatCurrency(outstanding, prefix: '$currency '),
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountItem {
  final String name;
  final String currency;
  final double balance;
  final IconData icon;

  const _AccountItem({
    required this.name,
    required this.currency,
    required this.balance,
    required this.icon,
  });
}
