import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/fullscreen_ads_service.dart';
import '../services/mobile_ads_config.dart';
import '../services/storage_service.dart';

class AdaptiveBannerAdSlot extends StatefulWidget {
  const AdaptiveBannerAdSlot({super.key});

  @override
  State<AdaptiveBannerAdSlot> createState() => _AdaptiveBannerAdSlotState();
}

class _AdaptiveBannerAdSlotState extends State<AdaptiveBannerAdSlot> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  Orientation? _orientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orientation ??= MediaQuery.orientationOf(context);
    if (_shouldShowBanner && _bannerAd == null) {
      _loadAd();
    }
  }

  bool get _shouldShowBanner =>
      MobileAdsConfig.showAnchoredBanner &&
      !StorageService.isAdFreePeriodActive();

  Future<void> _loadAd() async {
    if (!_shouldShowBanner) return;

    _bannerAd?.dispose();
    if (!mounted) return;
    setState(() {
      _bannerAd = null;
      _loaded = false;
    });

    final ad = BannerAd(
      adUnitId: MobileAdsConfig.anchoredBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _bannerAd = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _loaded = false);
        },
      ),
    );

    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: FullscreenAdsService.adExperienceVersion,
      builder: (context, _, child) {
        if (!_shouldShowBanner) {
          final toDispose = _bannerAd;
          if (toDispose != null) {
            _bannerAd = null;
            _loaded = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              toDispose.dispose();
            });
          }
          return const SizedBox.shrink();
        }

        return OrientationBuilder(
          builder: (context, orientation) {
            if (_orientation != orientation) {
              _orientation = orientation;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _shouldShowBanner) _loadAd();
              });
            }

            if (_bannerAd != null && _loaded) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: SizedBox(
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    ),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
