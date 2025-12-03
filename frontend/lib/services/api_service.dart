import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.0.120:8000/api';

  static Future<String> generateSummary(String text, {int numSentences = 5}) async {
    try {
      print('Generating summary for text length: ${text.length}');
      print('API endpoint: $baseUrl/summarize/');
      
      final response = await http.post(
        Uri.parse('$baseUrl/summarize/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'num_sentences': numSentences,
        }),
      ).timeout(const Duration(seconds: 60));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['summary'];
        if (summary != null && summary.toString().isNotEmpty) {
          return summary.toString();
        } else {
          throw Exception('Empty summary received from server');
        }
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception('Invalid request: ${errorData['detail'] ?? 'Bad request'}');
      } else if (response.statusCode == 500) {
        final errorData = jsonDecode(response.body);
        throw Exception('Server error: ${errorData['detail'] ?? 'Internal server error'}');
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in generateSummary: $e');
      if (e.toString().contains('Connection refused') || e.toString().contains('SocketException')) {
        throw Exception('Backend server is not running. Please start the backend server on port 8000.');
      }
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. The server may be processing or unavailable.');
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }
}