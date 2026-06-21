import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmailJSService {
  static const String _serviceId = 'service_5wqh1cp';
  static const String _templateId = 'template_hqzjvd8';
  static const String _userId = 'i9bzLf0q8zxpFumId'; // Public Key
  static const String _privateKey = 'ih_oyOZY9ucPypRyc2Pfp'; // Private Key

  static Future<bool> sendOtpEmail(String toEmail, String otpCode) async {
    // Coba beberapa format API yang didukung EmailJS
    final endpoints = [
      'https://api.emailjs.com/api/v1.0/email/send',
      'https://api.emailjs.com/api/v1.6/email/send',
    ];

    for (final endpoint in endpoints) {
      debugPrint('EmailJS: Trying endpoint $endpoint');
      debugPrint('EmailJS: service_id=$_serviceId, template_id=$_templateId');
      debugPrint('EmailJS: user_id=$_userId');

      try {
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'service_id': _serviceId,
            'template_id': _templateId,
            'user_id': _userId,
            'accessToken': _privateKey,
            'template_params': {
              'to_email': toEmail,
              'otp_code': otpCode,
            }
          }),
        );

        debugPrint('EmailJS Response [$endpoint]: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200) {
          debugPrint('EmailJS: OTP sent successfully to $toEmail');
          return true;
        }
      } catch (e) {
        debugPrint('EmailJS Exception [$endpoint]: $e');
      }
    }

    // Fallback: coba format form-encoded (bukan JSON)
    debugPrint('EmailJS: Trying form-encoded format...');
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send-form'),
        body: {
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _userId,
          'accessToken': _privateKey,
          'to_email': toEmail,
          'otp_code': otpCode,
        },
      );

      debugPrint('EmailJS Form Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('EmailJS: OTP sent successfully via form to $toEmail');
        return true;
      }
    } catch (e) {
      debugPrint('EmailJS Form Exception: $e');
    }

    debugPrint('EmailJS: All attempts failed');
    return false;
  }
}
