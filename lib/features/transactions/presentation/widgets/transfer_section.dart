import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';

/// Transfer-specific: From Account & To Account. Clean card, no gradients.
class TransferSection extends StatelessWidget {
  final String? fromAccount;
  final String? toAccount;
  final ValueChanged<String> onFromChanged;
  final ValueChanged<String> onToChanged;

  const TransferSection({
    super.key,
    required this.fromAccount,
    required this.toAccount,
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'From Account',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: fromAccount,
            onChanged: onFromChanged,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter from account',
              hintStyle: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'To Account',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: toAccount,
            onChanged: onToChanged,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter to account',
              hintStyle: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
