import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../core/router/app_router.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final allTodos = StorageService.getAllTodos();
    final todosForSelectedDate = StorageService.getTodosByDate(_selectedDate);
    
    // Group todos by date for summary
    final todosByDate = <DateTime, List<Todo>>{};
    for (var todo in allTodos) {
      final date = DateTime(todo.scheduledDate.year, todo.scheduledDate.month, todo.scheduledDate.day);
      todosByDate.putIfAbsent(date, () => []).add(todo);
    }

    // Get today's date for comparison
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    // Calculate summary stats
    final todayTodos = todosByDate[todayDate] ?? [];
    final todayDone = todayTodos.where((t) => t.isDone).length;
    final todayPending = todayTodos.length - todayDone;

    final isToday = selectedDateOnly.year == todayDate.year &&
        selectedDateOnly.month == todayDate.month &&
        selectedDateOnly.day == todayDate.day;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.checklist_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Todos',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary Cards
          if (isToday) _buildSummaryCards(todayDone, todayPending),
          
          // Date Picker Section
          _buildDatePicker(),
          
          // Todos List
          Expanded(
            child: todosForSelectedDate.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: todosForSelectedDate.length,
                    itemBuilder: (context, index) {
                      final todo = todosForSelectedDate[index];
                      return _buildTodoCard(todo);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildSummaryCards(int done, int pending) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Done',
              count: done,
              color: AppColors.income,
              icon: Icons.check_circle_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Pending',
              count: pending,
              color: AppColors.expense,
              icon: Icons.pending_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                '$count',
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primaryLight.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _buildDateNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  });
                },
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime.now();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Today',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildDateNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildTodoCard(Todo todo) {
    final isToday = _isToday(todo.scheduledDate);
    final isPast = todo.scheduledDate.isBefore(DateTime.now()) && !isToday;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: todo.isDone
              ? AppColors.income.withValues(alpha: 0.3)
              : (isPast
                  ? AppColors.expense.withValues(alpha: 0.3)
                  : AppColors.surfaceVariant),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              setState(() {
                final updatedTodo = todo.copyWith(isDone: !todo.isDone);
                StorageService.updateTodo(updatedTodo);
              });
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: todo.isDone
                    ? AppColors.income
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: todo.isDone
                      ? AppColors.income
                      : AppColors.textMuted,
                  width: 2,
                ),
              ),
              child: todo.isDone
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: GoogleFonts.inter(
                    color: todo.isDone
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: todo.isDone
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (todo.description != null && todo.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    todo.description!,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (todo.originalScheduledDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: AppColors.expense,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rescheduled from ${DateFormat('MMM dd').format(todo.originalScheduledDate!)}',
                        style: GoogleFonts.inter(
                          color: AppColors.expense,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'reschedule') {
                _showRescheduleDialog(todo);
              } else if (value == 'edit') {
                context.goToEditTodo(todo);
              } else if (value == 'delete') {
                _showDeleteDialog(todo);
              }
            },
            itemBuilder: (context) => [
              if (!todo.isDone)
                PopupMenuItem(
                  value: 'reschedule',
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        'Reschedule',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      'Edit',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, color: AppColors.expense, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      'Delete',
                      style: GoogleFonts.inter(
                        color: AppColors.expense,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(Todo todo) {
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Reschedule Task',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Select a new date for "${todo.title}"',
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
          ElevatedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: todo.scheduledDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        surface: AppColors.surface,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                final originalDate = todo.originalScheduledDate ?? todo.scheduledDate;
                final updatedTodo = todo.copyWith(
                  scheduledDate: picked,
                  originalScheduledDate: originalDate,
                );
                StorageService.updateTodo(updatedTodo);
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Task rescheduled to ${DateFormat('MMM dd, yyyy').format(picked)}',
                          style: GoogleFonts.inter(),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.surface,
                  ),
                );
              }
            },
            child: Text(
              'Select Date',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Todo todo) {
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
                color: AppColors.expense.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_rounded, color: AppColors.expense, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Task',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${todo.title}"?',
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
              StorageService.deleteTodo(todo.id);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 18),
                      const SizedBox(width: 10),
                      Text('Task deleted', style: GoogleFonts.inter()),
                    ],
                  ),
                  backgroundColor: AppColors.surface,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.checklist_outlined,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No tasks for this date',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a new task',
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
        final result = await context.goToAddTodo(scheduledDate: _selectedDate);
        if (result == true) {
          setState(() {});
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

