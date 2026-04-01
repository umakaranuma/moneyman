import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/account.dart';
import '../services/storage_service.dart';
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
  CurrencyType _defaultCurrency = CurrencyType.lkr;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadDefaultCurrency();
  }

  void _loadDefaultCurrency() {
    final code = StorageService.getDefaultCurrencyCode();
    if (code != null) {
      final type = CurrencyType.values.firstWhere(
        (e) => e.name == code,
        orElse: () => CurrencyType.lkr,
      );
      if (mounted) setState(() => _defaultCurrency = type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
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
                      title: 'Language',
                      subtitle: _language,
                      onTap: () => _showLanguageDialog(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Default currency',
                      subtitle: _defaultCurrency.displayLabel,
                      onTap: () => _showCurrencyDialog(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
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
                          title: 'App Version',
                          subtitle: version,
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Terms of Service',
                      onTap: () => context.goToTermsOfService(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Privacy Policy',
                      onTap: () => context.goToPrivacyPolicy(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Rate Us',
                      subtitle: 'Love the app? Rate us 5 stars!',
                      onTap: () => AppUtils.rateApp(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Share App',
                      subtitle: 'Share with friends and family',
                      onTap: () => AppUtils.shareApp(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
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
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
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
                size: 18,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 0,
    );
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              ...['English', 'Spanish', 'French', 'German'].map(
                (lang) => ListTile(
                  title: Text(
                    lang,
                    style: GoogleFonts.inter(
                      fontWeight:
                          _language == lang ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: _language == lang
                      ? Icon(Icons.check_rounded, color: AppColors.textSecondary, size: 20)
                      : null,
                  onTap: () {
                    if (!mounted) return;
                    setState(() => _language = lang);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencyDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: CurrencyType.values.map(
                    (currency) => ListTile(
                      title: Text(
                        currency.displayLabel,
                        style: GoogleFonts.inter(
                          fontWeight: _defaultCurrency == currency
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: _defaultCurrency == currency
                          ? Icon(Icons.check_rounded, color: AppColors.textSecondary, size: 20)
                          : null,
                      onTap: () async {
                        await StorageService.setDefaultCurrencyCode(currency.name);
                        if (!context.mounted) return;
                        setState(() => _defaultCurrency = currency);
                        Navigator.of(context).pop();
                      },
                    ),
                  ).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
