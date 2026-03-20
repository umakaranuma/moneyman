// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/sms_service.dart';
import '../services/account_service.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../features/stats/presentation/screens/stats_screen.dart';
import 'add_account_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen>
    with WidgetsBindingObserver {
  int _refreshKey = 0; // Key to force rebuild
  Set<String> _hiddenAccountIds = {}; // Track hidden accounts

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, refresh to get new transactions
      setState(() {
        _refreshKey++;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Don't refresh on every screen switch - only refresh when actually needed
    // This prevents blinking and loading screens when navigating
  }

  @override
  Widget build(BuildContext context) {
    // Use refreshKey to force recalculation when transactions change
    // This ensures balances update when SMS transactions are imported
    final _ = _refreshKey; // Reference to trigger rebuild when key changes

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<Map<String, dynamic>>(
          key: ValueKey(_refreshKey), // Force refresh when key changes
          future: _getAccountsAndTransactions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final accounts = snapshot.data!['accounts'] as List<Account>;
            final transactions =
                snapshot.data!['transactions'] as List<Transaction>;
            final balances = _calculateBalancesFromTransactions(transactions);

            // Filter out hidden accounts
            final visibleAccounts = accounts.where((account) {
              return !_hiddenAccountIds.contains(account.id);
            }).toList();

            return CustomScrollView(
              slivers: [
                // Fixed Header
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FixedHeaderDelegate(
                    child: _buildHeader(),
                    height: 60, // padding 12+8 + row ~40
                  ),
                ),

                // Fixed Summary Cards
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FixedHeaderDelegate(
                    child: _buildSummaryCards(balances),
                    height: 200,
                  ),
                ),

                // Account Sections
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: _buildAccountSections(visibleAccounts, balances),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(
            'Accounts',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          _appleIconButton(Icons.bar_chart_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StatsScreen(showGraphsView: true),
              ),
            );
          }),
          const SizedBox(width: 8),
          _appleMoreButton(),
        ],
      ),
    );
  }

  Widget _appleIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _appleMoreButton() {
    return GestureDetector(
      onTap: _showActionSheet,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          color: AppColors.textSecondary,
          size: 18,
        ),
      ),
    );
  }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Main Action Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _buildActionTile(
                        title: 'Add Account',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToAddAccount();
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        title: 'Show / Hide Accounts',
                        onTap: () {
                          Navigator.pop(context);
                          _showHideAccountsDialog();
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        title: 'Delete Accounts',
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(context);
                          _showDeleteAccountsDialog();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                /// Cancel Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDestructive ? AppColors.expense : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAddAccount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddAccountScreen()),
    );
    if (result == true) {
      setState(() {
        _refreshKey++;
      });
    }
  }

  Future<Map<String, dynamic>> _getAccountsAndTransactions() async {
    final accounts = AccountService.getAllAccounts();
    final transactions = await _getAllTransactions();
    return {'accounts': accounts, 'transactions': transactions};
  }

  void _showHideAccountsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _HideAccountsSheet(
        hiddenAccountIds: _hiddenAccountIds,
        onChanged: (hiddenIds) {
          setState(() {
            _hiddenAccountIds = hiddenIds;
          });
        },
      ),
    );
  }

  void _showDeleteAccountsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DeleteAccountsSheet(
        onDeleted: () {
          setState(() {
            _refreshKey++;
          });
        },
      ),
    );
  }

  Widget _buildAccountSections(
    List<Account> accounts,
    Map<String, double> balances,
  ) {
    // Group accounts by category
    final accountsByCategory = <AccountCategory, List<Account>>{};
    for (var account in accounts) {
      accountsByCategory.putIfAbsent(account.category, () => []).add(account);
    }

    final widgets = <Widget>[];

    // Build sections for each category
    for (var category in AccountCategory.values) {
      final categoryAccounts = accountsByCategory[category] ?? [];
      if (categoryAccounts.isEmpty) continue;

      // Get gradient and icon for category
      List<Color> gradient;
      IconData icon;
      String title;

      switch (category) {
        case AccountCategory.cash:
          gradient = [
            AppColors.income,
            AppColors.income.withValues(alpha: 0.7),
          ];
          icon = Icons.payments_rounded;
          title = 'Cash';
          break;
        case AccountCategory.bank:
        case AccountCategory.savings:
          gradient = [AppColors.primary, AppColors.primaryLight];
          icon = Icons.account_balance_rounded;
          title = category == AccountCategory.savings
              ? 'Savings'
              : 'Bank Accounts';
          break;
        case AccountCategory.card:
        case AccountCategory.debitCard:
          gradient = [AppColors.secondary, AppColors.primary];
          icon = Icons.credit_card_rounded;
          title = category == AccountCategory.debitCard
              ? 'Debit Cards'
              : 'Credit Cards';
          break;
        default:
          gradient = [AppColors.surface, AppColors.surfaceVariant];
          icon = Icons.account_balance_wallet_rounded;
          title = categoryAccounts.first.categoryLabel;
      }

      if (category == AccountCategory.card ||
          category == AccountCategory.debitCard) {
        widgets.add(_buildCardSectionFromAccounts(categoryAccounts, balances));
      } else {
        final accountItems = categoryAccounts.map((account) {
          final balance = _getAccountBalance(account, balances);
          return _AccountItem(
            name: account.name,
            currency: account.currencySymbol,
            balance: balance,
            icon: _getAccountIcon(account.category),
            accountId: account.id,
          );
        }).toList();

        widgets.add(
          _buildAccountCard(
            title: title,
            icon: icon,
            gradient: gradient,
            accounts: accountItems,
          ),
        );
      }

      widgets.add(const SizedBox(height: 16));
    }

    // Bottom padding
    widgets.add(SizedBox(height: MediaQuery.of(context).padding.bottom));

    return Column(children: widgets);
  }

  double _getAccountBalance(Account account, Map<String, double> balances) {
    // Try to get balance from account first, then from transaction balances
    if (account.balance != 0.0) {
      return account.balance;
    }

    // Map account to balance key
    final currencyKey = account.currency.name;
    final categoryKey = account.category.name;
    final balanceKey = '${categoryKey}_$currencyKey';

    return balances[balanceKey] ?? 0.0;
  }

  IconData _getAccountIcon(AccountCategory category) {
    switch (category) {
      case AccountCategory.cash:
        return Icons.monetization_on_rounded;
      case AccountCategory.bank:
      case AccountCategory.savings:
        return Icons.savings_rounded;
      case AccountCategory.card:
      case AccountCategory.debitCard:
        return Icons.credit_card_rounded;
      case AccountCategory.investments:
        return Icons.trending_up_rounded;
      case AccountCategory.loan:
        return Icons.account_balance_rounded;
      case AccountCategory.insurance:
        return Icons.shield_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Widget _buildCardSectionFromAccounts(
    List<Account> cardAccounts,
    Map<String, double> balances,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  'Credit Cards',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...cardAccounts.asMap().entries.map((entry) {
            final index = entry.key;
            final account = entry.value;
            final isLast = index == cardAccounts.length - 1;

            return Column(
              children: [
                _buildCardItem(
                  name: account.name,
                  currency: account.currencySymbol,
                  payable: account.balancePayable ?? 0.0,
                  outstanding: account.outstandingBalance ?? 0.0,
                ),
                if (!isLast)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Future<List<Transaction>> _getAllTransactions() async {
    // Get manually added/imported transactions
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
    // This ensures that imported transactions replace the original SMS versions
    for (var t in smsTransactions) {
      if (!uniqueTransactions.containsKey(t.id)) {
        uniqueTransactions[t.id] = t;
      }
    }

    return uniqueTransactions.values.toList();
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

      // Filter out already imported transactions to avoid double-counting
      final unimportedSmsTransactions = smsTransactions.where((smsT) {
        return !SmsService.isAlreadyImported(smsT.id);
      }).toList();

      // Convert ParsedSmsTransaction to Transaction
      return unimportedSmsTransactions.map((smsT) {
        // Detect if this is a transfer (ATM withdrawal, cash deposit, bank-to-bank transfer) vs actual expense/income
        final isTransfer = _isSmsTransactionTransfer(smsT);

        // Extract account information for transfers
        String? fromAccount;
        String? toAccount;

        if (isTransfer) {
          if (smsT.isCredit) {
            // Money coming in (cash deposit to bank, or transfer received)
            toAccount = smsT.accountNumber ?? 'Bank Account';
            fromAccount = 'Cash'; // Default for cash deposits
          } else {
            // Money going out (ATM withdrawal, or transfer to another account)
            fromAccount = smsT.accountNumber ?? 'Bank Account';
            // Check if it's a bank-to-bank transfer (has "TO ACCOUNT" or similar)
            final upperMessage = smsT.rawMessage.toUpperCase();
            if (upperMessage.contains('TO ACCOUNT') ||
                upperMessage.contains('TRANSFERRED TO') ||
                upperMessage.contains('NEFT') ||
                upperMessage.contains('RTGS') ||
                upperMessage.contains('IMPS') ||
                upperMessage.contains('UPI')) {
              // Bank-to-bank transfer - try to extract recipient account
              toAccount =
                  _extractRecipientAccount(smsT.rawMessage) ?? 'Other Account';
            } else {
              // ATM withdrawal
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
      // If there's an error, just return empty list
      return [];
    }
  }

  /// Detect if SMS transaction is a transfer (ATM withdrawal/cash deposit) vs actual expense/income
  bool _isSmsTransactionTransfer(ParsedSmsTransaction smsT) {
    final upperMessage = smsT.rawMessage.toUpperCase();

    if (smsT.isCredit) {
      final cashDepositKeywords = [
        'CASH DEPOSIT',
        'CASH DEPOSITED',
        'DEPOSITED CASH',
        'CASH CREDITED',
      ];
      return cashDepositKeywords.any(
        (keyword) => upperMessage.contains(keyword),
      );
    } else {
      final atmKeywords = [
        'ATM',
        'WITHDRAWAL',
        'WITHDRAWN',
        'CASH WITHDRAWAL',
        'CASH WITHDRAWN',
      ];
      return atmKeywords.any((keyword) => upperMessage.contains(keyword));
    }
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

  Map<String, double> _calculateBalancesFromTransactions(
    List<Transaction> transactions,
  ) {
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
      // Skip transfers - they don't affect net balance (money just moves between accounts)
      if (t.type == TransactionType.transfer) {
        continue;
      }

      double amount = t.amount;

      // For income: add to balance (positive)
      // For expense: subtract from balance (negative)
      if (t.type == TransactionType.expense) {
        amount = -amount;
      }
      // Income transactions keep positive amount

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
    }

    // Calculate Assets and Liabilities based on final account balances
    // Assets = Cash + Bank (positive balances only)
    balances['total_assets'] =
        (balances['cash_inr']! > 0 ? balances['cash_inr']! : 0.0) +
        (balances['bank_inr']! > 0 ? balances['bank_inr']! : 0.0);

    // Liabilities = Credit Card debt (negative card balance shown as positive liability)
    // If card balance is negative, it's a debt (liability)
    // If card balance is positive, it's actually an asset (overpayment/credit)
    if (balances['card_inr']! < 0) {
      balances['total_liabilities'] = balances['card_inr']!.abs();
    } else {
      // Positive card balance means you have credit/overpayment (rare but possible)
      balances['total_assets'] =
          balances['total_assets']! + balances['card_inr']!;
      balances['total_liabilities'] = 0.0;
    }

    return balances;
  }

  String _formatCurrency(double amount, {String prefix = ''}) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$prefix${formatter.format(amount.abs())}';
  }

  Widget _buildSummaryCards(Map<String, double> balances) {
    final totalAssets = balances['total_assets'] ?? 0.0;
    final totalLiabilities = balances['total_liabilities'] ?? 0.0;
    final total = totalAssets - totalLiabilities;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Worth',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatCurrency(total, prefix: 'Rs. '),
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryMini('Assets', totalAssets, AppColors.income),
                _summaryMini(
                  'Liabilities',
                  totalLiabilities,
                  AppColors.expense,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMini(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          _formatCurrency(value, prefix: 'Rs. '),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required List<_AccountItem> accounts,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...accounts.asMap().entries.map((entry) {
            final index = entry.key;
            final account = entry.value;
            final isLast = index == accounts.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        account.icon,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          account.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _formatCurrency(
                          account.balance,
                          prefix: '${account.currency} ',
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: account.balance >= 0
                              ? AppColors.textPrimary
                              : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.credit_card_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Payable',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                _formatCurrency(payable, prefix: '$currency '),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Outstanding',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                _formatCurrency(outstanding, prefix: '$currency '),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
  final String? accountId;

  const _AccountItem({
    required this.name,
    required this.currency,
    required this.balance,
    required this.icon,
    this.accountId,
  });
}

class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _FixedHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.background, child: child);
  }

  @override
  bool shouldRebuild(_FixedHeaderDelegate oldDelegate) {
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}

// Bottom sheet for hiding/showing accounts
class _HideAccountsSheet extends StatefulWidget {
  final Set<String> hiddenAccountIds;
  final Function(Set<String>) onChanged;

  const _HideAccountsSheet({
    required this.hiddenAccountIds,
    required this.onChanged,
  });

  @override
  State<_HideAccountsSheet> createState() => _HideAccountsSheetState();
}

class _HideAccountsSheetState extends State<_HideAccountsSheet> {
  late Set<String> _selectedHiddenIds;

  @override
  void initState() {
    super.initState();
    _selectedHiddenIds = Set.from(widget.hiddenAccountIds);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = AccountService.getAllAccounts();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      'Show / Hide Accounts',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 20, endIndent: 20),
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        final isVisible = !_selectedHiddenIds.contains(
                          account.id,
                        );

                        return CheckboxListTile(
                          value: isVisible,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedHiddenIds.remove(account.id);
                              } else {
                                _selectedHiddenIds.add(account.id);
                              }
                            });
                          },
                          title: Text(
                            account.name,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${account.categoryLabel} • ${account.currencySymbol}',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ElevatedButton(
                onPressed: () {
                  widget.onChanged(_selectedHiddenIds);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom sheet for deleting accounts
class _DeleteAccountsSheet extends StatefulWidget {
  final VoidCallback onDeleted;

  const _DeleteAccountsSheet({required this.onDeleted});

  @override
  State<_DeleteAccountsSheet> createState() => _DeleteAccountsSheetState();
}

class _DeleteAccountsSheetState extends State<_DeleteAccountsSheet> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final accounts = AccountService.getAllAccounts();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      'Delete Accounts',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 20, endIndent: 20),
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        final isSelected = _selectedIds.contains(account.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedIds.add(account.id);
                              } else {
                                _selectedIds.remove(account.id);
                              }
                            });
                          },
                          title: Text(
                            account.name,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${account.categoryLabel} • ${account.currencySymbol}',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ElevatedButton(
                onPressed: _selectedIds.isEmpty
                    ? null
                    : () async {
                        for (var id in _selectedIds) {
                          await AccountService.deleteAccount(id);
                        }
                        widget.onDeleted();
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expense,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.surfaceVariant,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
