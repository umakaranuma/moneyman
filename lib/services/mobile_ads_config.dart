import 'dart:io';

class MobileAdsConfig {
  MobileAdsConfig._();

  static const Duration adFreeRewardDuration = Duration(hours: 24);

  static const String _androidBannerTestId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _androidInterstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _androidRewardedTestId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String _iosBannerTestId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _iosInterstitialTestId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _iosRewardedTestId =
      'ca-app-pub-3940256099942544/1712485313';

  static bool get showAnchoredBanner => true;
  static bool get showInterstitialAds => false;
  static bool get showRewardedAds => true;

  static String get anchoredBannerAdUnitId =>
      Platform.isAndroid ? _androidBannerTestId : _iosBannerTestId;
  static String get interstitialAdUnitId =>
      Platform.isAndroid ? _androidInterstitialTestId : _iosInterstitialTestId;
  static String get rewardedAdUnitId =>
      Platform.isAndroid ? _androidRewardedTestId : _iosRewardedTestId;
}
