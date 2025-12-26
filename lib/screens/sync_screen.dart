import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _autoSyncEnabled = false;
  bool _syncOnWifiOnly = true;
  String _lastSyncTime = 'Never';

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
          'Sync',
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
                // Sync Status Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFE879F9).withValues(alpha: 0.2),
                        const Color(0xFFD946EF).withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE879F9).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE879F9), Color(0xFFD946EF)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_sync_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cloud Sync',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep your data synchronized across all devices',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: AppColors.textMuted,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Last sync: $_lastSyncTime',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
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

                // Sync Options
                _buildSectionHeader('Sync Options'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildSettingTile(
                      icon: Icons.sync_rounded,
                      title: 'Auto Sync',
                      subtitle: 'Automatically sync your data',
                      trailing: Switch(
                        value: _autoSyncEnabled,
                        onChanged: (value) {
                          setState(() {
                            _autoSyncEnabled = value;
                          });
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.wifi_rounded,
                      title: 'Wi-Fi Only',
                      subtitle: 'Sync only when connected to Wi-Fi',
                      trailing: Switch(
                        value: _syncOnWifiOnly,
                        onChanged: (value) {
                          setState(() {
                            _syncOnWifiOnly = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Sync Services
                _buildSectionHeader('Sync Services'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildServiceTile(
                      icon: Icons.cloud_rounded,
                      title: 'Google Drive',
                      subtitle: 'Sync with Google Drive',
                      onTap: () => _showConnectDialog('Google Drive'),
                    ),
                    _buildDivider(),
                    _buildServiceTile(
                      icon: Icons.cloud_done_rounded,
                      title: 'iCloud',
                      subtitle: 'Sync with iCloud',
                      onTap: () => _showConnectDialog('iCloud'),
                    ),
                    _buildDivider(),
                    _buildServiceTile(
                      icon: Icons.storage_rounded,
                      title: 'Dropbox',
                      subtitle: 'Sync with Dropbox',
                      onTap: () => _showConnectDialog('Dropbox'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Actions
                _buildSectionHeader('Actions'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildActionTile(
                      icon: Icons.upload_rounded,
                      title: 'Upload to Cloud',
                      subtitle: 'Upload your data now',
                      onTap: () => _performSync('upload'),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.download_rounded,
                      title: 'Download from Cloud',
                      subtitle: 'Download latest data',
                      onTap: () => _performSync('download'),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.sync_alt_rounded,
                      title: 'Sync Now',
                      subtitle: 'Sync both ways',
                      onTap: () => _performSync('sync'),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFE879F9), Color(0xFFD946EF)],
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

  Widget _buildServiceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _buildSettingTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _buildSettingTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
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

  void _showConnectDialog(String service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Connect $service',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Text(
          'Connect your $service account to enable cloud sync.',
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
                    'Connected to $service',
                    style: GoogleFonts.inter(),
                  ),
                ),
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _performSync(String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              type == 'upload'
                  ? 'Uploading...'
                  : type == 'download'
                      ? 'Downloading...'
                      : 'Syncing...',
              style: GoogleFonts.inter(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      setState(() {
        _lastSyncTime = 'Just now';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == 'upload'
                ? 'Upload completed'
                : type == 'download'
                    ? 'Download completed'
                    : 'Sync completed',
            style: GoogleFonts.inter(),
          ),
        ),
      );
    });
  }
}

