import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/note.dart';
import '../models/todo.dart';

class StorageService {
  static const String _transactionBoxName = 'transactions';
  static const String _noteBoxName = 'notes';
  static const String _todoBoxName = 'todos';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Open boxes (using dynamic type to store JSON maps)
    await Hive.openBox(_transactionBoxName);
    await Hive.openBox(_noteBoxName);
    await Hive.openBox(_todoBoxName);
  }

  // Transaction methods
  static Box get _transactionBox => Hive.box(_transactionBoxName);

  static Future<void> addTransaction(Transaction transaction) async {
    await _transactionBox.put(transaction.id, transaction.toJson());
  }

  static Future<void> updateTransaction(Transaction transaction) async {
    await _transactionBox.put(transaction.id, transaction.toJson());
  }

  static Future<void> deleteTransaction(String id) async {
    await _transactionBox.delete(id);
  }

  static List<Transaction> getAllTransactions() {
    final transactions = _transactionBox.values
        .map((json) => Transaction.fromJson(Map<String, dynamic>.from(json)))
        .toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  static Transaction? getTransaction(String id) {
    final json = _transactionBox.get(id);
    if (json == null) return null;
    return Transaction.fromJson(Map<String, dynamic>.from(json));
  }

  static double getTotalIncome() {
    return getAllTransactions()
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  static double getTotalExpense() {
    return getAllTransactions()
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  static double getTotalTransfer() {
    return getAllTransactions()
        .where((t) => t.type == TransactionType.transfer)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  static double getBalance() {
    return getTotalIncome() - getTotalExpense();
  }

  // Note methods
  static Box get _noteBox => Hive.box(_noteBoxName);

  static Future<void> addNote(Note note) async {
    await _noteBox.put(note.id, note.toJson());
  }

  static Future<void> updateNote(Note note) async {
    note.updatedAt = DateTime.now();
    await _noteBox.put(note.id, note.toJson());
  }

  static Future<void> deleteNote(String id) async {
    await _noteBox.delete(id);
  }

  static List<Note> getAllNotes() {
    final notes = _noteBox.values
        .map((json) => Note.fromJson(Map<String, dynamic>.from(json)))
        .toList();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  static Note? getNote(String id) {
    final json = _noteBox.get(id);
    if (json == null) return null;
    return Note.fromJson(Map<String, dynamic>.from(json));
  }

  // Todo methods
  static Box get _todoBox => Hive.box(_todoBoxName);

  static Future<void> addTodo(Todo todo) async {
    await _todoBox.put(todo.id, todo.toJson());
  }

  static Future<void> updateTodo(Todo todo) async {
    todo.updatedAt = DateTime.now();
    await _todoBox.put(todo.id, todo.toJson());
  }

  static Future<void> deleteTodo(String id) async {
    await _todoBox.delete(id);
  }

  static List<Todo> getAllTodos() {
    final todos = _todoBox.values
        .map((json) => Todo.fromJson(Map<String, dynamic>.from(json)))
        .toList();
    todos.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return todos;
  }

  static List<Todo> getTodosByDate(DateTime date) {
    final allTodos = getAllTodos();
    final targetDate = DateTime(date.year, date.month, date.day);
    return allTodos.where((todo) {
      final todoDate = DateTime(todo.scheduledDate.year, todo.scheduledDate.month, todo.scheduledDate.day);
      return todoDate.year == targetDate.year &&
          todoDate.month == targetDate.month &&
          todoDate.day == targetDate.day;
    }).toList();
  }

  static Todo? getTodo(String id) {
    final json = _todoBox.get(id);
    if (json == null) return null;
    return Todo.fromJson(Map<String, dynamic>.from(json));
  }

  static Future<void> clearAllData() async {
    await _transactionBox.clear();
    await _noteBox.clear();
    await _todoBox.clear();
  }
}
