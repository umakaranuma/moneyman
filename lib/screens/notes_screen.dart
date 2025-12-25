import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/note_card.dart';
import '../core/router/app_router.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with WidgetsBindingObserver {
  DateTime _selectedMonth = DateTime.now();
  int _refreshKey = 0; // Key to force refresh

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
      setState(() {
        _refreshKey++;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _refreshKey++;
        });
      }
    });
  }

  List<Note> _getFilteredNotes() {
    final allNotes = StorageService.getAllNotes();
    return allNotes.where((note) {
      return note.createdAt.year == _selectedMonth.year &&
          note.createdAt.month == _selectedMonth.month;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final notes = _getFilteredNotes();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          key: ValueKey(_refreshKey), // Force refresh when key changes
          children: [
            // Header with Month Selector (matching home screen style)
            _buildHeader(),
            
            // Notes List
            Expanded(
              child: notes.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return NoteCard(
                          note: note,
                          onTap: () async {
                            final result = await context.goToEditNote(note);
                            if (result == true) {
                              setState(() {
                                _refreshKey++;
                              });
                            }
                          },
                          onDelete: () {
                            _showDeleteDialog(note);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceVariant, width: 1),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.note_alt_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'Notes',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Date Filter (matching home screen style)
          _buildCircleButton(
            icon: Icons.chevron_left_rounded,
            onTap: _previousMonth,
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          _buildCircleButton(
            icon: Icons.chevron_right_rounded,
            onTap: _nextMonth,
          ),
        ],
      ),
    );
  }


  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceVariant, width: 1),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.primaryLight.withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.6),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.note_alt_outlined,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notes for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first note',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () async {
        final result = await context.goToAddNote();
        if (result == true) {
          setState(() {
            _refreshKey++;
          });
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  void _showDeleteDialog(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.expense.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.delete_rounded, color: AppColors.expense, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Note',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${note.title}"?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          GestureDetector(
            onTap: () {
              StorageService.deleteNote(note.id);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 18),
                      const SizedBox(width: 10),
                      Text('Note deleted', style: GoogleFonts.inter()),
                    ],
                  ),
                  backgroundColor: AppColors.surface,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.expense.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: AppColors.expense,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
