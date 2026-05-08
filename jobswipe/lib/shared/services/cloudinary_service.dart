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
      throw 'Erreur Cloudinary PDF : $responseBody';
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    return data['secure_url'].toString();
  }

  static Future<String> uploadVideo({
    required Uint8List fileBytes,
    required String fileName,
    required String folder,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/video/upload',
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
      throw 'Erreur Cloudinary vidéo : $responseBody';
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    return data['secure_url'].toString();
  }
}
