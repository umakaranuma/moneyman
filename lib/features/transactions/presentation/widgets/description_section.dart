import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';

/// Description (title) and Note. Single card, soft shadow.
class DescriptionSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController noteController;
  final Color color;

  const DescriptionSection({
    super.key,
    required this.titleController,
    required this.noteController,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            'Description *',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: titleController,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'What was this for?',
              hintStyle: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Description is required' : null,
          ),
          const SizedBox(height: 20),
          Text(
            'Note',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: noteController,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Add a note',
              hintStyle: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            maxLines: 3,
            minLines: 1,
          ),
        ],
      ),
    );
  }
}
