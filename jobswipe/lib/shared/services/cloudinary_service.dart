import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dfqxmh5gq';
  static const String uploadPreset = 'jobswipe_unsigned';

  static Future<String> uploadPdf({
    required Uint8List fileBytes,
    required String fileName,
    required String folder,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Erreur Cloudinary : $responseBody';
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final secureUrl = data['secure_url'];

    if (secureUrl == null || secureUrl.toString().isEmpty) {
      throw 'Cloudinary n’a pas retourné d’URL.';
    }

    return secureUrl.toString();
  }
}
