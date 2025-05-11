import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ApiService {
  static const String baseUrl = "http://192.168.1.2:5000";

  static Future<Map<String, dynamic>?> lookupWord(String word) async {
    final url = Uri.parse('$baseUrl/lookup');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"word": word}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<String?> uploadAudio(File audioFile) async {
    try {
      final uri = Uri.parse('$baseUrl/voice2sign');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('audio', audioFile.path));
      final response = await request.send();

      if (response.statusCode == 200) {
        return await response.stream.bytesToString();
      } else {
        return 'Upload failed with status ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }


  static Future<String?> downloadVideo(String word) async {
    try {
      final url = Uri.parse('$baseUrl/static/videos/${word.toLowerCase().replaceAll(' ', '_')}.mp4');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/${word.toLowerCase().replaceAll(' ', '_')}.mp4';
        File file = File(path);
        await file.writeAsBytes(response.bodyBytes);
        return path;
      } else {
        return null;
      }
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }

  static Future<String?> uploadSignVideo(File videoFile) async {
    try {
      final uri = Uri.parse('$baseUrl/translate');  // <-- Correct endpoint
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('video', videoFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        return await response.stream.bytesToString();
      } else {
        print("Upload failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error uploading video: $e");
      return null;
    }
  }


  static Future<File?> saveVideoLocally(File videoFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/${videoFile.path.split('/').last}';
      final savedVideo = await videoFile.copy(newPath);
      return savedVideo;
    } catch (e) {
      print('Error saving video: $e');
      return null;
    }
  }
}
