import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/sms_service.dart';
import '../services/storage_service.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../widgets/sms_analytics_tab.dart';

enum TransactionFilter { all, credit, debit }

enum ImportFilter { all, imported, notImported }

class SmsTransactionsScreen extends StatefulWidget {
  const SmsTransactionsScreen({super.key});

  @override
  State<SmsTransactionsScreen> createState() => _SmsTransactionsScreenState();
}

class _SmsTransactionsScreenState extends State<SmsTransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ParsedSmsTransaction> _allTransactions = [];
  List<ParsedSmsTransaction> _filteredTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  // Filter state
  String? _selectedBank;
  TransactionFilter _transactionFilter = TransactionFilter.all;
  ImportFilter _importFilter = ImportFilter.all;
  bool _showFilters = false;

  // Fetch all transactions toggle
  bool _fetchAllTransactions = false;

  // Bulk import state
  bool _isBulkImporting = false;
  int _bulkImportCount = 0;

  // Timer for SMS consent timeout
  int _timeoutSeconds = 300; // 5 minutes default
  Timer? _timeoutTimer;

  // Track if any transaction was imported (for home screen refresh)
  bool _hasImportedTransaction = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    // No auto-loading - user must manually import SMS via consent API
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  List<String> get _availableBanks {
    final banks = _allTransactions.map((t) => t.bankName).toSet().toList();
    banks.sort();
    return banks;
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _allTransactions.where((t) {
        // Bank filter
        if (_selectedBank != null && t.bankName != _selectedBank) {
          return false;
        }

        // Transaction type filter
        if (_transactionFilter == TransactionFilter.credit && !t.isCredit) {
          return false;
        }
        if (_transactionFilter == TransactionFilter.debit && t.isCredit) {
          return false;
        }

        // Import status filter
        if (_importFilter == ImportFilter.imported && !t.isImported) {
          return false;
        }
        if (_importFilter == ImportFilter.notImported && t.isImported) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedBank = null;
      _transactionFilter = TransactionFilter.all;
      _importFilter = ImportFilter.all;
      _filteredTransactions = List.from(_allTransactions);
    });
  }

  bool get _hasActiveFilters {
    return _selectedBank != null ||
        _transactionFilter != TransactionFilter.all ||
        _importFilter != ImportFilter.all;
  }

  /// Bulk import: Import multiple SMS transactions one by one
  /// Keeps asking user to select SMS until they cancel
  Future<void> _startBulkImport() async {
    if (!mounted) return;

    // Show confirmation dialog
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Import SMS Transactions'),
        content: const Text(
          'This will import multiple bank SMS transactions.\n\n'
          '⚠️ IMPORTANT: This only works with NEW SMS messages.\n\n'
          'How it works:\n'
          '1. Keep the app open\n'
          '2. Complete bank transactions (UPI, transfers, etc.)\n'
          '3. When each SMS arrives, Android shows "Allow" dialog\n'
          '4. Tap "Allow" to import\n'
          '5. Repeat for each transaction\n\n'
          'Tap "Cancel" when you\'re done importing.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.income,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Import'),
          ),
        ],
      ),
    );

    if (shouldContinue != true) return;

    setState(() {
      _isBulkImporting = true;
      _bulkImportCount = 0;
      _errorMessage = null;
      _timeoutSeconds = 300; // Reset to 5 minutes
    });

    // Start countdown timer
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isBulkImporting) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeoutSeconds > 0) {
          _timeoutSeconds--;
        } else {
          timer.cancel();
        }
      });
    });

    // Keep importing until user cancels
    while (_isBulkImporting && mounted) {
      final parsed = await SmsService.importSmsTransaction().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          return null;
        },
      );

      if (!mounted) break;

      if (parsed != null) {
        // Successfully imported
        setState(() {
          _allTransactions.insert(0, parsed);
          _filteredTransactions = List.from(_allTransactions);
          _applyFilters();
          _bulkImportCount++;
        });

        // Import to main transaction list
        await _importTransaction(parsed);

        // Ask if user wants to continue
        final continueImport = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Transaction Imported'),
            content: Text(
              'Successfully imported: ${parsed.bankName} - Rs. ${_formatCurrency(parsed.amount)}\n\n'
              'Total imported: $_bulkImportCount\n\n'
              'Import another transaction?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Done'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.income,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Import More'),
              ),
            ],
          ),
        );

        if (continueImport != true) {
          _timeoutTimer?.cancel();
          setState(() {
            _isBulkImporting = false;
          });
          break;
        } else {
          // Reset timer for next import
          setState(() {
            _timeoutSeconds = 300;
          });
        }
      } else {
        // User cancelled or timeout - ask what to do
        if (!mounted) break;

        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('SMS Import Issue'),
            content: Text(
              _bulkImportCount > 0
                  ? 'No SMS was selected or the request timed out.\n\n'
                        'Total imported so far: $_bulkImportCount\n\n'
                        'Possible reasons:\n'
                        '• SMS consent dialog was dismissed\n'
                        '• No SMS was selected\n'
                        '• Request timed out\n\n'
                        'What would you like to do?'
                  : 'No SMS was selected or the request timed out.\n\n'
                        'Possible reasons:\n'
                        '• SMS consent dialog was dismissed\n'
                        '• No SMS messages on device\n'
                        '• Google Play Services issue\n'
                        '• Request timed out\n\n'
                        'Make sure:\n'
                        '1. SMS consent dialog appears\n'
                        '2. Select a bank SMS message\n'
                        '3. Tap "Allow" button\n\n'
                        'What would you like to do?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'done'),
                child: const Text('Done'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.income,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: const Text('Cancel Import'),
              ),
            ],
          ),
        );

        if (action == 'done' || action == 'cancel') {
          _timeoutTimer?.cancel();
          setState(() {
            _isBulkImporting = false;
          });

          if (mounted && _bulkImportCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Bulk import completed. Imported $_bulkImportCount transaction(s).',
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (mounted && _bulkImportCount == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No transactions were imported. Please make sure to select an SMS when the dialog appears.',
                ),
                backgroundColor: AppColors.expense,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 5),
              ),
            );
          }
          break;
        }
        // If 'retry', continue the loop to try again
      }
    }

    if (mounted) {
      setState(() {
        _isBulkImporting = false;
      });
    }
  }

  /// Import SMS by pasting text (for messages that already arrived)
  Future<void> _importFromPaste() async {
    final TextEditingController textController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste SMS Text'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Copy the SMS text from your Messages app and paste it here:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Paste SMS text here...',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.income,
              foregroundColor: Colors.white,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result == true && textController.text.trim().isNotEmpty) {
      try {
        // Parse the pasted SMS text
        final parsed = SmsService.parseSmsText(textController.text.trim());

        if (parsed != null) {
          // Add to transactions list
          setState(() {
            _allTransactions.insert(0, parsed);
            _filteredTransactions = List.from(_allTransactions);
            _applyFilters();
          });

          // Import to main transaction list
          await _importTransaction(parsed);

          // Mark that a transaction was imported
          _hasImportedTransaction = true;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Transaction imported: ${parsed.bankName} - Rs. ${_formatCurrency(parsed.amount)}',
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not parse transaction from SMS text. Please check the format.',
                ),
                backgroundColor: AppColors.expense,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.expense,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// Import SMS using User Consent API (Play Store approved, user-friendly method)
  /// User taps button → Android shows SMS picker → User selects SMS → We parse and import
  /// ⚠️ Only works with NEW SMS that arrive AFTER tapping the button
  Future<void> _importSmsTransaction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _timeoutSeconds = 300; // Reset to 5 minutes
    });

    // Start countdown timer
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isLoading) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeoutSeconds > 0) {
          _timeoutSeconds--;
        } else {
          timer.cancel();
        }
      });
    });

    try {
      // Request SMS via User Consent API with timeout
      // Android will show system dialog with SMS messages
      // User selects one SMS and taps Allow
      final parsed = await SmsService.importSmsTransaction().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          setState(() {
            _isLoading = false;
            _errorMessage = 'SMS consent request timed out. Please try again.';
          });
          return null;
        },
      );

      // Ensure loading is reset even if parsed is null
      if (!mounted) return;

      if (parsed != null) {
        // Add to transactions list
        setState(() {
          _allTransactions.insert(0, parsed);
          _filteredTransactions = List.from(_allTransactions);
          _applyFilters();
          _isLoading = false;
        });

        // Import directly to main transaction list
        await _importTransaction(parsed);

        // Mark that a transaction was imported
        _hasImportedTransaction = true;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transaction imported: ${parsed.bankName} - Rs. ${_formatCurrency(parsed.amount)}',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // User cancelled, timed out, or no valid transaction found
        _timeoutTimer?.cancel();
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No new SMS received or request timed out.\n\n'
              'Remember: This only works with NEW SMS messages that arrive after tapping the button.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      _timeoutTimer?.cancel();
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error importing SMS: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importTransaction(ParsedSmsTransaction smsTransaction) async {
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title:
          '${smsTransaction.bankName} ${smsTransaction.isCredit ? "Credit" : "Debit"}',
      amount: smsTransaction.amount,
      type: smsTransaction.isCredit
          ? TransactionType.income
          : TransactionType.expense,
      date: smsTransaction.date,
      category: smsTransaction.isCredit ? 'Bank Transfer' : 'Bank Transaction',
      note: 'Imported from SMS: ${smsTransaction.rawMessage}',
      accountType: AccountType.bank,
    );

    await StorageService.addTransaction(transaction);
    await SmsService.markAsImported(smsTransaction.id);

    setState(() {
      smsTransaction.isImported = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaction imported: Rs. ${_formatCurrency(smsTransaction.amount)}',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importSelected() async {
    int importedCount = 0;

    for (final id in _selectedIds) {
      final transaction = _allTransactions.firstWhere((t) => t.id == id);
      if (!transaction.isImported) {
        await _importTransaction(transaction);
        importedCount++;
      }
    }

    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });

    if (mounted && importedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$importedCount transactions imported successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: () {
                  setState(() {
                    _selectedIds.clear();
                    _isSelectionMode = false;
                  });
                },
              )
            : GestureDetector(
                onTap: () {
                  // Return true if a transaction was imported, so home screen can refresh
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context, _hasImportedTransaction);
                  } else {
                    // If using GoRouter, use context.pop
                    context.pop(_hasImportedTransaction);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
        title: Text(
          _isSelectionMode
              ? '${_selectedIds.length} Selected'
              : 'Bank SMS Transactions',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: _isSelectionMode
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Transactions'),
                  Tab(text: 'Analytics'),
                ],
              ),
        actions: [
          if (_isSelectionMode && _selectedIds.isNotEmpty)
            TextButton.icon(
              onPressed: _importSelected,
              icon: const Icon(Icons.download, color: AppColors.income),
              label: const Text(
                'Import',
                style: TextStyle(color: AppColors.income),
              ),
            )
          else ...[
            if (!_isLoading && _allTransactions.isNotEmpty)
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: _hasActiveFilters
                          ? AppColors.income
                          : AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                  ),
                  if (_hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.income,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            if (!_isLoading && _allTransactions.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.checklist,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = true;
                  });
                },
              ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _importSmsTransaction,
          ),
        ],
      ),
      body: _isSelectionMode
          ? _buildBody()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBody(),
                SmsAnalyticsTab(transactions: _allTransactions),
              ],
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading || _isBulkImporting) {
      final minutes = _timeoutSeconds ~/ 60;
      final seconds = _timeoutSeconds % 60;
      final timeString =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.income),
                const SizedBox(height: 24),
                Text(
                  _isBulkImporting
                      ? 'Bulk Importing...\n$_bulkImportCount imported so far'
                      : 'Waiting for New Bank SMS',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.income.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.timer,
                            color: AppColors.income,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Timeout: $timeString',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.income,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '⚠️ IMPORTANT: This only works with NEW SMS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.expense,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'The app is waiting for a NEW bank SMS to arrive.\n\n'
                        'It will NOT read existing messages.\n\n'
                        'To import a transaction:\n'
                        '1. Keep this screen open\n'
                        '2. Complete a bank transaction (UPI, transfer, etc.)\n'
                        '3. OR wait for a bank alert SMS\n'
                        '4. When SMS arrives, Android will show "Allow" dialog\n'
                        '5. Tap "Allow" to import',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_isBulkImporting) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isBulkImporting = false;
                        _timeoutTimer?.cancel();
                      });
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Bulk Import'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.expense,
                      side: const BorderSide(color: AppColors.expense),
                    ),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = false;
                        _timeoutTimer?.cancel();
                      });
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Why this limitation?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Google requires explicit user consent for each SMS.\n'
                        'This ensures privacy and Play Store compliance.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.income.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.battery_charging_full,
                            size: 16,
                            color: AppColors.income,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Motorola / Android 14 Tip',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.income,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'If SMS delays occur, disable battery optimization:\n'
                        'Settings → Apps → Finzo → Battery → Unrestricted',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_allTransactions.isEmpty && !_isLoading) {
      return _buildImportButton();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.expense),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _importSmsTransaction,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.income,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_allTransactions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Filter Section
        if (_showFilters) _buildFilterSection(),

        // Active Filters Chips
        if (_hasActiveFilters && !_showFilters) _buildActiveFiltersBar(),

        _buildSummaryCard(),
        Expanded(
          child: _filteredTransactions.isEmpty
              ? _buildNoResultsState()
              : ListView.builder(
                  itemCount: _filteredTransactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionCard(_filteredTransactions[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_hasActiveFilters)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: AppColors.expense),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Bank Filter
          const Text(
            'Bank',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Banks',
                  isSelected: _selectedBank == null,
                  onTap: () {
                    setState(() {
                      _selectedBank = null;
                    });
                    _applyFilters();
                  },
                ),
                ..._availableBanks.map(
                  (bank) => _buildFilterChip(
                    label: bank,
                    isSelected: _selectedBank == bank,
                    onTap: () {
                      setState(() {
                        _selectedBank = bank;
                      });
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Transaction Type Filter
          const Text(
            'Transaction Type',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFilterChip(
                label: 'All',
                isSelected: _transactionFilter == TransactionFilter.all,
                onTap: () {
                  setState(() {
                    _transactionFilter = TransactionFilter.all;
                  });
                  _applyFilters();
                },
              ),
              _buildFilterChip(
                label: 'Credit',
                isSelected: _transactionFilter == TransactionFilter.credit,
                color: AppColors.income,
                onTap: () {
                  setState(() {
                    _transactionFilter = TransactionFilter.credit;
                  });
                  _applyFilters();
                },
              ),
              _buildFilterChip(
                label: 'Debit',
                isSelected: _transactionFilter == TransactionFilter.debit,
                color: AppColors.expense,
                onTap: () {
                  setState(() {
                    _transactionFilter = TransactionFilter.debit;
                  });
                  _applyFilters();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Import Status Filter
          const Text(
            'Import Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFilterChip(
                label: 'All',
                isSelected: _importFilter == ImportFilter.all,
                onTap: () {
                  setState(() {
                    _importFilter = ImportFilter.all;
                  });
                  _applyFilters();
                },
              ),
              _buildFilterChip(
                label: 'Imported',
                isSelected: _importFilter == ImportFilter.imported,
                color: AppColors.success,
                onTap: () {
                  setState(() {
                    _importFilter = ImportFilter.imported;
                  });
                  _applyFilters();
                },
              ),
              _buildFilterChip(
                label: 'Not Imported',
                isSelected: _importFilter == ImportFilter.notImported,
                color: AppColors.textSecondary,
                onTap: () {
                  setState(() {
                    _importFilter = ImportFilter.notImported;
                  });
                  _applyFilters();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Range Option
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _fetchAllTransactions
                    ? AppColors.income.withValues(alpha: 0.5)
                    : AppColors.surfaceVariant,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _fetchAllTransactions
                        ? AppColors.income.withValues(alpha: 0.15)
                        : AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history,
                    size: 20,
                    color: _fetchAllTransactions
                        ? AppColors.income
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fetch All Historical Transactions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _fetchAllTransactions
                            ? 'Showing all SMS transactions'
                            : 'Only showing from install date',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _fetchAllTransactions,
                  onChanged: (value) {
                    setState(() {
                      _fetchAllTransactions = value;
                    });
                    // Transactions are imported manually via paste dialog
                    // No need to reload - user will import when needed
                  },
                  activeColor: AppColors.income,
                  activeTrackColor: AppColors.income.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.income;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor.withValues(alpha: 0.2)
                : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : AppColors.surfaceVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? chipColor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: AppColors.income),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedBank != null)
                    _buildActiveFilterChip(
                      label: _selectedBank!,
                      onRemove: () {
                        setState(() {
                          _selectedBank = null;
                        });
                        _applyFilters();
                      },
                    ),
                  if (_transactionFilter != TransactionFilter.all)
                    _buildActiveFilterChip(
                      label: _transactionFilter == TransactionFilter.credit
                          ? 'Credit'
                          : 'Debit',
                      color: _transactionFilter == TransactionFilter.credit
                          ? AppColors.income
                          : AppColors.expense,
                      onRemove: () {
                        setState(() {
                          _transactionFilter = TransactionFilter.all;
                        });
                        _applyFilters();
                      },
                    ),
                  if (_importFilter != ImportFilter.all)
                    _buildActiveFilterChip(
                      label: _importFilter == ImportFilter.imported
                          ? 'Imported'
                          : 'Not Imported',
                      onRemove: () {
                        setState(() {
                          _importFilter = ImportFilter.all;
                        });
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _showFilters = true;
              });
            },
            child: const Text(
              'Edit',
              style: TextStyle(color: AppColors.income, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onRemove,
    Color color = AppColors.income,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions match your filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              'Clear Filters',
              style: TextStyle(color: AppColors.income),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportButton() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceVariant, width: 2),
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 64,
                  color: AppColors.income,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Import Bank Transaction',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Import bank transactions from SMS messages.\n\n'
                '⚠️ IMPORTANT: This only works with NEW SMS messages.\n\n'
                'How it works:\n'
                '1. Tap "Import Bank SMS" below\n'
                '2. Keep the app open and wait\n'
                '3. Complete a bank transaction (UPI, transfer, etc.)\n'
                '4. OR wait for a bank alert SMS\n'
                '5. When SMS arrives, Android shows "Allow" dialog\n'
                '6. Tap "Allow" to import the transaction\n\n'
                '✨ No copy-paste needed!\n'
                '🔒 Privacy: We only read SMS you explicitly allow. All data stays on your device.',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _importSmsTransaction,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sms),
                label: Text(_isLoading ? 'Importing...' : 'Import New SMS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.income,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _importFromPaste,
                icon: const Icon(Icons.paste),
                label: const Text('Paste Existing SMS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.income,
                  side: const BorderSide(color: AppColors.income),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '💡 Tip: Use "Paste Existing SMS" for messages that already arrived',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isLoading || _isBulkImporting
                    ? null
                    : _startBulkImport,
                icon: _isBulkImporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(
                  _isBulkImporting
                      ? 'Bulk Importing... ($_bulkImportCount imported)'
                      : 'Bulk Import Multiple SMS',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.income,
                  side: const BorderSide(color: AppColors.income),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final installDate = SmsService.getInstallDate();
    final monthName = DateFormat('MMMM yyyy').format(installDate);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Bank Transactions Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _fetchAllTransactions
                  ? 'No bank SMS messages found in your inbox'
                  : 'No bank SMS messages found since $monthName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (!_fetchAllTransactions) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _fetchAllTransactions = true;
                  });
                  // Transactions are imported manually via paste dialog
                  // No need to reload - user will import when needed
                },
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Fetch All Historical Transactions'),
                style: TextButton.styleFrom(foregroundColor: AppColors.income),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    // Calculate based on filtered transactions
    final totalCredit = _filteredTransactions
        .where((t) => t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalDebit = _filteredTransactions
        .where((t) => !t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);
    final importedCount = _filteredTransactions
        .where((t) => t.isImported)
        .length;
    final installDate = SmsService.getInstallDate();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sms, color: AppColors.income, size: 20),
              const SizedBox(width: 8),
              Text(
                _hasActiveFilters ? 'Filtered Results' : 'Transaction Summary',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _fetchAllTransactions
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.income.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _fetchAllTransactions
                          ? Icons.all_inclusive
                          : Icons.calendar_today,
                      size: 10,
                      color: _fetchAllTransactions
                          ? AppColors.success
                          : AppColors.income,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _fetchAllTransactions
                          ? 'All Time'
                          : 'Since ${DateFormat('MMM').format(installDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _fetchAllTransactions
                            ? AppColors.success
                            : AppColors.income,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Credited',
                  'Rs. ${_formatCurrency(totalCredit)}',
                  AppColors.income,
                  Icons.arrow_downward,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.surfaceVariant),
              Expanded(
                child: _buildSummaryItem(
                  'Debited',
                  'Rs. ${_formatCurrency(totalDebit)}',
                  AppColors.expense,
                  Icons.arrow_upward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _hasActiveFilters
                      ? '${_filteredTransactions.length} of ${_allTransactions.length} transactions'
                      : '${_filteredTransactions.length} transactions found',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$importedCount imported',
                  style: TextStyle(
                    fontSize: 12,
                    color: importedCount > 0
                        ? AppColors.income
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(ParsedSmsTransaction transaction) {
    final isSelected = _selectedIds.contains(transaction.id);
    final dateStr = DateFormat('MMM dd, yyyy').format(transaction.date);
    final timeStr = DateFormat('hh:mm a').format(transaction.date);

    return GestureDetector(
      onLongPress: () {
        if (!transaction.isImported) {
          setState(() {
            _isSelectionMode = true;
            _selectedIds.add(transaction.id);
          });
        }
      },
      onTap: () {
        if (_isSelectionMode && !transaction.isImported) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(transaction.id);
              if (_selectedIds.isEmpty) {
                _isSelectionMode = false;
              }
            } else {
              _selectedIds.add(transaction.id);
            }
          });
        } else {
          _showTransactionDetails(transaction);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.income.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.income
                : transaction.isImported
                ? AppColors.surfaceVariant.withValues(alpha: 0.5)
                : AppColors.surfaceVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection checkbox or transaction icon
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.income : Colors.transparent,
                    border: Border.all(
                      color: transaction.isImported
                          ? AppColors.textMuted
                          : isSelected
                          ? AppColors.income
                          : AppColors.textSecondary,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: transaction.isCredit
                      ? AppColors.income.withValues(alpha: 0.15)
                      : AppColors.expense.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  transaction.isCredit
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: transaction.isCredit
                      ? AppColors.income
                      : AppColors.expense,
                  size: 22,
                ),
              ),

            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          transaction.bankName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: transaction.isImported
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (transaction.isImported)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.income.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Imported',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.income,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: transaction.isImported
                              ? AppColors.textMuted.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: transaction.isImported
                              ? AppColors.textMuted.withValues(alpha: 0.5)
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (transaction.accountNumber != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        transaction.accountNumber!,
                        style: TextStyle(
                          fontSize: 11,
                          color: transaction.isImported
                              ? AppColors.textMuted.withValues(alpha: 0.5)
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. ${_formatCurrency(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: transaction.isImported
                        ? AppColors.textMuted
                        : transaction.isCredit
                        ? AppColors.income
                        : AppColors.expense,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: transaction.isImported
                        ? AppColors.textMuted.withValues(alpha: 0.2)
                        : transaction.isCredit
                        ? AppColors.income.withValues(alpha: 0.15)
                        : AppColors.expense.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.isCredit ? 'CREDIT' : 'DEBIT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: transaction.isImported
                          ? AppColors.textMuted
                          : transaction.isCredit
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(ParsedSmsTransaction transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: transaction.isCredit
                          ? AppColors.income.withValues(alpha: 0.15)
                          : AppColors.expense.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      transaction.isCredit
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: transaction.isCredit
                          ? AppColors.income
                          : AppColors.expense,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.bankName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy - hh:mm a',
                          ).format(transaction.date),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rs. ${_formatCurrency(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: transaction.isCredit
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Message content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Original Message',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      transaction.rawMessage,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action button
              if (!transaction.isImported)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _importTransaction(transaction);
                      // Mark that a transaction was imported
                      _hasImportedTransaction = true;
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Import as Transaction'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.income,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.income,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Already Imported',
                        style: TextStyle(
                          color: AppColors.income,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
