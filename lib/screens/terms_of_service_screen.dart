import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
                  'Agreement to Terms',
                  'By accessing or using Finzo, you agree to be bound by these Terms of Service. If you disagree with any part of these terms, then you may not access the service.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Use License',
                  'Permission is granted to temporarily download one copy of Finzo for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n'
                  '• Modify or copy the materials\n'
                  '• Use the materials for any commercial purpose\n'
                  '• Attempt to reverse engineer any software contained in Finzo\n'
                  '• Remove any copyright or other proprietary notations from the materials',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'User Accounts',
                  'When you create an account with us, you must provide information that is accurate, complete, and current at all times. You are responsible for safeguarding the password and for all activities that occur under your account.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Prohibited Uses',
                  'You may not use Finzo:\n\n'
                  '• In any way that violates any applicable law or regulation\n'
                  '• To transmit any malicious code or viruses\n'
                  '• To attempt to gain unauthorized access to any portion of the service\n'
                  '• To interfere with or disrupt the service or servers',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'In-App Purchases',
                  'Finzo offers in-app purchases for Pro features. All purchases are processed through the respective app store (Google Play Store or Apple App Store). Refunds are subject to the policies of the app store.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Disclaimer',
                  'The materials on Finzo are provided on an "as is" basis. Finzo makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Limitations',
                  'In no event shall Finzo or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use Finzo, even if Finzo or a Finzo authorized representative has been notified orally or in writing of the possibility of such damage.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Accuracy of Materials',
                  'The materials appearing in Finzo could include technical, typographical, or photographic errors. Finzo does not warrant that any of the materials on its app are accurate, complete, or current.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Modifications',
                  'Finzo may revise these terms of service at any time without notice. By using this app you are agreeing to be bound by the then current version of these terms of service.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Governing Law',
                  'These terms and conditions are governed by and construed in accordance with applicable laws. Any disputes relating to these terms shall be subject to the exclusive jurisdiction of the courts in the applicable jurisdiction.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Contact Information',
                  'If you have any questions about these Terms of Service, please contact us at:\n\n'
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
        border: Border.all(
          color: AppColors.surfaceVariant,
          width: 1,
        ),
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

