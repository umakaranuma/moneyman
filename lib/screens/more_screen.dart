import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../core/router/app_router.dart';
import '../utils/app_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Fixed Header
              SliverPersistentHeader(
                pinned: true,
                delegate: _FixedHeaderDelegate(
                  child: _buildHeader(),
                  height: 96,
                ),
              ),

              // Pro Banner - Commented out as Pro features are not implemented yet
              // SliverToBoxAdapter(child: _buildProBanner(context)),

              // Settings Grid
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildSettingsItem(
                      context,
                      icon: Icons.tune_rounded,
                      label: 'Configuration',
                      onTap: () => context.goToConfiguration(),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.checklist_rounded,
                      label: 'Todos',
                      onTap: () => context.goToTodos(),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.notifications_active_rounded,
                      label: 'Reminders',
                      onTap: () => context.goToReminders(),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.note_alt_rounded,
                      label: 'Notes',
                      onTap: () => context.goToNotes(),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.sms_rounded,
                      label: 'SMS Import',
                      onTap: () => context.goToSmsTransactions(),
                    ),
                    // _buildSettingsItem(
                    //   context,
                    //   icon: Icons.settings_rounded,
                    //   label: 'Settings',
                    //   onTap: () => context.goToSettings(),
                    // ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.category_rounded,
                      label: 'Categories',
                      onTap: () => context.goToCategories(),
                    ),
                    // Security - Commented out as not implemented yet
                    // _buildSettingsItem(
                    //   context,
                    //   icon: Icons.lock_rounded,
                    //   label: 'Security',
                    //   onTap: () => context.goToSecurity(),
                    // ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.calculate_rounded,
                      label: 'Calculator',
                      onTap: () => context.goToCalculator(),
                    ),
                    // Sync - Commented out as not implemented yet
                    // _buildSettingsItem(
                    //   context,
                    //   icon: Icons.devices_rounded,
                    //   label: 'Sync',
                    //   onTap: () => context.goToSync(),
                    // ),
                    // Backup - Commented out as not implemented yet
                    // _buildSettingsItem(
                    //   context,
                    //   icon: Icons.cloud_upload_rounded,
                    //   label: 'Backup',
                    //   onTap: () => context.goToBackup(),
                    // ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.chat_bubble_rounded,
                      label: 'Feedback',
                      onTap: () => context.goToFeedback(),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.help_rounded,
                      label: 'Help',
                      onTap: () => context.goToHelp(),
                    ),
                  ]),
                ),
              ),

              // About Section
              SliverToBoxAdapter(child: _buildAboutSection(context)),

              // Bottom spacing to account for bottom navigation bar
              // Nav bar: 72px height + 16px margin = 88px, plus safe area
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 16 + MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "More",
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData
                  ? "Version ${snapshot.data!.version}"
                  : "Version 1.0.0";
              return Text(
                version,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Pro Banner - Commented out as Pro features are not implemented yet
  /*
  Widget _buildProBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B69), Color(0xFF1A1040)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => context.goToUpgrade(),
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.secondary,
                                      ],
                                    ).createShader(bounds),
                                child: Text(
                                  'PRO',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Upgrade Now',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Unlock all features & remove ads',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.secondary,
                                  AppColors.primary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'GET PRO',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  */

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 14),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            _buildAboutRow(
              title: "Rate Finzo",
              onTap: () => AppUtils.rateApp(),
            ),
            _divider(),
            _buildAboutRow(
              title: "Share App",
              onTap: () => AppUtils.shareApp(),
            ),
            _divider(),
            _buildAboutRow(
              title: "Privacy Policy",
              onTap: () => context.goToPrivacyPolicy(),
            ),
            _divider(),
            _buildAboutRow(
              title: "Terms of Service",
              onTap: () => context.goToTermsOfService(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutRow({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 16);
  }
}

class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _FixedHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.background, child: child);
  }

  @override
  bool shouldRebuild(_FixedHeaderDelegate oldDelegate) {
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}
