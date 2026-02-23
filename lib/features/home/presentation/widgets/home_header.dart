import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool showYearOnly;
  final VoidCallback? onSearch;
  final VoidCallback? onFilter;
  final VoidCallback? onBookmark;
  final VoidCallback? onNotes;
  final VoidCallback? onClearFilters;
  final bool hasActiveFilters;
  final bool hasSearchQuery;

  const HomeHeader({
    super.key,
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
    this.showYearOnly = false,
    this.onSearch,
    this.onFilter,
    this.onBookmark,
    this.onNotes,
    this.onClearFilters,
    this.hasActiveFilters = false,
    this.hasSearchQuery = false,
  });

  @override
  Widget build(BuildContext context) {
    final headerText = showYearOnly
        ? '${selectedMonth.year}'
        : DateFormat('MMMM yyyy').format(selectedMonth);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          _ActionIcon(
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              headerText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _ActionIcon(
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
          ),
          const SizedBox(width: 6),
          if (onBookmark != null)
            _ActionIcon(icon: Icons.bookmark_rounded, onTap: onBookmark!),
          if (onBookmark != null) const SizedBox(width: 6),
          if (onNotes != null)
            _ActionIcon(icon: Icons.sticky_note_2_rounded, onTap: onNotes!),
          if (onNotes != null) const SizedBox(width: 6),
          if (onSearch != null)
            _ActionIcon(
              icon: Icons.search_rounded,
              onTap: onSearch!,
              highlight: hasSearchQuery,
            ),
          if (onSearch != null) const SizedBox(width: 6),
          if (onFilter != null)
            _ActionIcon(
              icon: Icons.tune_rounded,
              onTap: onFilter!,
              highlight: hasActiveFilters,
            ),
          if ((hasSearchQuery || hasActiveFilters) && onClearFilters != null) ...[
            const SizedBox(width: 6),
            _ActionIcon(
              icon: Icons.clear_all_rounded,
              onTap: onClearFilters!,
              highlightColor: AppColors.error,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;
  final Color? highlightColor;

  const _ActionIcon({
    required this.icon,
    required this.onTap,
    this.highlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? (highlightColor ?? AppColors.primary) : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
