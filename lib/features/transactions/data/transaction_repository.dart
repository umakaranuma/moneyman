import '../domain/transaction.dart';
import '../../../services/storage_service.dart';

/// Repository for transaction persistence. Delegates to [StorageService].
class TransactionRepository {
  Future<void> add(Transaction transaction) async {
    await StorageService.addTransaction(transaction);
  }

  Future<void> update(Transaction transaction) async {
    await StorageService.updateTransaction(transaction);
  }

  Future<void> delete(String id) async {
    await StorageService.deleteTransaction(id);
  }

  Transaction? getById(String id) => StorageService.getTransaction(id);

  List<Transaction> getAll() => StorageService.getAllTransactions();
}
