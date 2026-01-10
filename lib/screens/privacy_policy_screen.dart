import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                _buildSection(
                  'Introduction',
                  'Finzo ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Information We Collect',
                  'We do not collect or gather any user data. All information you enter in the application, including:\n\n'
                      '• Transaction data (amounts, categories, dates)\n'
                      '• Account information\n'
                      '• Notes and todos\n'
                      '• Category preferences\n'
                      '• App settings and preferences\n\n'
                      'is stored exclusively on your device using local storage. We do not have any backend servers, and no data is transmitted to external servers. Your data remains completely private and under your control.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'How We Use Your Information',
                  'Since all data is stored locally on your device, we do not have access to your information. The application uses your locally stored data to:\n\n'
                      '• Provide and maintain the service on your device\n'
                      '• Display your transactions and financial data\n'
                      '• Send you local notifications (if enabled)\n\n'
                      'No data is transmitted to external servers or third parties.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Data Storage',
                  'All your financial data is stored exclusively on your device using local storage. We do not have any backend infrastructure, cloud services, or external servers. Your data never leaves your device and is not transmitted anywhere.\n\n'
                      'You have complete control over your data and can delete it at any time through the app settings. Since all data is local, if you uninstall the app, all data will be removed from your device.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Data Security',
                  'We implement appropriate technical and organizational measures to protect your personal information. However, no method of transmission over the internet or electronic storage is 100% secure, and we cannot guarantee absolute security.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Third-Party Services',
                  'Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to read their privacy policies.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Children\'s Privacy',
                  'Our service is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Changes to This Privacy Policy',
                  'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Contact Us',
                  'If you have any questions about this Privacy Policy, please contact us at:\n\n'
                      'Email: support@finzo.app\n'
                      'Or through the Feedback section in the app.',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.surfaceVariant,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
