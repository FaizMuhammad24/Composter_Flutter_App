import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StorageService {
  // Cloudinary credentials provided by user
  static const String _cloudName = 'dwnym5d5h';
  static const String _uploadPreset = 'wzrtdwsj';

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
        print('Cloudinary upload failed: ${response.statusCode} - $errorResponse');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }
}
