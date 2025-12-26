import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<HelpItem> _helpItems = [
    HelpItem(
      title: 'Getting Started',
      icon: Icons.play_circle_rounded,
      questions: [
        'How do I add a transaction?',
        'How do I create categories?',
        'How do I set up accounts?',
      ],
    ),
    HelpItem(
      title: 'Transactions',
      icon: Icons.receipt_long_rounded,
      questions: [
        'How do I edit a transaction?',
        'How do I delete a transaction?',
        'Can I import transactions?',
      ],
    ),
    HelpItem(
      title: 'Categories',
      icon: Icons.category_rounded,
      questions: [
        'How do I create custom categories?',
        'Can I delete categories?',
        'How do I manage subcategories?',
      ],
    ),
    HelpItem(
      title: 'Backup & Sync',
      icon: Icons.cloud_rounded,
      questions: [
        'How do I backup my data?',
        'How do I restore from backup?',
        'How does cloud sync work?',
      ],
    ),
    HelpItem(
      title: 'Settings',
      icon: Icons.settings_rounded,
      questions: [
        'How do I change currency?',
        'How do I enable notifications?',
        'How do I change the theme?',
      ],
    ),
  ];

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
          'Help & Support',
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
                // Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.2),
                        AppColors.secondaryLight.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, AppColors.secondaryLight],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.help_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'How Can We Help?',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find answers to common questions',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Help Categories
                ..._helpItems.map((item) => _buildHelpCategory(item)),

                const SizedBox(height: 24),

                // Contact Support
                _buildSectionHeader('Still Need Help?'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildContactTile(
                      icon: Icons.email_rounded,
                      title: 'Email Support',
                      subtitle: 'support@moneyapp.com',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildContactTile(
                      icon: Icons.chat_rounded,
                      title: 'Live Chat',
                      subtitle: 'Chat with our support team',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildContactTile(
                      icon: Icons.phone_rounded,
                      title: 'Phone Support',
                      subtitle: '+1 (555) 123-4567',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Resources
                _buildSectionHeader('Resources'),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  children: [
                    _buildResourceTile(
                      icon: Icons.video_library_rounded,
                      title: 'Video Tutorials',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildResourceTile(
                      icon: Icons.article_rounded,
                      title: 'User Guide',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildResourceTile(
                      icon: Icons.forum_rounded,
                      title: 'Community Forum',
                      onTap: () {},
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

  Widget _buildHelpCategory(HelpItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(item.title),
        const SizedBox(height: 12),
        Container(
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
            children: [
              ...item.questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return Column(
                  children: [
                    _buildQuestionTile(
                      icon: item.icon,
                      question: question,
                      onTap: () => _showAnswerDialog(question),
                    ),
                    if (index < item.questions.length - 1) _buildDivider(),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuestionTile({
    required IconData icon,
    required String question,
    required VoidCallback onTap,
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
                  colors: [AppColors.secondary, AppColors.secondaryLight],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                question,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                  colors: [AppColors.secondary, AppColors.secondaryLight],
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildResourceTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
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
                  colors: [AppColors.secondary, AppColors.secondaryLight],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.surfaceVariant,
      indent: 60,
    );
  }

  void _showAnswerDialog(String question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          question,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Text(
          'Here is a detailed answer to your question. This feature helps you understand how to use the app effectively.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.inter(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class HelpItem {
  final String title;
  final IconData icon;
  final List<String> questions;

  HelpItem({
    required this.title,
    required this.icon,
    required this.questions,
  });
}

