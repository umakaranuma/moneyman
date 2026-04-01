import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/ad_service.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/stats/presentation/screens/stats_screen.dart';
import '../services/notification_navigation_handler.dart';
import 'accounts_screen.dart';
import 'more_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  late AnimationController _fabAnimationController;
  late final PageController _pageController;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const AccountsScreen(),
    const MoreScreen(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Transactions',
    ),
    _NavItem(
      icon: Icons.pie_chart_outline_rounded,
      activeIcon: Icons.pie_chart_rounded,
      label: 'Analytics',
    ),
    _NavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Accounts',
    ),
    _NavItem(
      icon: Icons.apps_outlined,
      activeIcon: Icons.apps_rounded,
      label: 'More',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pageController = PageController(initialPage: _currentIndex);
    _loadBannerAd();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyPendingNotificationRoute());
  }

  void _loadBannerAd() {
    final ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _isBannerLoaded = false);
        },
      ),
    );

    ad.load();
    _bannerAd = ad;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _applyPendingNotificationRoute();
    }
  }

  /// When app was opened from a notification tap, navigate to the right screen.
  /// Ensures we're at home first so that back from the target screen returns to home.
  Future<void> _applyPendingNotificationRoute() async {
    if (!mounted) return;
    final router = GoRouter.of(context);
    final route = await NotificationNavigationHandler.takePendingRoute();
    if (route == null || route.isEmpty || !mounted) return;
    // Go to home first so that back from the target screen returns to home.
    router.go('/');
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (route == NotificationNavigationHandler.routeTodos) {
        router.push('/todos');
      } else if (route == NotificationNavigationHandler.routeHome) {
        // Already on home
      } else if (route.startsWith('reminders|')) {
        final parts = route.split('|');
        if (parts.length == 2) {
          final notificationId = int.tryParse(parts[1]);
          if (notificationId != null) {
            router.push('/reminders', extra: {'highlightNotificationId': notificationId});
          } else {
            router.push('/reminders');
          }
        } else {
          router.push('/reminders');
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fabAnimationController.dispose();
    _pageController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          _pageController.jumpToPage(0);
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: ListenableBuilder(
        listenable: ThemeService(),
        builder: (context, _) {
          return Scaffold(
            body: PageView(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable swipe to prevent loading screens
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: _screens,
            ),
            extendBody: true,
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isBannerLoaded && _bannerAd != null)
                  SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                _buildBottomNavBar(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface.withValues(alpha: 0.95),
                    AppColors.surfaceVariant.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _navItems.length,
                  (index) => _buildNavItem(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _currentIndex == index;
    final item = _navItems[index];

    return GestureDetector(
      onTap: () {
        if (_currentIndex == index) {
          return;
        }
        setState(() {
          _currentIndex = index;
        });
        _pageController.jumpToPage(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? AppColors.primary : AppColors.navUnselected,
              size: 24,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        item.label,
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
