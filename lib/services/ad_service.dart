import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static const String _androidBannerProdId =
      'ca-app-pub-8425136910231843/9421211590';
  static const String _androidRewardedProdId =
      'ca-app-pub-8425136910231843/6795048256';
  static const String _iosBannerTestId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _iosRewardedTestId =
      'ca-app-pub-3940256099942544/1712485313';

  // Android Production IDs are configured above.
  static const String _iosBannerProdId = _iosBannerTestId;
  static const String _iosRewardedProdId = _iosRewardedTestId;

  static Future<InitializationStatus> init() async {
    final status = await MobileAds.instance.initialize();
    
    // Configure this specific device as a test device using its hashed ID
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: ['AB13D7D0BF33D444802701C880D74ECD'],
      ),
    );
    
    return status;
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return _androidBannerProdId;
    if (Platform.isIOS) return _iosBannerProdId;
    throw UnsupportedError('Unsupported platform for Banner Ads');
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) return _androidRewardedProdId;
    if (Platform.isIOS) return _iosRewardedProdId;
    throw UnsupportedError('Unsupported platform for Rewarded Ads');
  }

  static Future<RewardedAd?> loadRewardedAd() async {
    final completer = Completer<RewardedAd?>();

    debugPrint('[AdService] Loading RewardedAd with ID: $rewardedAdUnitId');
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] RewardedAd loaded successfully.');
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] RewardedAd failed to load: $error');
          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }
}
