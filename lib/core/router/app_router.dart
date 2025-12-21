import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/main_navigation.dart';
import '../../screens/add_edit_transaction_screen.dart';
import '../../screens/notes_screen.dart';
import '../../screens/add_edit_note_screen.dart';
import '../../screens/categories_screen.dart';
import '../../screens/sms_transactions_screen.dart';
import '../../models/transaction.dart';
import '../../models/note.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Main navigation shell
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MainNavigation(),
      ),
      
      // Transaction routes
      GoRoute(
        path: '/transaction/add',
        name: 'addTransaction',
        pageBuilder: (context, state) {
          final type = state.extra as TransactionType?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AddEditTransactionScreen(initialType: type),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/transaction/edit',
        name: 'editTransaction',
        pageBuilder: (context, state) {
          final transaction = state.extra as Transaction;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AddEditTransactionScreen(transaction: transaction),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      
      // Notes routes
      GoRoute(
        path: '/notes',
        name: 'notes',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const NotesScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/notes/add',
        name: 'addNote',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const AddEditNoteScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/notes/edit',
        name: 'editNote',
        pageBuilder: (context, state) {
          final note = state.extra as Note;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AddEditNoteScreen(note: note),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      
      // Categories route
      GoRoute(
        path: '/categories',
        name: 'categories',
        pageBuilder: (context, state) {
          final isExpense = state.extra as bool? ?? true;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CategoriesScreen(isExpense: isExpense),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      
      // SMS Transactions route
      GoRoute(
        path: '/sms-transactions',
        name: 'smsTransactions',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SmsTransactionsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
          );
        },
      ),
    ],
  );
}

// Extension for easy navigation
extension GoRouterExtension on BuildContext {
  Future<T?> goToAddTransaction<T>({TransactionType? type}) async {
    final result = await GoRouter.of(this).pushNamed('addTransaction', extra: type);
    return result as T?;
  }
  
  Future<T?> goToEditTransaction<T>(Transaction transaction) async {
    final result = await GoRouter.of(this).pushNamed('editTransaction', extra: transaction);
    return result as T?;
  }
  
  void goToNotes() {
    GoRouter.of(this).pushNamed('notes');
  }
  
  void goToAddNote() {
    GoRouter.of(this).pushNamed('addNote');
  }
  
  void goToEditNote(Note note) {
    GoRouter.of(this).pushNamed('editNote', extra: note);
  }
  
  void goToCategories({bool isExpense = true}) {
    GoRouter.of(this).pushNamed('categories', extra: isExpense);
  }
  
  Future<T?> goToSmsTransactions<T>() async {
    final result = await GoRouter.of(this).pushNamed('smsTransactions');
    return result as T?;
  }
}

