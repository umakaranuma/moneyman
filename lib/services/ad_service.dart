import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static const String _androidBannerTestId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _androidRewardedTestId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosBannerTestId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _iosRewardedTestId =
      'ca-app-pub-3940256099942544/1712485313';

  // Replace these with your real Ad Unit IDs before Play Store release.
  static const String _androidBannerProdId = _androidBannerTestId;
  static const String _androidRewardedProdId = _androidRewardedTestId;
  static const String _iosBannerProdId = _iosBannerTestId;
  static const String _iosRewardedProdId = _iosRewardedTestId;

  static Future<InitializationStatus> init() {
    return MobileAds.instance.initialize();
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
    RewardedAd? rewardedAd;

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => rewardedAd = ad,
        onAdFailedToLoad: (_) => rewardedAd = null,
      ),
    );

    return rewardedAd;
  }
}
