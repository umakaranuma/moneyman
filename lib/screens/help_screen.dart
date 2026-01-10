import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../core/router/app_router.dart';

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
    // Backup & Sync - Commented out as not implemented yet
    // HelpItem(
    //   title: 'Backup & Sync',
    //   icon: Icons.cloud_rounded,
    //   questions: [
    //     'How do I backup my data?',
    //     'How do I restore from backup?',
    //     'How does cloud sync work?',
    //   ],
    // ),
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
                      subtitle: 'support@finzo.app',
                      onTap: () => _openEmailSupport(),
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
                      icon: Icons.feedback_rounded,
                      title: 'Send Feedback',
                      onTap: () {
                        Navigator.pop(context);
                        context.goToFeedback();
                      },
                    ),
                    _buildDivider(),
                    _buildResourceTile(
                      icon: Icons.star_rounded,
                      title: 'Rate Us',
                      onTap: () => AppUtils.rateApp(),
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
    String answer = _getAnswerForQuestion(question);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          question,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            answer,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAnswerForQuestion(String question) {
    switch (question) {
      case 'How do I add a transaction?':
        return 'To add a transaction:\n\n'
            '1. Tap the "+" button on the home screen\n'
            '2. Select whether it\'s an Income or Expense\n'
            '3. Enter the amount\n'
            '4. Choose a category\n'
            '5. Add a note (optional)\n'
            '6. Select the date\n'
            '7. Tap "Save" to complete';
      
      case 'How do I create categories?':
        return 'To create categories:\n\n'
            '1. Go to Settings > Categories\n'
            '2. Tap the "+" button\n'
            '3. Enter category name\n'
            '4. Choose an icon and color\n'
            '5. Select if it\'s for Income or Expense\n'
            '6. Tap "Save"';
      
      case 'How do I set up accounts?':
        return 'To set up accounts:\n\n'
            '1. Go to the Accounts tab\n'
            '2. Tap the "+" button\n'
            '3. Enter account name (e.g., "Cash", "Bank Account")\n'
            '4. Set initial balance\n'
            '5. Choose account type\n'
            '6. Tap "Save"';
      
      case 'How do I edit a transaction?':
        return 'To edit a transaction:\n\n'
            '1. Find the transaction in your list\n'
            '2. Tap on the transaction\n'
            '3. Make your changes\n'
            '4. Tap "Save" to update';
      
      case 'How do I delete a transaction?':
        return 'To delete a transaction:\n\n'
            '1. Find the transaction in your list\n'
            '2. Long press on the transaction\n'
            '3. Select "Delete" from the menu\n'
            '4. Confirm the deletion';
      
      case 'Can I import transactions?':
        return 'Yes! You can import transactions:\n\n'
            '1. Go to Settings > SMS Import\n'
            '2. Grant SMS permission if prompted\n'
            '3. The app will scan your SMS for transaction messages\n'
            '4. Review and confirm the transactions\n'
            '5. Tap "Import" to add them to your records';
      
      case 'How do I create custom categories?':
        return 'To create custom categories:\n\n'
            '1. Navigate to Settings > Categories\n'
            '2. Tap the "+" button at the top\n'
            '3. Enter a name for your category\n'
            '4. Select an icon and color\n'
            '5. Choose Income or Expense type\n'
            '6. Tap "Save" to create';
      
      case 'Can I delete categories?':
        return 'Yes, you can delete categories:\n\n'
            '1. Go to Settings > Categories\n'
            '2. Find the category you want to delete\n'
            '3. Long press on the category\n'
            '4. Select "Delete" from the menu\n'
            'Note: You cannot delete categories that have transactions';
      
      case 'How do I manage subcategories?':
        return 'To manage subcategories:\n\n'
            '1. Go to Settings > Categories\n'
            '2. Tap on a category\n'
            '3. You\'ll see the subcategories list\n'
            '4. Tap "+" to add a subcategory\n'
            '5. Long press to edit or delete';
      
      // Backup & Sync questions - Commented out as not implemented yet
      // case 'How do I backup my data?':
      //   return 'To backup your data:\n\n'
      //       '1. Go to Settings > Backup\n'
      //       '2. Tap "Create Backup"\n'
      //       '3. Choose backup location (local or cloud)\n'
      //       '4. Wait for backup to complete\n'
      //       'Note: Backup feature is available in Pro version';
      //
      // case 'How do I restore from backup?':
      //   return 'To restore from backup:\n\n'
      //       '1. Go to Settings > Backup\n'
      //       '2. Tap "Restore Backup"\n'
      //       '3. Select the backup file\n'
      //       '4. Confirm restoration\n'
      //       'Note: This will replace your current data';
      //
      // case 'How does cloud sync work?':
      //   return 'Cloud sync allows you to:\n\n'
      //       '• Sync data across multiple devices\n'
      //       '• Automatically backup your data\n'
      //       '• Access your data from anywhere\n\n'
      //       'Note: Cloud sync is available in Pro version';
      
      case 'How do I change currency?':
        return 'To change currency:\n\n'
            '1. Go to Settings\n'
            '2. Tap on "Currency"\n'
            '3. Select your preferred currency\n'
            '4. The app will update all amounts';
      
      case 'How do I enable notifications?':
        return 'To enable notifications:\n\n'
            '1. Go to Settings\n'
            '2. Find "Notifications" section\n'
            '3. Toggle "Enable Notifications" on\n'
            '4. Grant notification permission if prompted';
      
      case 'How do I change the theme?':
        return 'To change the theme:\n\n'
            '1. Go to Settings\n'
            '2. Find "Theme" in General settings\n'
            '3. Toggle between Dark and Light mode\n'
            '4. The app will update immediately';
      
      default:
        return 'For more help, please contact our support team at support@finzo.app or use the Feedback section in the app.';
    }
  }

  void _openEmailSupport() {
    AppUtils.openUrl('mailto:support@finzo.app?subject=Support Request');
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

