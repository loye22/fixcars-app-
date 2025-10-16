import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ImageService {
  Future<File?> compressImage(File file) async {
    try {
      final filePath = file.path;
      final outPath = filePath.replaceAll(RegExp(r'\.[^\.]+$'), '_compressed.jpg');
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 70, // Adjust for smaller size vs. quality
        minWidth: 1024,
        minHeight: 1024,
        format: CompressFormat.jpeg,
      );
      return compressedFile != null ? File(compressedFile.path) : file;
    } catch (e) {
      print('Compression error: $e');
      return null; // Return null to indicate failure
    }
  }

  Future<Map<String, dynamic>> uploadFile(File file, String baseUrl) async {
    try {
      // Validate file existence and format
      if (!file.existsSync()) {
        return {'success': false, 'error': 'Fișierul nu există: ${file.path}'};
      }
      final supportedExtensions = ['jpg', 'jpeg', 'png'];
      final extension = file.path.split('.').last.toLowerCase();
      if (!supportedExtensions.contains(extension)) {
        return {
          'success': false,
          'error': 'Format neacceptat: $extension. Suportate: $supportedExtensions',
        };
      }

      // Log file size
      final fileSize = await file.length() / 1024 / 1024; // Size in MB
      print('Uploading file: ${file.path}, Size: ${fileSize.toStringAsFixed(2)} MB');

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-file/'));
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', extension),
        ),
      );
      request.headers['Accept'] = 'application/json';

      final streamedResponse = await request.send().timeout(Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      print("===========================================================");
      print("uploadFile Response");
      print("Status: ${response.statusCode}");
      print("Headers: ${response.headers}");
      print("Body: ${response.body.length > 1000 ? response.body.substring(0, 1000) : response.body}");
      print("===========================================================");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.contains('application/json')) {
          return {
            'success': false,
            'error': 'Răspunsul serverului nu este JSON. Content-Type: $contentType',
            'responseBody': response.body,
          };
        }
        try {
          final data = json.decode(response.body);
          return {'success': true, 'data': data};
        } catch (e) {
          return {
            'success': false,
            'error': 'Eroare la parsarea JSON: $e',
            'responseBody': response.body,
          };
        }
      } else {
        String errorMessage = 'Eroare server: ${response.statusCode} ${response.reasonPhrase}';
        try {
          final data = json.decode(response.body);
          errorMessage = data['error'] ?? data['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Răspuns invalid de la server (nu este JSON): ${response.body.substring(0, 200)}';
        }
        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
          'responseBody': response.body,
        };
      }
    } on SocketException catch (e) {
      return {'success': false, 'error': 'Fără conexiune la internet: $e'};
    }
  }
}