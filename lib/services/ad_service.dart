import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'storage_service.dart';

class AdService {
  AdService._();

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

  // Android Production IDs are configured above.
  static const String _iosBannerProdId = _iosBannerTestId;
  static const String _iosInterstitialProdId = _iosInterstitialTestId;
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

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) return _androidInterstitialProdId;
    if (Platform.isIOS) return _iosInterstitialProdId;
    throw UnsupportedError('Unsupported platform for Interstitial Ads');
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

  static Future<void> executeWithRewardedAd(BuildContext context, Future<void> Function() onRewarded) async {
    if (StorageService.isAdFreePeriodActive()) {
      await onRewarded();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final rewardedAd = await loadRewardedAd();
    
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    if (rewardedAd == null) {
      debugPrint('[AdService] Failed to load RewardedAd. It returned null.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load ad. Please try again later.')),
        );
      }
      return;
    }

    rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, e) => ad.dispose(),
    );

    rewardedAd.show(
      onUserEarnedReward: (ad, reward) async {
        await onRewarded();
      },
    );
  }

  static Future<InterstitialAd?> loadInterstitialAd() async {
    final completer = Completer<InterstitialAd?>();

    debugPrint('[AdService] Loading InterstitialAd with ID: $interstitialAdUnitId');
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] InterstitialAd loaded successfully.');
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] InterstitialAd failed to load: $error');
          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }

  static Future<void> executeWithInterstitialAd(BuildContext context, Future<void> Function() onAction) async {
    if (StorageService.isAdFreePeriodActive()) {
      await onAction();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final interstitialAd = await loadInterstitialAd();
    
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    if (interstitialAd == null) {
      debugPrint('[AdService] Failed to load InterstitialAd. It returned null.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load ad. Please try again later.')),
        );
      }
      return;
    }

    interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) async {
        ad.dispose();
        await onAction();
      },
      onAdFailedToShowFullScreenContent: (ad, e) async {
        ad.dispose();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to display ad. Please try again.')),
          );
        }
      },
    );

    interstitialAd.show();
  }
}
