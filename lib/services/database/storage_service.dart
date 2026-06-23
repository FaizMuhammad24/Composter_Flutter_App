import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageService {
  // Cloudinary credentials provided by user
  static final String _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static final String _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  /// Uploads an image to Cloudinary and returns the secure URL.
  Future<String?> uploadCompostPhoto({
    required String userEmail,
    required File imageFile,
  }) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'compost_photos/${userEmail.replaceAll('@', '_')}'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);
        return jsonResponse['secure_url'] as String;
      } else {
        final errorResponse = await response.stream.bytesToString();
        debugPrint('Cloudinary upload failed: ${response.statusCode} - $errorResponse');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      return null;
    }
  }
}
