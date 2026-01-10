import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../services/feedback_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _feedbackType = 'Suggestion';
  int _rating = 5;
  bool _isSubmitting = false;

  // Configuration for direct email sending
  // Option 1: Use EmailJS (Recommended - Free, no backend needed)
  // Sign up at https://www.emailjs.com/ and get your credentials
  static const bool _useEmailJS = false; // Set to true to enable
  static const String _emailJSServiceId = 'YOUR_SERVICE_ID';
  static const String _emailJSTemplateId = 'YOUR_TEMPLATE_ID';
  static const String _emailJSPublicKey = 'YOUR_PUBLIC_KEY';

  // Option 2: Use Formspree (Free service, no backend needed)
  // Sign up at https://formspree.io/ and get your form endpoint
  static const bool _useFormspree = false; // Set to true to enable
  static const String _formspreeEndpoint =
      'https://formspree.io/f/YOUR_FORM_ID';

  // Option 3: Use your own backend API
  static const bool _useBackendAPI = false; // Set to true to enable
  // Update FeedbackService._apiEndpoint when enabling this

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

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
          'Feedback',
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
                        const Color(0xFFFECA57).withValues(alpha: 0.2),
                        const Color(0xFFFF9F43).withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFFECA57).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFECA57), Color(0xFFFF9F43)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'We\'d Love Your Feedback',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help us improve by sharing your thoughts',
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

                // Rating
                _buildSectionHeader('Rate Your Experience'),
                const SizedBox(height: 12),
                Container(
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.star_rounded,
                            color: index < _rating
                                ? const Color(0xFFFECA57)
                                : AppColors.textMuted,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 24),

                // Feedback Type
                _buildSectionHeader('Feedback Type'),
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
                      _buildTypeOption('Suggestion', Icons.lightbulb_rounded),
                      _buildDivider(),
                      _buildTypeOption('Bug Report', Icons.bug_report_rounded),
                      _buildDivider(),
                      _buildTypeOption(
                        'Feature Request',
                        Icons.add_circle_rounded,
                      ),
                      _buildDivider(),
                      _buildTypeOption('Other', Icons.more_horiz_rounded),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Feedback Form
                _buildSectionHeader('Your Feedback'),
                const SizedBox(height: 12),
                Container(
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
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.surfaceVariant,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _feedbackController,
                        maxLines: 6,
                        style: GoogleFonts.inter(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Tell us what you think...',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Your email (optional)',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.email_rounded,
                            color: AppColors.textMuted,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.surfaceVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.surfaceVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFECA57), Color(0xFFFF9F43)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFECA57).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Submit Feedback',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
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

  Widget _buildTypeOption(String title, IconData icon) {
    final isSelected = _feedbackType == title;
    return InkWell(
      onTap: () {
        setState(() {
          _feedbackType = title;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFFECA57), Color(0xFFFF9F43)],
                      )
                    : null,
                color: isSelected ? null : AppColors.surfaceVariant,
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
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFFFECA57),
                size: 24,
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

  void _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your feedback',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isSubmitting) return; // Prevent multiple submissions

    setState(() {
      _isSubmitting = true;
    });

    // Prepare feedback data
    final userEmail = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : null;
    final feedbackText = _feedbackController.text.trim();

    // Try direct email sending via API first (if configured)
    Map<String, dynamic>? result;

    if (_useEmailJS) {
      result = await FeedbackService.sendFeedbackViaEmailJS(
        feedbackType: _feedbackType,
        rating: _rating,
        feedbackText: feedbackText,
        userEmail: userEmail,
        serviceId: _emailJSServiceId,
        templateId: _emailJSTemplateId,
        publicKey: _emailJSPublicKey,
      );
    } else if (_useFormspree) {
      result = await FeedbackService.sendFeedbackViaFormspree(
        feedbackType: _feedbackType,
        rating: _rating,
        feedbackText: feedbackText,
        userEmail: userEmail,
        formEndpoint: _formspreeEndpoint,
      );
    } else if (_useBackendAPI) {
      result = await FeedbackService.sendFeedback(
        feedbackType: _feedbackType,
        rating: _rating,
        feedbackText: feedbackText,
        userEmail: userEmail,
      );
    }

    // If direct sending was successful
    if (result != null && result['success'] == true) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        // Clear form
        _feedbackController.clear();
        _emailController.clear();
        setState(() {
          _rating = 5;
          _feedbackType = 'Suggestion';
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Feedback sent successfully!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Close screen after a delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
      return;
    }

    // If direct sending failed or not configured, fall back to email client
    setState(() {
      _isSubmitting = false;
    });

    final subject = 'Finzo Feedback - $_feedbackType (Rating: $_rating/5)';
    final body =
        'Feedback Type: $_feedbackType\n'
        'Rating: $_rating/5\n'
        'Email: ${userEmail ?? 'No email provided'}\n\n'
        'Feedback:\n$feedbackText';

    // Try to open email client with pre-filled feedback
    final emailUri = Uri.parse(
      'mailto:fynux.bussiness@gmail.com?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      // Try to launch email directly
      if (await canLaunchUrl(emailUri)) {
        final launched = await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Email app opened. Please send the email to submit your feedback.',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: AppColors.surface,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      print('Error launching email: $e');
    }

    // Fallback: Use share functionality to copy email content
    final shareText =
        'To: fynux.bussiness@gmail.com\n'
        'Subject: $subject\n\n'
        '$body';

    try {
      await Share.share(shareText, subject: subject);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Feedback shared. Please send it to fynux.bussiness@gmail.com',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.surface,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Last resort: Show email content in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Email Content',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'To: fynux.bussiness@gmail.com',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subject: $subject',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    body,
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please copy this content and send it via your email app.',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
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
    }
  }
}
