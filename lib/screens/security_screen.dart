import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  bool _autoLockEnabled = true;
  int _autoLockMinutes = 5;

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
          'Security',
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
                // Security Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.2),
                        AppColors.primary.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Protect Your Data',
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Secure your financial information',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Authentication Methods
                _buildSectionHeader('Authentication'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildSettingTile(
                      icon: Icons.fingerprint_rounded,
                      title: 'Biometric Lock',
                      subtitle: 'Use fingerprint or face ID',
                      trailing: Switch(
                        value: _biometricEnabled,
                        onChanged: (value) {
                          setState(() {
                            _biometricEnabled = value;
                          });
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.pin_rounded,
                      title: 'PIN Lock',
                      subtitle: 'Set a 4-digit PIN',
                      trailing: Switch(
                        value: _pinEnabled,
                        onChanged: (value) {
                          setState(() {
                            _pinEnabled = value;
                            if (value) {
                              _showPinSetupDialog();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Auto Lock
                _buildSectionHeader('Auto Lock'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildSettingTile(
                      icon: Icons.timer_rounded,
                      title: 'Auto Lock',
                      subtitle: 'Lock app after inactivity',
                      trailing: Switch(
                        value: _autoLockEnabled,
                        onChanged: (value) {
                          setState(() {
                            _autoLockEnabled = value;
                          });
                        },
                      ),
                    ),
                    if (_autoLockEnabled) ...[
                      _buildDivider(),
                      _buildSettingTile(
                        icon: Icons.access_time_rounded,
                        title: 'Lock Timeout',
                        subtitle: '$_autoLockMinutes minutes',
                        onTap: () => _showAutoLockDialog(),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                // Privacy
                _buildSectionHeader('Privacy'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildSettingTile(
                      icon: Icons.visibility_off_rounded,
                      title: 'Hide Balance',
                      subtitle: 'Hide balance on home screen',
                      trailing: Switch(
                        value: false,
                        onChanged: (value) {},
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.screen_lock_portrait_rounded,
                      title: 'Block Screenshots',
                      subtitle: 'Prevent screenshots in app',
                      trailing: Switch(
                        value: false,
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Data Protection
                _buildSectionHeader('Data Protection'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildSettingTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Encrypt Data',
                      subtitle: 'All data is encrypted locally',
                      trailing: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 24,
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.delete_forever_rounded,
                      title: 'Clear All Data',
                      subtitle: 'Permanently delete all data',
                      onTap: () => _showClearDataDialog(),
                      titleColor: AppColors.error,
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
        border: Border.all(
          color: AppColors.surfaceVariant,
          width: 1,
        ),
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
    Color? titleColor,
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
                  colors: titleColor == AppColors.error
                      ? [AppColors.error, AppColors.error.withValues(alpha: 0.7)]
                      : [AppColors.secondary, AppColors.primary],
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
                      color: titleColor ?? AppColors.textPrimary,
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

  void _showPinSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Set PIN',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Text(
          'Enter a 4-digit PIN to secure your app',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'PIN set successfully',
                    style: GoogleFonts.inter(),
                  ),
                ),
              );
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }

  void _showAutoLockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Auto Lock Timeout',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 5, 10, 15, 30]
              .map((minutes) => RadioListTile<int>(
                    title: Text(
                      '$minutes ${minutes == 1 ? 'minute' : 'minutes'}',
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                    ),
                    value: minutes,
                    groupValue: _autoLockMinutes,
                    onChanged: (value) {
                      setState(() {
                        _autoLockMinutes = value!;
                      });
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Clear All Data',
          style: GoogleFonts.inter(color: AppColors.error),
        ),
        content: Text(
          'This will permanently delete all your transactions, categories, and settings. This action cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'All data cleared',
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }
}

