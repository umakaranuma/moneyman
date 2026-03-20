import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/transaction.dart';

class TotalExportService {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthNameFormat = DateFormat('MMMM');
  static const PdfColor _finzoPrimary = PdfColor(
    249 / 255,
    106 / 255,
    70 / 255,
  );
  static const PdfColor _finzoPrimaryLight = PdfColor(
    255 / 255,
    239 / 255,
    233 / 255,
  );
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _fileOpenChannel = MethodChannel(
    'finzo/file_open',
  );
  static const MethodChannel _downloadsChannel = MethodChannel(
    'finzo/downloads',
  );
  static bool _notificationsInitialized = false;

  static Future<String> exportExcel({
    required DateTime selectedMonth,
    required int comparisonPercent,
    required double cashExpenses,
    required double cardExpenses,
    required double transfers,
    required List<Transaction> monthTransactions,
  }) async {
    final monthlyIncome = _sumByType(monthTransactions, TransactionType.income);
    final monthlyExpenses = cashExpenses + cardExpenses;
    final monthlyAvailableBalance = monthlyIncome - monthlyExpenses - transfers;
    final transferTransactions = monthTransactions
        .where((tx) => tx.type == TransactionType.transfer)
        .toList();

    final excel = Excel.createExcel();
    final summarySheet = excel['Summary'];
    final transactionsSheet = excel['Transactions'];
    final transfersSheet = excel['Transfers'];

    summarySheet.appendRow([TextCellValue('Metric'), TextCellValue('Value')]);
    summarySheet.appendRow([
      TextCellValue('Month'),
      TextCellValue(DateFormat('MMMM yyyy').format(selectedMonth)),
    ]);
    summarySheet.appendRow([
      TextCellValue('Compared Expenses (Last month)'),
      TextCellValue('$comparisonPercent%'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Expenses (Cash, Accounts)'),
      TextCellValue(_currency(cashExpenses)),
    ]);
    summarySheet.appendRow([
      TextCellValue('Expenses (Card)'),
      TextCellValue(_currency(cardExpenses)),
    ]);
    summarySheet.appendRow([
      TextCellValue('Transfers'),
      TextCellValue(_currency(transfers)),
    ]);
    summarySheet.appendRow([
      TextCellValue('Monthly Income'),
      TextCellValue(_currency(monthlyIncome)),
    ]);
    summarySheet.appendRow([
      TextCellValue('Monthly Available Balance'),
      TextCellValue(_currency(monthlyAvailableBalance)),
    ]);

    transactionsSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Title'),
      TextCellValue('Type'),
      TextCellValue('Account'),
      TextCellValue('Category'),
      TextCellValue('Amount'),
      TextCellValue('Note'),
    ]);

    for (final tx in monthTransactions) {
      transactionsSheet.appendRow([
        TextCellValue(_dateFormat.format(tx.date)),
        TextCellValue(tx.title),
        TextCellValue(tx.type.name),
        TextCellValue(tx.accountType.name),
        TextCellValue(tx.category ?? ''),
        TextCellValue(_currency(tx.amount)),
        TextCellValue(tx.note ?? ''),
      ]);
    }

    transfersSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Title'),
      TextCellValue('From'),
      TextCellValue('To'),
      TextCellValue('Amount'),
      TextCellValue('Note'),
    ]);
    for (final tx in transferTransactions) {
      transfersSheet.appendRow([
        TextCellValue(_dateFormat.format(tx.date)),
        TextCellValue(tx.title),
        TextCellValue(tx.fromAccount ?? tx.accountType.name),
        TextCellValue(tx.toAccount ?? '-'),
        TextCellValue(_currency(tx.amount)),
        TextCellValue(tx.note ?? ''),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to generate Excel file.');
    }

    final fileName = _buildFileName(
      selectedMonth: selectedMonth,
      extension: 'xlsx',
    );
    final saved = await _saveExportBytes(
      fileName: fileName,
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    debugPrint('Export saved (Excel): ${saved.pathOrUri}');
    await _tryShowDownloadNotification(
      fileName: saved.fileName,
      filePath: saved.pathOrUri,
    );
    return saved.pathOrUri;
  }

  static Future<String> exportPdf({
    required DateTime selectedMonth,
    required int comparisonPercent,
    required double cashExpenses,
    required double cardExpenses,
    required double transfers,
    required List<Transaction> monthTransactions,
  }) async {
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final logo = await _loadFinzoLogo();
    final doc = pw.Document();
    final monthTitle = DateFormat('MMMM yyyy').format(selectedMonth);
    final monthlyIncome = _sumByType(monthTransactions, TransactionType.income);
    final monthlyExpenses = cashExpenses + cardExpenses;
    final monthlyAvailableBalance = monthlyIncome - monthlyExpenses - transfers;
    final transferTransactions = monthTransactions
        .where((tx) => tx.type == TransactionType.transfer)
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(24),
          pageFormat: PdfPageFormat.a4,
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _finzoPrimaryLight,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null)
                  pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(
                      logo,
                      width: 38,
                      height: 38,
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                if (logo != null) pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Finzo Monthly Financial Report',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          font: boldFont,
                          color: _finzoPrimary,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Month: $monthTitle',
                        style: pw.TextStyle(font: regularFont),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Metric', 'Value'],
            data: [
              ['Compared Expenses (Last month)', '$comparisonPercent%'],
              ['Monthly Income', _currency(monthlyIncome)],
              ['Expenses (Cash, Accounts)', _currency(cashExpenses)],
              ['Expenses (Card)', _currency(cardExpenses)],
              ['Transfers', _currency(transfers)],
              ['Monthly Available Balance', _currency(monthlyAvailableBalance)],
            ],
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
            cellStyle: pw.TextStyle(font: regularFont),
            headerDecoration: const pw.BoxDecoration(color: _finzoPrimaryLight),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Transactions',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Date',
              'Title',
              'Type',
              'Account',
              'Category',
              'Amount',
            ],
            data: monthTransactions
                .map(
                  (tx) => [
                    _dateFormat.format(tx.date),
                    tx.title,
                    tx.type.name,
                    tx.accountType.name,
                    tx.category ?? '',
                    _currency(tx.amount),
                  ],
                )
                .toList(),
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
            cellStyle: pw.TextStyle(font: regularFont),
            headerDecoration: const pw.BoxDecoration(color: _finzoPrimaryLight),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Transfer Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 8),
          if (transferTransactions.isEmpty)
            pw.Text(
              'No transfer transactions in this month.',
              style: pw.TextStyle(font: regularFont),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'From', 'To', 'Amount', 'Note'],
              data: transferTransactions
                  .map(
                    (tx) => [
                      _dateFormat.format(tx.date),
                      tx.fromAccount ?? tx.accountType.name,
                      tx.toAccount ?? '-',
                      _currency(tx.amount),
                      tx.note ?? '',
                    ],
                  )
                  .toList(),
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                font: boldFont,
              ),
              cellStyle: pw.TextStyle(font: regularFont),
              headerDecoration: const pw.BoxDecoration(
                color: _finzoPrimaryLight,
              ),
            ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _finzoPrimary, width: 1.2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Final Monthly Available Balance',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _currency(monthlyAvailableBalance),
                  style: pw.TextStyle(
                    font: boldFont,
                    fontWeight: pw.FontWeight.bold,
                    color: monthlyAvailableBalance >= 0
                        ? PdfColors.green700
                        : PdfColors.red700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final fileName = _buildFileName(
      selectedMonth: selectedMonth,
      extension: 'pdf',
    );
    final saved = await _saveExportBytes(
      fileName: fileName,
      bytes: await doc.save(),
      mimeType: 'application/pdf',
    );
    debugPrint('Export saved (PDF): ${saved.pathOrUri}');
    await _tryShowDownloadNotification(
      fileName: saved.fileName,
      filePath: saved.pathOrUri,
    );
    return saved.pathOrUri;
  }

  static Future<Directory> _resolveExportDirectory() async {
    if (Platform.isAndroid) {
      final androidDownloads = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      if (androidDownloads != null && androidDownloads.isNotEmpty) {
        final dir = androidDownloads.first;
        await dir.create(recursive: true);
        debugPrint('Using export directory: ${dir.path}');
        return dir;
      }
    }

    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      await downloads.create(recursive: true);
      debugPrint('Using export directory: ${downloads.path}');
      return downloads;
    }

    final appDocs = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${appDocs.path}/exports');
    await exportsDir.create(recursive: true);
    debugPrint('Using export directory: ${exportsDir.path}');
    return exportsDir;
  }

  static String _currency(double value) =>
      'Rs. ${_currencyFormat.format(value)}';

  static double _sumByType(
    List<Transaction> monthTransactions,
    TransactionType type,
  ) {
    return monthTransactions
        .where((tx) => tx.type == type)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
  }

  static Future<pw.MemoryImage?> _loadFinzoLogo() async {
    try {
      final data = await rootBundle.load('assets/icon/appicon.jpg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _buildFileName({
    required DateTime selectedMonth,
    required String extension,
  }) {
    final month = _monthNameFormat.format(selectedMonth).toLowerCase();
    return '$month-analysis-finzo.$extension';
  }

  static Future<File> _resolveUniqueExportFile(
    String directoryPath,
    String baseFileName,
  ) async {
    var candidate = File('$directoryPath/$baseFileName');
    if (!await candidate.exists()) {
      return candidate;
    }

    var index = 1;
    while (true) {
      final nextName = '$baseFileName($index)';
      candidate = File('$directoryPath/$nextName');
      if (!await candidate.exists()) {
        return candidate;
      }
      index++;
    }
  }

  static Future<_SavedExportRef> _saveExportBytes({
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) async {
    if (Platform.isAndroid) {
      try {
        final response = await _downloadsChannel
            .invokeMapMethod<String, dynamic>('saveBytesToDownloads', {
              'fileName': fileName,
              'bytes': Uint8List.fromList(bytes),
              'mimeType': mimeType,
            });
        final savedName = response?['displayName'] as String?;
        final savedUri = response?['uri'] as String?;
        if (savedName != null && (savedUri?.isNotEmpty ?? false)) {
          return _SavedExportRef(fileName: savedName, pathOrUri: savedUri!);
        }
      } on MissingPluginException catch (error) {
        debugPrint(
          'Downloads channel not available (restart app required). Falling back to file path save: $error',
        );
      } on PlatformException catch (error) {
        debugPrint(
          'Downloads channel failed. Falling back to file path save: ${error.code} ${error.message}',
        );
      }
    }

    final directory = await _resolveExportDirectory();
    final file = await _resolveUniqueExportFile(directory.path, fileName);
    await file.writeAsBytes(bytes, flush: true);
    return _SavedExportRef(
      fileName: file.path.split(Platform.pathSeparator).last,
      pathOrUri: file.path,
    );
  }

  static Future<void> _showDownloadNotification({
    required String fileName,
    required String filePath,
  }) async {
    await _ensureNotificationsInitialized();

    final androidDetails = AndroidNotificationDetails(
      'finzo_downloads',
      'Finzo Downloads',
      channelDescription: 'Notifications for exported files',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      ticker: 'Download complete',
      styleInformation: BigTextStyleInformation(
        'Saved to: $filePath',
        contentTitle: '$fileName downloaded',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Download complete',
      fileName,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: filePath,
    );
  }

  static Future<void> _tryShowDownloadNotification({
    required String fileName,
    required String filePath,
  }) async {
    try {
      await _showDownloadNotification(fileName: fileName, filePath: filePath);
    } catch (error) {
      // Notification failures should not fail the export itself.
      debugPrint('Download notification skipped: $error');
    }
  }

  static Future<void> _ensureNotificationsInitialized() async {
    if (_notificationsInitialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        final path = response.payload;
        if (path == null || path.isEmpty) return;
        debugPrint('Opening file: $path');
        final isContentUri = path.startsWith('content://');
        final file = File(path);
        if (isContentUri || await file.exists()) {
          try {
            if (isContentUri) {
              await _fileOpenChannel.invokeMethod('openFile', {'uri': path});
            } else {
              await _fileOpenChannel.invokeMethod('openFile', {'path': path});
            }
          } catch (error) {
            debugPrint('Failed to open exported file: $error');
          }
        }
      },
    );
    _notificationsInitialized = true;
  }
}

class _SavedExportRef {
  final String fileName;
  final String pathOrUri;

  _SavedExportRef({required this.fileName, required this.pathOrUri});
}
