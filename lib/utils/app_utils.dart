import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUtils {
  // Replace with your actual app name for sharing
  static const String _appName = 'Finzo - Money Manager';

  /// Opens the app's Play Store/App Store page for rating
  static Future<void> rateApp() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      if (Platform.isAndroid) {
        // Try to open Play Store app first
        final playStoreUrl = 'market://details?id=$packageName';
        final playStoreWebUrl =
            'https://play.google.com/store/apps/details?id=$packageName';

        final uri = Uri.parse(playStoreUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback to web browser
          final webUri = Uri.parse(playStoreWebUrl);
          if (await canLaunchUrl(webUri)) {
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
          }
        }
      } else if (Platform.isIOS) {
        // iOS App Store
        final appStoreUrl = 'https://apps.apple.com/app/id$packageName';
        final uri = Uri.parse(appStoreUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      // Handle error silently or show a message
      print('Error opening app store: $e');
    }
  }

  /// Shares the app with others
  static Future<void> shareApp() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      String appStoreUrl;
      String storeName;

      if (Platform.isAndroid) {
        appStoreUrl =
            'https://play.google.com/store/apps/details?id=$packageName';
        storeName = 'Play Store';
      } else if (Platform.isIOS) {
        appStoreUrl = 'https://apps.apple.com/app/id$packageName';
        storeName = 'App Store';
      } else {
        // Fallback for other platforms
        appStoreUrl =
            'https://play.google.com/store/apps/details?id=$packageName';
        storeName = 'app store';
      }

      final shareText =
          'Check out $_appName! 🚀\n\n'
          'A powerful money manager app to track your expenses and income.\n\n'
          'Download it from the $storeName:\n$appStoreUrl';

      await Share.share(shareText, subject: _appName);
    } catch (e) {
      // Handle error silently or show a message
      print('Error sharing app: $e');
      rethrow; // Re-throw to allow caller to handle if needed
    }
  }

  /// Opens a URL in the browser
  static Future<void> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening URL: $e');
    }
  }
}
