import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'mobile_ads_config.dart';
import 'storage_service.dart';

class FullscreenAdsService {
  FullscreenAdsService._();
  static final FullscreenAdsService instance = FullscreenAdsService._();
  static final ValueNotifier<int> adExperienceVersion = ValueNotifier(0);

  static void bumpAdExperience() => adExperienceVersion.value++;

  InterstitialAd? _interstitial;
  bool _interstitialLoading = false;
  DateTime? _lastInterstitialShownAt;
  final Random _random = Random();

  static const _minInterstitialGap = Duration(minutes: 4);
  static const _interstitialShowProbability = 0.38;

  void preloadInterstitial() {
    if (kIsWeb || !MobileAdsConfig.showInterstitialAds) return;
    if (StorageService.isAdFreePeriodActive()) return;
    if (_interstitial != null || _interstitialLoading) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: MobileAdsConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (_) => _interstitialLoading = false,
      ),
    );
  }

  void _finishInterstitial(InterstitialAd ad) {
    ad.dispose();
    _interstitial = null;
    preloadInterstitial();
  }

  void scheduleInterstitialAfterAction() {
    if (kIsWeb || !MobileAdsConfig.showInterstitialAds) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 550), () {
        if (StorageService.isAdFreePeriodActive()) return;
        if (_random.nextDouble() > _interstitialShowProbability) {
          preloadInterstitial();
          return;
        }
        final last = _lastInterstitialShownAt;
        if (last != null &&
            DateTime.now().difference(last) < _minInterstitialGap) {
          preloadInterstitial();
          return;
        }

        final ad = _interstitial;
        if (ad == null) {
          preloadInterstitial();
          return;
        }
        _interstitial = null;
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (a) {
            _lastInterstitialShownAt = DateTime.now();
            _finishInterstitial(a);
          },
          onAdFailedToShowFullScreenContent: (a, e) {
            debugPrint('Interstitial failed to show: $e');
            _finishInterstitial(a);
          },
        );
        ad.show();
      });
    });
  }

  Future<void> presentRewardedForAdFree(BuildContext context) async {
    if (kIsWeb || !MobileAdsConfig.showRewardedAds) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final completer = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: MobileAdsConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: completer.complete,
        onAdFailedToLoad: (_) => completer.complete(null),
      ),
    );
    final ad = await completer.future;
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    } else {
      ad?.dispose();
      return;
    }
    if (ad == null) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Could not load the video. Try again later.')),
      );
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        bumpAdExperience();
      },
      onAdFailedToShowFullScreenContent: (a, _) => a.dispose(),
    );

    ad.setImmersiveMode(true);
    ad.show(
      onUserEarnedReward: (adView, reward) async {
        await StorageService.extendAdFreePeriod(
          MobileAdsConfig.adFreeRewardDuration,
        );
        bumpAdExperience();
        messenger?.showSnackBar(
          const SnackBar(content: Text('Thanks! Ads are off for 24 hours.')),
        );
      },
    );
  }
}
