import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
  });

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return AppColors.primary;
    }
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _getColorFromHex(note.color);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [cardColor, cardColor],
                      ),
                      borderRadius: BorderRadius.circular(2.5),
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Helpers.formatDateTime(note.updatedAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.expense.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.expense,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                note.content,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
