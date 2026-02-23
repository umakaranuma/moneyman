import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/transaction.dart';
import '../../../../services/storage_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/router/app_router.dart';

class HomeSearchScreen extends StatefulWidget {
  final String initialQuery;

  const HomeSearchScreen({super.key, required this.initialQuery});

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  late TextEditingController _controller;
  List<Transaction> _all = [];
  List<Transaction> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _controller.addListener(_applyFilter);
    _load();
  }

  @override
  void dispose() {
    _controller.removeListener(_applyFilter);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = StorageService.getAllTransactions();
    setState(() {
      _all = list;
      _loading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    final q = _controller.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_all)
          : _all.where((t) =>
              t.title.toLowerCase().contains(q) ||
              (t.category?.toLowerCase().contains(q) ?? false) ||
              (t.note?.toLowerCase().contains(q) ?? false)).toList();
    });
  }

  static String _fmt(double n) => NumberFormat('#,##0', 'en_US').format(n);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search by title, category, note...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                    onPressed: () => _controller.clear(),
                  )
                : null,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
              ? Center(
                  child: Text(
                    _controller.text.isEmpty ? 'No transactions' : 'No results',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final t = _filtered[i];
                    final color = t.type == TransactionType.income
                        ? AppColors.income
                        : t.type == TransactionType.expense
                            ? AppColors.expense
                            : AppColors.transfer;
                    return ListTile(
                      onTap: () async {
                        final result = await context.goToEditTransaction<bool>(t);
                        if (result == true) _load();
                      },
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          t.type == TransactionType.income
                              ? Icons.arrow_downward_rounded
                              : t.type == TransactionType.expense
                                  ? Icons.arrow_upward_rounded
                                  : Icons.swap_horiz_rounded,
                          color: color,
                        ),
                      ),
                      title: Text(
                        t.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        t.category ?? 'Other',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      trailing: Text(
                        'Rs. ${_fmt(t.amount)}',
                        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    );
                  },
                ),
    );
  }
}
