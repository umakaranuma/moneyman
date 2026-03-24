import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/transaction.dart';
import '../../../../theme/app_theme.dart';

/// Premium amount block: LKR, large bold typography, soft shadow. No gradients.
class AmountSection extends StatelessWidget {
  final TextEditingController controller;
  final Color color;
  final TransactionType type;
  final VoidCallback? onCalculatorTap;
  final String? budgetWarning;

  const AmountSection({
    super.key,
    required this.controller,
    required this.color,
    required this.type,
    this.onCalculatorTap,
    this.budgetWarning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Amount',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LKR ',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: GoogleFonts.inter(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    if (double.tryParse(value.trim()) == null ||
                        double.parse(value.trim()) <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
              ),
              if (onCalculatorTap != null)
                IconButton(
                  onPressed: onCalculatorTap,
                  icon: Icon(
                    Icons.calculate_outlined,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ),
            ],
          ),
          if (budgetWarning != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      budgetWarning!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
