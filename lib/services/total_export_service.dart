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
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _mediaChannel = MethodChannel('finzo/media_scan');
  static const MethodChannel _fileOpenChannel = MethodChannel('finzo/file_open');
  static bool _notificationsInitialized = false;

  static Future<String> exportExcel({
    required DateTime selectedMonth,
    required int comparisonPercent,
    required double cashExpenses,
    required double cardExpenses,
    required double transfers,
    required List<Transaction> monthTransactions,
  }) async {
    final excel = Excel.createExcel();
    final summarySheet = excel['Summary'];
    final transactionsSheet = excel['Transactions'];

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

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to generate Excel file.');
    }

    final directory = await _resolveExportDirectory();
    final fileName = _buildFileName(selectedMonth: selectedMonth, extension: 'xlsx');
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await _scanFileOnAndroid(file.path);
    debugPrint('Export saved (Excel): ${file.path}');
    await _showDownloadNotification(fileName: fileName, filePath: file.path);
    return file.path;
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
    final doc = pw.Document();
    final monthTitle = DateFormat('MMMM yyyy').format(selectedMonth);

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(24),
          pageFormat: PdfPageFormat.a4,
        ),
        build: (context) => [
          pw.Text(
            'Money Man - Total Export',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Month: $monthTitle', style: pw.TextStyle(font: regularFont)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Metric', 'Value'],
            data: [
              ['Compared Expenses (Last month)', '$comparisonPercent%'],
              ['Expenses (Cash, Accounts)', _currency(cashExpenses)],
              ['Expenses (Card)', _currency(cardExpenses)],
              ['Transfers', _currency(transfers)],
            ],
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldFont),
            cellStyle: pw.TextStyle(font: regularFont),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
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
            headers: const ['Date', 'Title', 'Type', 'Account', 'Category', 'Amount'],
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
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldFont),
            cellStyle: pw.TextStyle(font: regularFont),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    final directory = await _resolveExportDirectory();
    final fileName = _buildFileName(selectedMonth: selectedMonth, extension: 'pdf');
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await doc.save(), flush: true);
    await _scanFileOnAndroid(file.path);
    debugPrint('Export saved (PDF): ${file.path}');
    await _showDownloadNotification(fileName: fileName, filePath: file.path);
    return file.path;
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

  static String _currency(double value) => 'Rs. ${_currencyFormat.format(value)}';

  static String _buildFileName({
    required DateTime selectedMonth,
    required String extension,
  }) {
    final month = _monthNameFormat.format(selectedMonth).toLowerCase();
    return '$month-analysis-finzo.$extension';
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

  static Future<void> _ensureNotificationsInitialized() async {
    if (_notificationsInitialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        final path = response.payload;
        if (path == null || path.isEmpty) return;
        debugPrint('Opening file: $path');
        final file = File(path);
        if (await file.exists()) {
          try {
            await _fileOpenChannel.invokeMethod('openFile', {'path': path});
          } catch (error) {
            debugPrint('Failed to open exported file: $error');
          }
        }
      },
    );
    _notificationsInitialized = true;
  }

  static Future<void> _scanFileOnAndroid(String path) async {
    if (!Platform.isAndroid) return;
    try {
      await _mediaChannel.invokeMethod('scanFile', {'path': path});
    } catch (_) {
      // Ignore scan failures; file is still written and usable.
    }
  }
}
