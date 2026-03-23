import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/note.dart';
import '../models/todo.dart';
import '../models/reminder.dart';

class StorageService {
  static const String _transactionBoxName = 'transactions';
  static const String _noteBoxName = 'notes';
  static const String _todoBoxName = 'todos';
  static const String _reminderBoxName = 'reminders';
  static const String _settingsBoxName = 'settings';
  static const String _keyDefaultCurrency = 'default_currency';
  static const String _keyConfigSubcategoryEnabled = 'config_subcategory_enabled';
  static const String _keyConfigSubCurrency = 'config_sub_currency';
  static const String _keyConfigStartScreen = 'config_start_screen';
  static const String _keyConfigMonthlyStartDate = 'config_monthly_start_date';
  static const String _keyConfigWeeklyStartDay = 'config_weekly_start_day';
  static const String _keyConfigCarryOverEnabled = 'config_carry_over_enabled';
  static const String _keyConfigSwipeMode = 'config_swipe_mode';
  static const String _keyConfigColorSetting = 'config_color_setting';
  static const String _keyConfigTimeInput = 'config_time_input';
  static const String _keyConfigShowDescription = 'config_show_description';
  static const String _keyConfigAutocomplete = 'config_autocomplete';
  static const String _keyConfigInputOrder = 'config_input_order';
  static const String _keyConfigNoteButtonEnabled = 'config_note_button_enabled';
  static const String _keyConfigPasscodeEnabled = 'config_passcode_enabled';
  static const String _keyConfigAlarmEnabled = 'config_alarm_enabled';
  static const String _keyConfigQuickAddEnabled = 'config_quick_add_enabled';
  static const String _keyConfigStyle = 'config_style';
  static const String _keyConfigLanguage = 'config_language';
  static const String _keyLastHandledNotificationLaunchSignature =
      'last_handled_notification_launch_signature';

  /// Key and box for pending notification route (used by NotificationNavigationHandler; box name for background isolate).
  static const String pendingNotificationRouteKey = 'pending_notification_route';
  static const String settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Open boxes (using dynamic type to store JSON maps)
    await Hive.openBox(_transactionBoxName);
    await Hive.openBox(_noteBoxName);
    await Hive.openBox(_todoBoxName);
    await Hive.openBox(_reminderBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  static Box get _settingsBox => Hive.box(_settingsBoxName);

  /// Default currency for new accounts (e.g. 'lkr', 'usd'). Returns null if not set.
  static String? getDefaultCurrencyCode() {
    return _settingsBox.get(_keyDefaultCurrency) as String?;
  }

  static Future<void> setDefaultCurrencyCode(String currencyCode) async {
    await _settingsBox.put(_keyDefaultCurrency, currencyCode);
  }

  // Configuration settings
  static bool getConfigSubcategoryEnabled() {
    return (_settingsBox.get(_keyConfigSubcategoryEnabled) as bool?) ?? true;
  }

  static Future<void> setConfigSubcategoryEnabled(bool value) async {
    await _settingsBox.put(_keyConfigSubcategoryEnabled, value);
  }

  static String getConfigSubCurrency() {
    return (_settingsBox.get(_keyConfigSubCurrency) as String?) ?? r'$';
  }

  static Future<void> setConfigSubCurrency(String value) async {
    await _settingsBox.put(_keyConfigSubCurrency, value);
  }

  static String getConfigStartScreen() {
    return (_settingsBox.get(_keyConfigStartScreen) as String?) ?? 'Daily';
  }

  static Future<void> setConfigStartScreen(String value) async {
    await _settingsBox.put(_keyConfigStartScreen, value);
  }

  static int getConfigMonthlyStartDate() {
    return (_settingsBox.get(_keyConfigMonthlyStartDate) as int?) ?? 1;
  }

  static Future<void> setConfigMonthlyStartDate(int value) async {
    await _settingsBox.put(_keyConfigMonthlyStartDate, value);
  }

  static String getConfigWeeklyStartDay() {
    return (_settingsBox.get(_keyConfigWeeklyStartDay) as String?) ?? 'Sunday';
  }

  static Future<void> setConfigWeeklyStartDay(String value) async {
    await _settingsBox.put(_keyConfigWeeklyStartDay, value);
  }

  static bool getConfigCarryOverEnabled() {
    return (_settingsBox.get(_keyConfigCarryOverEnabled) as bool?) ?? true;
  }

  static Future<void> setConfigCarryOverEnabled(bool value) async {
    await _settingsBox.put(_keyConfigCarryOverEnabled, value);
  }

  static String getConfigSwipeMode() {
    return (_settingsBox.get(_keyConfigSwipeMode) as String?) ?? 'To Change Date';
  }

  static Future<void> setConfigSwipeMode(String value) async {
    await _settingsBox.put(_keyConfigSwipeMode, value);
  }

  static String getConfigColorSetting() {
    return (_settingsBox.get(_keyConfigColorSetting) as String?) ?? 'Set. A';
  }

  static Future<void> setConfigColorSetting(String value) async {
    await _settingsBox.put(_keyConfigColorSetting, value);
  }

  static String getConfigTimeInput() {
    return (_settingsBox.get(_keyConfigTimeInput) as String?) ?? 'Input Only, Desc.';
  }

  static Future<void> setConfigTimeInput(String value) async {
    await _settingsBox.put(_keyConfigTimeInput, value);
  }

  static bool getConfigShowDescription() {
    return (_settingsBox.get(_keyConfigShowDescription) as bool?) ?? false;
  }

  static Future<void> setConfigShowDescription(bool value) async {
    await _settingsBox.put(_keyConfigShowDescription, value);
  }

  static bool getConfigAutocomplete() {
    return (_settingsBox.get(_keyConfigAutocomplete) as bool?) ?? true;
  }

  static Future<void> setConfigAutocomplete(bool value) async {
    await _settingsBox.put(_keyConfigAutocomplete, value);
  }

  static String getConfigInputOrder() {
    return (_settingsBox.get(_keyConfigInputOrder) as String?) ?? 'From Amount';
  }

  static Future<void> setConfigInputOrder(String value) async {
    await _settingsBox.put(_keyConfigInputOrder, value);
  }

  static bool getConfigNoteButtonEnabled() {
    return (_settingsBox.get(_keyConfigNoteButtonEnabled) as bool?) ?? false;
  }

  static Future<void> setConfigNoteButtonEnabled(bool value) async {
    await _settingsBox.put(_keyConfigNoteButtonEnabled, value);
  }

  static bool getConfigPasscodeEnabled() {
    return (_settingsBox.get(_keyConfigPasscodeEnabled) as bool?) ?? false;
  }

  static Future<void> setConfigPasscodeEnabled(bool value) async {
    await _settingsBox.put(_keyConfigPasscodeEnabled, value);
  }

  static bool getConfigAlarmEnabled() {
    return (_settingsBox.get(_keyConfigAlarmEnabled) as bool?) ?? true;
  }

  static Future<void> setConfigAlarmEnabled(bool value) async {
    await _settingsBox.put(_keyConfigAlarmEnabled, value);
  }

  static bool getConfigQuickAddEnabled() {
    return (_settingsBox.get(_keyConfigQuickAddEnabled) as bool?) ?? false;
  }

  static Future<void> setConfigQuickAddEnabled(bool value) async {
    await _settingsBox.put(_keyConfigQuickAddEnabled, value);
  }

  static String getConfigStyle() {
    return (_settingsBox.get(_keyConfigStyle) as String?) ?? 'Dark';
  }

  static Future<void> setConfigStyle(String value) async {
    await _settingsBox.put(_keyConfigStyle, value);
  }

  static String getConfigLanguage() {
    return (_settingsBox.get(_keyConfigLanguage) as String?) ?? 'English';
  }

  static Future<void> setConfigLanguage(String value) async {
    await _settingsBox.put(_keyConfigLanguage, value);
  }

  /// Pending notification route (e.g. 'todos', 'home', 'reminders|123'). Used when app is opened from a notification tap.
  static Future<void> setPendingNotificationRoute(String? route) async {
    if (route == null || route.isEmpty) {
      await _settingsBox.delete(pendingNotificationRouteKey);
    } else {
      await _settingsBox.put(pendingNotificationRouteKey, route);
    }
  }

  /// Read and clear the pending notification route. Returns null if none.
  static Future<String?> getAndClearPendingNotificationRoute() async {
    final v = _settingsBox.get(pendingNotificationRouteKey) as String?;
    if (v != null && v.toString().isNotEmpty) {
      await _settingsBox.delete(pendingNotificationRouteKey);
    }
    return v != null && v.toString().isNotEmpty ? v.toString() : null;
  }

  /// Signature of the last notification launch event handled on startup.
  /// Used to avoid opening the same notification route again after normal app restarts.
  static String? getLastHandledNotificationLaunchSignature() {
    return _settingsBox.get(_keyLastHandledNotificationLaunchSignature) as String?;
  }

  static Future<void> setLastHandledNotificationLaunchSignature(
    String? signature,
  ) async {
    if (signature == null || signature.isEmpty) {
      await _settingsBox.delete(_keyLastHandledNotificationLaunchSignature);
    } else {
      await _settingsBox.put(_keyLastHandledNotificationLaunchSignature, signature);
    }
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

  // Reminder methods
  static Box get _reminderBox => Hive.box(_reminderBoxName);

  static Future<void> addReminder(Reminder reminder) async {
    await _reminderBox.put(reminder.id, reminder.toJson());
  }

  static Future<void> updateReminder(Reminder reminder) async {
    await _reminderBox.put(reminder.id, reminder.toJson());
  }

  static Future<void> deleteReminder(String id) async {
    await _reminderBox.delete(id);
  }

  static List<Reminder> getAllReminders() {
    final reminders = _reminderBox.values
        .map((json) => Reminder.fromJson(Map<String, dynamic>.from(json)))
        .toList();
    reminders.sort((a, b) {
      final aDate = a.effectiveDate ?? DateTime(0);
      final bDate = b.effectiveDate ?? DateTime(0);
      return aDate.compareTo(bDate);
    });
    return reminders;
  }

  static Reminder? getReminder(String id) {
    final json = _reminderBox.get(id);
    if (json == null) return null;
    return Reminder.fromJson(Map<String, dynamic>.from(json));
  }

  static Future<void> clearAllData() async {
    await _transactionBox.clear();
    await _noteBox.clear();
    await _todoBox.clear();
    await _reminderBox.clear();
  }
}
