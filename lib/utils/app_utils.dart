import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUtils {
  // Replace with your actual app name for sharing
  static const String _appName = 'Finzo - Money Manager';

  /// Opens the app's Play Store page for rating
  static Future<void> rateApp() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;
      
      // Try to open Play Store app first
      final playStoreUrl = 'market://details?id=$packageName';
      final playStoreWebUrl = 'https://play.google.com/store/apps/details?id=$packageName';
      
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
    } catch (e) {
      // Handle error silently or show a message
      print('Error opening Play Store: $e');
    }
  }

  /// Shares the app with others
  static Future<void> shareApp() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;
      
      final shareText = 'Check out $_appName on the Play Store!\n\n'
          'https://play.google.com/store/apps/details?id=$packageName';
      
      await Share.share(shareText, subject: _appName);
    } catch (e) {
      // Handle error silently or show a message
      print('Error sharing app: $e');
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

