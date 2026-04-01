import 'dart:io';

class MobileAdsConfig {
  MobileAdsConfig._();

  static const Duration adFreeRewardDuration = Duration(hours: 24);

  static const String _androidBannerProdId =
      'ca-app-pub-8425136910231843/9421211590';
  static const String _androidInterstitialProdId =
      'ca-app-pub-8425136910231843/6543037867';
  static const String _androidRewardedProdId =
      'ca-app-pub-8425136910231843/6795048256';

  static const String _iosBannerTestId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _iosInterstitialTestId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _iosRewardedTestId =
      'ca-app-pub-3940256099942544/1712485313';

  static bool get showAnchoredBanner => true;
  static bool get showInterstitialAds => true;
  static bool get showRewardedAds => true;

  static String get anchoredBannerAdUnitId =>
      Platform.isAndroid ? _androidBannerProdId : _iosBannerTestId;
  static String get interstitialAdUnitId =>
      Platform.isAndroid ? _androidInterstitialProdId : _iosInterstitialTestId;
  static String get rewardedAdUnitId =>
      Platform.isAndroid ? _androidRewardedProdId : _iosRewardedTestId;
}
