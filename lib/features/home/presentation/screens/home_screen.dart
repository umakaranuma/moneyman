import 'package:flutter/material.dart';
import '../../../../models/transaction.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/sms_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../screens/transaction_filter_screen.dart';
import '../widgets/home_header.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_list.dart';
import '../widgets/calendar_view.dart';
import '../widgets/monthly_view.dart';
import '../widgets/total_view.dart';
import '../widgets/add_transaction_fab.dart';
import '../bottom_sheets/transaction_options_sheet.dart';
import 'home_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _refreshKey = 0;
  String _searchQuery = '';
  TransactionFilter? _activeFilter;
  List<Transaction> _cachedTransactions = [];

  static const _tabCount = 4;
  static const _tabs = ['Daily', 'Calendar', 'Monthly', 'Total'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _tabController.addListener(_onTabChange);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _refreshKey++);
    }
  }

  void _onTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() => _refreshKey++);
  }

  Future<List<Transaction>> _getFilteredTransactions() async {
    final manual = StorageService.getAllTransactions();
    final sms = await _getSmsTransactionsAsTransactions();
    final unique = <String, Transaction>{};
    for (var t in manual) {
      unique[t.id] = t;
    }
    for (var t in sms) {
      if (!unique.containsKey(t.id)) unique[t.id] = t;
    }
    var list = unique.values.toList();

    switch (_tabController.index) {
      case 0:
      case 2:
        list = list
            .where(
              (t) =>
                  t.date.year == _selectedMonth.year &&
                  t.date.month == _selectedMonth.month,
            )
            .toList();
        break;
      case 3:
        break;
      default:
        list = list
            .where(
              (t) =>
                  t.date.year == _selectedMonth.year &&
                  t.date.month == _selectedMonth.month,
            )
            .toList();
    }

    if (_activeFilter != null && _activeFilter!.hasActiveFilters) {
      list = _activeFilter!.apply(list);
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                (t.category?.toLowerCase().contains(q) ?? false) ||
                (t.note?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    return list;
  }

  Future<List<Transaction>> _getSmsTransactionsAsTransactions() async {
    try {
      if (!await SmsService.hasSmsPermission()) return [];
      final smsList = await SmsService.fetchAndParseSmsMessages(
        fetchAll: false,
      );
      return smsList.map((smsT) {
        final isTransfer = _isSmsTransactionTransfer(smsT);
        String? fromAccount, toAccount;
        if (isTransfer) {
          if (smsT.isCredit) {
            toAccount = smsT.accountNumber ?? 'Bank Account';
            fromAccount = 'Cash';
          } else {
            fromAccount = smsT.accountNumber ?? 'Bank Account';
            final upper = smsT.rawMessage.toUpperCase();
            if (upper.contains('TO ACCOUNT') ||
                upper.contains('TRANSFERRED TO') ||
                upper.contains('NEFT') ||
                upper.contains('RTGS') ||
                upper.contains('IMPS') ||
                upper.contains('UPI')) {
              toAccount =
                  _extractRecipientAccount(smsT.rawMessage) ?? 'Other Account';
            } else {
              toAccount = 'Cash';
            }
          }
        }
        final upper = smsT.rawMessage.toUpperCase();
        final title = isTransfer
            ? (smsT.isCredit
                  ? '${smsT.bankName} Deposit'
                  : (upper.contains('TO ACCOUNT') ||
                            upper.contains('TRANSFERRED TO') ||
                            upper.contains('NEFT') ||
                            upper.contains('RTGS') ||
                            upper.contains('IMPS')
                        ? '${smsT.bankName} Transfer'
                        : '${smsT.bankName} Withdrawal'))
            : '${smsT.bankName} ${smsT.isCredit ? "Credit" : "Debit"}';
        return Transaction(
          id: 'sms_${smsT.id}',
          title: title,
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
              'From SMS: ${smsT.rawMessage.length > 50 ? "${smsT.rawMessage.substring(0, 50)}..." : smsT.rawMessage}',
          accountType: AccountType.bank,
          fromAccount: fromAccount,
          toAccount: toAccount,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  bool _isSmsTransactionTransfer(ParsedSmsTransaction smsT) {
    final upper = smsT.rawMessage.toUpperCase();
    if (smsT.isCredit) {
      const keywords = [
        'CASH DEPOSIT',
        'CASH DEPOSITED',
        'DEPOSIT CASH',
        'CASH DEPOSITED TO',
      ];
      return keywords.any((k) => upper.contains(k));
    }
    const expenseKeywords = [
      'PAYMENT',
      'PAID',
      'PURCHASE',
      'PURCHASED',
      'BILL',
      'MERCHANT',
      'POS',
      'DEBIT CARD',
      'CREDIT CARD',
      'ONLINE',
      'SHOPPING',
      'RESTAURANT',
      'FOOD',
      'GROCERY',
      'FUEL',
      'PETROL',
      'DIESEL',
      'TAXI',
      'UBER',
      'OLA',
      'RENT',
      'SALARY',
      'SERVICE',
      'CHARGE',
      'FEE',
      'TAX',
    ];
    if (upper.contains('ATM') &&
        (upper.contains('WITHDRAWAL') || upper.contains('WITHDRAWN'))) {
      return true;
    }
    if (RegExp(
      r'ATM\s+WITHDRAW(?:AL|N)',
      caseSensitive: false,
    ).hasMatch(upper)) {
      return true;
    }
    if (upper.contains('CASH WITHDRAWAL') || upper.contains('CASH WITHDRAWN')) {
      return true;
    }
    if ((upper.contains('WITHDRAWAL') || upper.contains('WITHDRAWN')) &&
        (upper.contains('FROM ACCOUNT') ||
            upper.contains('FROM A/C') ||
            upper.contains('FROM AC') ||
            RegExp(
              r'FROM\s+[A/C\s]*NO',
              caseSensitive: false,
            ).hasMatch(upper) ||
            upper.contains('A/C NO') ||
            upper.contains('ACCOUNT NO') ||
            upper.contains('A/C:'))) {
      return true;
    }
    if ((upper.contains('NEFT') ||
            upper.contains('RTGS') ||
            upper.contains('IMPS') ||
            upper.contains('UPI')) &&
        (upper.contains('TO ACCOUNT') ||
            upper.contains('TO A/C') ||
            upper.contains('TO AC') ||
            RegExp(
              r'DEBITED\s+TO\s+(?:AC|ACCOUNT|A/C)',
              caseSensitive: false,
            ).hasMatch(upper) ||
            RegExp(
              r'TO\s+(?:AC|ACCOUNT|A/C)\s+NO',
              caseSensitive: false,
            ).hasMatch(upper))) {
      return true;
    }
    if (upper.contains('TRANSFER') &&
        (upper.contains('TO ACCOUNT') ||
            upper.contains('TO A/C') ||
            upper.contains('TO AC') ||
            upper.contains('FROM ACCOUNT') ||
            upper.contains('FROM A/C') ||
            upper.contains('FROM AC') ||
            RegExp(r'TO\s+[A/C\s]*NO', caseSensitive: false).hasMatch(upper) ||
            RegExp(
              r'FROM\s+[A/C\s]*NO',
              caseSensitive: false,
            ).hasMatch(upper))) {
      return true;
    }
    if (expenseKeywords.any((k) => upper.contains(k))) return false;
    return false;
  }

  String? _extractRecipientAccount(String message) {
    final upper = message.toUpperCase();
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
    for (final p in patterns) {
      final m = p.firstMatch(upper);
      if (m != null && m.group(1) != null) {
        final account = m.group(1)!;
        return account.contains('@')
            ? account
            : '****${account.length > 4 ? account.substring(account.length - 4) : account}';
      }
    }
    return null;
  }

  Map<DateTime, List<Transaction>> _groupByDate(List<Transaction> list) {
    final map = <DateTime, List<Transaction>>{};
    for (var t in list) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(d, () => []).add(t);
    }
    return map;
  }

  Map<String, double> _getSummary(List<Transaction> list) {
    final income = list
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = list
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    return {'income': income, 'expense': expense, 'total': income - expense};
  }

  void _previousMonth() {
    setState(() {
      if (_tabController.index == 2) {
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
      _refreshKey++;
    });
  }

  void _nextMonth() {
    setState(() {
      if (_tabController.index == 2) {
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
      _refreshKey++;
    });
  }

  void _refresh() => setState(() => _refreshKey++);

  Future<void> _openSearch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeSearchScreen(initialQuery: _searchQuery),
      ),
    );
  }

  void _showBookmarked() {
    final all = StorageService.getAllTransactions();
    final bookmarked = all.where((t) => t.isBookmarked).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.bookmark_rounded,
                    color: AppColors.income,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Bookmarked (${bookmarked.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: bookmarked.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No bookmarks',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: bookmarked.length,
                      itemBuilder: (context, i) {
                        final t = bookmarked[i];
                        return ListTile(
                          title: Text(
                            t.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            t.category ?? '',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          trailing: Text(
                            'Rs. ${t.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: t.type == TransactionType.income
                                  ? AppColors.income
                                  : AppColors.expense,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            final result = await context
                                .goToEditTransaction<bool>(t);
                            if (result == true) _refresh();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilter() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFilterScreen(
          selectedMonth: _selectedMonth,
          initialFilter: _activeFilter,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _activeFilter = result['filter'] as TransactionFilter?;
        if (result['month'] != null) {
          _selectedMonth = result['month'] as DateTime;
        }
        _refreshKey++;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _activeFilter = null;
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: AddTransactionFAB(onSaved: _refresh),
      body: SafeArea(
        bottom: true,
        child: FutureBuilder<List<Transaction>>(
          key: ValueKey(_refreshKey),
          future: _getFilteredTransactions(),
          builder: (context, snapshot) {
            if (snapshot.hasData) _cachedTransactions = snapshot.data ?? [];
            final transactions = _cachedTransactions.isNotEmpty
                ? _cachedTransactions
                : (snapshot.data ?? []);
            final summary = _getSummary(transactions);
            final grouped = _groupByDate(transactions);
            final sortedDates = grouped.keys.toList()
              ..sort((a, b) => b.compareTo(a));
            final showYearOnly = _tabController.index == 2;

            return Column(
              children: [
                HomeHeader(
                  selectedMonth: _selectedMonth,
                  onPrevious: _previousMonth,
                  onNext: _nextMonth,
                  showYearOnly: showYearOnly,
                  onSearch: _openSearch,
                  onFilter: _showFilter,
                  onBookmark: _showBookmarked,
                  onNotes: () => context.goToNotes(),
                  onClearFilters:
                      (_searchQuery.isNotEmpty ||
                          _activeFilter?.hasActiveFilters == true)
                      ? _clearFilters
                      : null,
                  hasActiveFilters: _activeFilter?.hasActiveFilters ?? false,
                  hasSearchQuery: _searchQuery.isNotEmpty,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
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
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                SummaryCard(
                  income: summary['income']!,
                  expense: summary['expense']!,
                  total: summary['total']!,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      DailyTransactionsView(
                        transactions: transactions,
                        groupedByDate: grouped,
                        sortedDates: sortedDates,
                        onRefresh: () async => _refresh(),
                        onTransactionTap: _onTransactionTap,
                        onTransactionLongPress: _onTransactionLongPress,
                      ),
                      CalendarView(
                        selectedMonth: _selectedMonth,
                        selectedDay: _selectedDay,
                        transactions: transactions,
                        onTransactionTap: _onTransactionTap,
                        onDaySelected: (d) => setState(() => _selectedDay = d),
                      ),
                      MonthlyView(
                        selectedMonth: _selectedMonth,
                        transactions: transactions,
                      ),
                      TotalView(
                        selectedMonth: _selectedMonth,
                        summary: summary,
                        transactions: transactions,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onTransactionTap(Transaction t) async {
    final result = await context.goToEditTransaction<bool>(t);
    if (result == true) _refresh();
  }

  void _onTransactionLongPress(Transaction t) {
    showTransactionOptionsSheet(
      context,
      transaction: t,
      onEdit: () async {
        final result = await context.goToEditTransaction<bool>(t);
        if (result == true) _refresh();
      },
      onDeleted: _refresh,
      onBookmarkToggled: _refresh,
    );
  }
}
