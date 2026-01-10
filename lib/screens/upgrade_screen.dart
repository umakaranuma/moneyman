import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  String _selectedPlan = 'yearly'; // 'monthly' or 'yearly'

  final List<ProFeature> _proFeatures = [
    ProFeature(
      icon: Icons.workspace_premium_rounded,
      title: 'Remove All Ads',
      description: 'Enjoy an ad-free experience',
      gradient: [AppColors.primary, AppColors.primaryLight],
    ),
    ProFeature(
      icon: Icons.cloud_sync_rounded,
      title: 'Cloud Sync',
      description: 'Sync your data across all devices',
      gradient: [const Color(0xFF48DBFB), const Color(0xFF0ABDE3)],
    ),
    ProFeature(
      icon: Icons.backup_rounded,
      title: 'Auto Backup',
      description: 'Automatic daily backups to cloud',
      gradient: [AppColors.secondary, AppColors.secondaryLight],
    ),
    ProFeature(
      icon: Icons.analytics_rounded,
      title: 'Advanced Analytics',
      description: 'Detailed reports and insights',
      gradient: [const Color(0xFFE879F9), const Color(0xFFD946EF)],
    ),
    ProFeature(
      icon: Icons.category_rounded,
      title: 'Unlimited Categories',
      description: 'Create unlimited custom categories',
      gradient: [AppColors.income, AppColors.income.withValues(alpha: 0.7)],
    ),
    ProFeature(
      icon: Icons.receipt_long_rounded,
      title: 'Receipt Scanner',
      description: 'Scan and attach receipts to transactions',
      gradient: [const Color(0xFFF59E0B), const Color(0xFFF97316)],
    ),
    ProFeature(
      icon: Icons.account_tree_rounded,
      title: 'Multiple Accounts',
      description: 'Manage unlimited bank accounts',
      gradient: [AppColors.transfer, AppColors.transfer.withValues(alpha: 0.7)],
    ),
    ProFeature(
      icon: Icons.pie_chart_rounded,
      title: 'Budget Planning',
      description: 'Advanced budget tracking and planning',
      gradient: [const Color(0xFFFECA57), const Color(0xFFFF9F43)],
    ),
    ProFeature(
      icon: Icons.file_download_rounded,
      title: 'Export Reports',
      description: 'Export data to PDF, Excel, CSV',
      gradient: [AppColors.primary, AppColors.secondary],
    ),
    ProFeature(
      icon: Icons.security_rounded,
      title: 'Biometric Lock',
      description: 'Secure your app with fingerprint/Face ID',
      gradient: [AppColors.secondary, AppColors.primary],
    ),
    ProFeature(
      icon: Icons.palette_rounded,
      title: 'Custom Themes',
      description: 'Choose from multiple beautiful themes',
      gradient: [const Color(0xFFE879F9), const Color(0xFFD946EF)],
    ),
    ProFeature(
      icon: Icons.support_agent_rounded,
      title: 'Priority Support',
      description: 'Get priority customer support',
      gradient: [AppColors.primary, AppColors.primaryLight],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              backgroundColor: AppColors.background,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              expandedHeight: 200,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2D1B69),
                        const Color(0xFF1A1040),
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
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
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 150,
                          height: 150,
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
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryLight],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary,
                                ],
                              ).createShader(bounds),
                              child: Text(
                                'UPGRADE TO PRO',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Unlock all premium features',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pricing Plans
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.surfaceVariant,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlan = 'monthly'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: _selectedPlan == 'monthly'
                                  ? const LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryLight],
                                    )
                                  : null,
                              color: _selectedPlan == 'monthly' ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Monthly',
                                  style: GoogleFonts.inter(
                                    color: _selectedPlan == 'monthly'
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$4.99',
                                  style: GoogleFonts.inter(
                                    color: _selectedPlan == 'monthly'
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlan = 'yearly'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: _selectedPlan == 'yearly'
                                  ? const LinearGradient(
                                      colors: [AppColors.secondary, AppColors.primary],
                                    )
                                  : null,
                              color: _selectedPlan == 'yearly' ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Yearly',
                                      style: GoogleFonts.inter(
                                        color: _selectedPlan == 'yearly'
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _selectedPlan == 'yearly'
                                            ? Colors.white.withValues(alpha: 0.3)
                                            : AppColors.primary.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'SAVE 58%',
                                        style: GoogleFonts.inter(
                                          color: _selectedPlan == 'yearly'
                                              ? Colors.white
                                              : AppColors.primary,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$24.99',
                                  style: GoogleFonts.inter(
                                    color: _selectedPlan == 'yearly'
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Features List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final feature = _proFeatures[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildFeatureCard(feature),
                    );
                  },
                  childCount: _proFeatures.length,
                ),
              ),
            ),

            // Upgrade Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement purchase logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Purchase functionality will be implemented soon',
                              style: GoogleFonts.inter(),
                            ),
                            backgroundColor: AppColors.surface,
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          'UPGRADE NOW',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cancel anytime. No commitment.',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '7-day free trial',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(ProFeature feature) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: feature.gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: feature.gradient[0].withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              feature.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class ProFeature {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  ProFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

