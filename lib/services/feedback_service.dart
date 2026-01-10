import 'package:http/http.dart' as http;
import 'dart:convert';

class FeedbackService {
  // Backend API endpoint - Replace with your actual backend URL
  // Example: 'https://your-backend.com/api/feedback'
  // For testing, you can use services like:
  // - EmailJS (https://www.emailjs.com/) - Free tier available
  // - Formspree (https://formspree.io/) - Free tier available
  // - Your own backend server
  static const String _apiEndpoint = 'YOUR_BACKEND_API_ENDPOINT_HERE';

  /// Sends feedback directly via backend API
  /// Returns true if successful, false otherwise
  static Future<Map<String, dynamic>> sendFeedback({
    required String feedbackType,
    required int rating,
    required String feedbackText,
    String? userEmail,
  }) async {
    try {
      // Prepare the request body
      final body = jsonEncode({
        'to': 'fynux.bussiness@gmail.com',
        'subject': 'Finzo Feedback - $feedbackType (Rating: $rating/5)',
        'feedbackType': feedbackType,
        'rating': rating,
        'feedback': feedbackText,
        'email': userEmail ?? 'No email provided',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Make POST request to backend
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Feedback sent successfully!',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send feedback. Please try again.',
          'error': 'Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error sending feedback: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Alternative: Send via EmailJS (Free service, no backend needed)
  /// You need to sign up at https://www.emailjs.com/ and get your credentials
  static Future<Map<String, dynamic>> sendFeedbackViaEmailJS({
    required String feedbackType,
    required int rating,
    required String feedbackText,
    String? userEmail,
    required String serviceId,
    required String templateId,
    required String publicKey,
  }) async {
    try {
      final emailjsEndpoint = 'https://api.emailjs.com/api/v1.0/email/send';

      final body = jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'to_email': 'fynux.bussiness@gmail.com',
          'subject': 'Finzo Feedback - $feedbackType (Rating: $rating/5)',
          'feedback_type': feedbackType,
          'rating': rating.toString(),
          'feedback': feedbackText,
          'user_email': userEmail ?? 'No email provided',
          'timestamp': DateTime.now().toIso8601String(),
        },
      });

      final response = await http.post(
        Uri.parse(emailjsEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Feedback sent successfully!',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send feedback. Please try again.',
          'error': 'Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error sending feedback: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Alternative: Send via Formspree (Free service, no backend needed)
  /// You need to sign up at https://formspree.io/ and get your form endpoint
  static Future<Map<String, dynamic>> sendFeedbackViaFormspree({
    required String feedbackType,
    required int rating,
    required String feedbackText,
    String? userEmail,
    required String formEndpoint, // e.g., 'https://formspree.io/f/YOUR_FORM_ID'
  }) async {
    try {
      final body = {
        'email': userEmail ?? 'anonymous@example.com',
        'subject': 'Finzo Feedback - $feedbackType (Rating: $rating/5)',
        'feedback_type': feedbackType,
        'rating': rating.toString(),
        'feedback': feedbackText,
        'timestamp': DateTime.now().toIso8601String(),
        '_replyto': 'fynux.bussiness@gmail.com',
      };

      final response = await http.post(
        Uri.parse(formEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Feedback sent successfully!',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send feedback. Please try again.',
          'error': 'Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error sending feedback: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }
}

