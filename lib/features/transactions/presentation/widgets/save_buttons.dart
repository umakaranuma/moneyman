import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Floating save button: wide, rounded, one accent color. Premium fintech style.
class SaveTransactionButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const SaveTransactionButton({
    super.key,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
          color: color,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          shadowColor: color.withValues(alpha: 0.4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}
