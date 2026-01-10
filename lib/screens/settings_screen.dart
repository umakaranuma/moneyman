import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../core/router/app_router.dart';
import '../utils/app_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  // bool _autoBackupEnabled = false; // Commented out as Auto Backup is not implemented yet
  String _currency = 'USD';
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // General Settings
                _buildSectionHeader('General'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildSettingTile(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: _language,
                      onTap: () => _showLanguageDialog(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.attach_money_rounded,
                      title: 'Currency',
                      subtitle: _currency,
                      onTap: () => _showCurrencyDialog(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.palette_rounded,
                      title: 'Theme',
                      subtitle: _darkModeEnabled ? 'Dark' : 'Light',
                      trailing: Switch(
                        value: _darkModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _darkModeEnabled = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Notifications
                _buildSectionHeader('Notifications'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildSettingTile(
                      icon: Icons.notifications_rounded,
                      title: 'Enable Notifications',
                      subtitle: 'Get alerts for important updates',
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Data & Storage - Commented out as Auto Backup is not implemented yet
                // _buildSectionHeader('Data & Storage'),
                // const SizedBox(height: 12),
                // _buildSettingsCard(
                //   children: [
                //     _buildSettingTile(
                //       icon: Icons.backup_rounded,
                //       title: 'Auto Backup',
                //       subtitle: 'Automatically backup your data',
                //       trailing: Switch(
                //         value: _autoBackupEnabled,
                //         onChanged: (value) {
                //           setState(() {
                //             _autoBackupEnabled = value;
                //           });
                //         },
                //       ),
                //     ),
                //   ],
                // ),

                // const SizedBox(height: 24),

                // About
                _buildSectionHeader('About'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final version = snapshot.hasData
                            ? 'v${snapshot.data!.version}'
                            : 'v1.0.0';
                        return _buildSettingTile(
                          icon: Icons.info_rounded,
                          title: 'App Version',
                          subtitle: version,
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.description_rounded,
                      title: 'Terms of Service',
                      onTap: () => context.goToTermsOfService(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.privacy_tip_rounded,
                      title: 'Privacy Policy',
                      onTap: () => context.goToPrivacyPolicy(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.star_rounded,
                      title: 'Rate Us',
                      subtitle: 'Love the app? Rate us 5 stars!',
                      onTap: () => AppUtils.rateApp(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.share_rounded,
                      title: 'Share App',
                      subtitle: 'Share with friends and family',
                      onTap: () => AppUtils.shareApp(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.chat_bubble_rounded,
                      title: 'Feedback',
                      subtitle: 'Help us improve the app',
                      onTap: () => context.goToFeedback(),
                    ),
                  ],
                ),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null && onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.surfaceVariant,
      indent: 60,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Select Language',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Spanish', 'French', 'German']
              .map(
                (lang) => RadioListTile<String>(
                  title: Text(
                    lang,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                  ),
                  value: lang,
                  groupValue: _language,
                  onChanged: (value) {
                    setState(() {
                      _language = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Select Currency',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['USD', 'EUR', 'GBP', 'INR', 'JPY']
              .map(
                (curr) => RadioListTile<String>(
                  title: Text(
                    curr,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                  ),
                  value: curr,
                  groupValue: _currency,
                  onChanged: (value) {
                    setState(() {
                      _currency = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
