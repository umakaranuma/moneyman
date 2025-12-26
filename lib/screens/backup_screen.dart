import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _autoBackupEnabled = false;
  int _backupFrequency = 7; // days
  String _lastBackupTime = 'Never';
  int _backupCount = 0;

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
          'Backup',
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
                // Backup Status Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF48DBFB).withValues(alpha: 0.2),
                        const Color(0xFF0ABDE3).withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF48DBFB).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF48DBFB), Color(0xFF0ABDE3)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Data Backup',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Protect your data with regular backups',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Last Backup',
                            _lastBackupTime,
                            Icons.access_time_rounded,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppColors.surfaceVariant,
                          ),
                          _buildStatItem(
                            'Backups',
                            '$_backupCount',
                            Icons.backup_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Backup Options
                _buildSectionHeader('Backup Options'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildSettingTile(
                      icon: Icons.backup_rounded,
                      title: 'Auto Backup',
                      subtitle: 'Automatically backup your data',
                      trailing: Switch(
                        value: _autoBackupEnabled,
                        onChanged: (value) {
                          setState(() {
                            _autoBackupEnabled = value;
                          });
                        },
                      ),
                    ),
                    if (_autoBackupEnabled) ...[
                      _buildDivider(),
                      _buildSettingTile(
                        icon: Icons.schedule_rounded,
                        title: 'Backup Frequency',
                        subtitle: 'Every $_backupFrequency days',
                        onTap: () => _showFrequencyDialog(),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                // Backup Actions
                _buildSectionHeader('Backup Actions'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildActionTile(
                      icon: Icons.cloud_upload_rounded,
                      title: 'Create Backup Now',
                      subtitle: 'Backup your data to cloud',
                      onTap: () => _createBackup(),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.restore_rounded,
                      title: 'Restore from Backup',
                      subtitle: 'Restore from previous backup',
                      onTap: () => _restoreBackup(),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.folder_rounded,
                      title: 'Manage Backups',
                      subtitle: 'View and delete backups',
                      onTap: () => _manageBackups(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Backup Storage
                _buildSectionHeader('Storage'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildStorageTile(
                      icon: Icons.cloud_rounded,
                      title: 'Cloud Storage',
                      subtitle: '12.5 MB used',
                      progress: 0.25,
                    ),
                    _buildDivider(),
                    _buildStorageTile(
                      icon: Icons.phone_android_rounded,
                      title: 'Local Storage',
                      subtitle: '8.3 MB used',
                      progress: 0.15,
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
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
                  colors: [Color(0xFF48DBFB), Color(0xFF0ABDE3)],
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

  Widget _buildStorageTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double progress,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF48DBFB), Color(0xFF0ABDE3)],
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
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF48DBFB),
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  void _showFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Backup Frequency',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 3, 7, 14, 30]
              .map((days) => RadioListTile<int>(
                    title: Text(
                      days == 1
                          ? 'Daily'
                          : days == 7
                              ? 'Weekly'
                              : days == 14
                                  ? 'Bi-weekly'
                                  : days == 30
                                      ? 'Monthly'
                                      : 'Every $days days',
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                    ),
                    value: days,
                    groupValue: _backupFrequency,
                    onChanged: (value) {
                      setState(() {
                        _backupFrequency = value!;
                      });
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _createBackup() {
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
              'Creating backup...',
              style: GoogleFonts.inter(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      setState(() {
        _lastBackupTime = 'Just now';
        _backupCount++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup created successfully',
            style: GoogleFonts.inter(),
          ),
        ),
      );
    });
  }

  void _restoreBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Restore Backup',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will replace your current data with the backup. Are you sure?',
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
                    'Data restored successfully',
                    style: GoogleFonts.inter(),
                  ),
                ),
              );
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _manageBackups() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Manage Backups',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Text(
          'No backups available',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

