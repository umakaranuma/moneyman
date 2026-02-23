// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../models/transaction.dart';
import '../../../../services/storage_service.dart';
import '../../../../theme/app_theme.dart';
import '../widgets/summary_card.dart';

void showTransactionOptionsSheet(
  BuildContext context, {
  required Transaction transaction,
  required VoidCallback onEdit,
  required VoidCallback onDeleted,
  required VoidCallback onBookmarkToggled,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle (iOS style)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Transaction summary
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          (transaction.type == TransactionType.income
                                  ? AppColors.income
                                  : transaction.type == TransactionType.expense
                                  ? AppColors.expense
                                  : AppColors.transfer)
                              .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      transaction.type == TransactionType.income
                          ? Icons.arrow_downward_rounded
                          : transaction.type == TransactionType.expense
                          ? Icons.arrow_upward_rounded
                          : Icons.swap_horiz_rounded,
                      color: transaction.type == TransactionType.income
                          ? AppColors.income
                          : transaction.type == TransactionType.expense
                          ? AppColors.expense
                          : AppColors.transfer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'MMM d, yyyy · h:mm a',
                          ).format(transaction.date),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rs. ${SummaryCard.formatCurrency(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: transaction.type == TransactionType.income
                          ? AppColors.income
                          : transaction.type == TransactionType.expense
                          ? AppColors.expense
                          : AppColors.transfer,
                    ),
                  ),
                ],
              ),
            ),
            // iOS-style grouped list
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _IOSOptionRow(
                      icon: Icons.edit_rounded,
                      label: 'Edit',
                      onTap: () {
                        Navigator.pop(context);
                        onEdit();
                      },
                    ),
                    _buildDivider(),
                    _IOSOptionRow(
                      icon: transaction.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      label: transaction.isBookmarked
                          ? 'Remove bookmark'
                          : 'Bookmark',
                      onTap: () async {
                        final updated = Transaction(
                          id: transaction.id,
                          title: transaction.title,
                          amount: transaction.amount,
                          type: transaction.type,
                          date: transaction.date,
                          category: transaction.category,
                          note: transaction.note,
                          accountType: transaction.accountType,
                          fromAccount: transaction.fromAccount,
                          toAccount: transaction.toAccount,
                          isBookmarked: !transaction.isBookmarked,
                          imagePaths: transaction.imagePaths,
                        );
                        await StorageService.updateTransaction(updated);
                        if (context.mounted) Navigator.pop(context);
                        onBookmarkToggled();
                      },
                    ),
                    _buildDivider(),
                    _IOSOptionRow(
                      icon: Icons.copy_rounded,
                      label: 'Copy',
                      onTap: () {
                        final text =
                            '${transaction.title}\n'
                            'Rs. ${SummaryCard.formatCurrency(transaction.amount)}\n'
                            '${DateFormat('MMM d, yyyy · h:mm a').format(transaction.date)}\n'
                            '${transaction.category ?? 'N/A'}';
                        Clipboard.setData(ClipboardData(text: text));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Transaction copied'),
                            backgroundColor: AppColors.surface,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Destructive action (separate group, iOS style)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _IOSOptionRow(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: AppColors.expense,
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, transaction, onDeleted);
                  },
                ),
              ),
            ),
            // Bottom safe area padding
            SizedBox(
              height: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom
                  : 16,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildDivider() {
  return Padding(
    padding: const EdgeInsets.only(left: 52),
    child: Divider(height: 1, color: AppColors.surfaceVariant.withOpacity(0.6)),
  );
}

class _IOSOptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _IOSOptionRow({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: c,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showDeleteConfirmation(
  BuildContext context,
  Transaction transaction,
  VoidCallback onDeleted,
) {
  showCupertinoDialog(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('Delete transaction'),
      content: const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('Are you sure? This cannot be undone.'),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () async {
            await StorageService.deleteTransaction(transaction.id);
            if (ctx.mounted) Navigator.pop(ctx);
            onDeleted();
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Transaction deleted'),
                  backgroundColor: AppColors.surface,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
