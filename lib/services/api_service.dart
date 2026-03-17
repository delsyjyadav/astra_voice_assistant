import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_model.dart';
import '../utils/constants.dart';
import '../models/chat_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = Constants.baseUrl;

  Future<ChatResponse> sendChatMessage(ChatRequest request) async {
    try {
      final url = '${Constants.baseUrl}${Constants.chatEndpoint}';
      print('Sending to: $url');
      print('Request: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 15));



      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return ChatResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }

  Future<bool> checkHealth() async {
    try {
      final url = '${Constants.baseUrl}${Constants.healthEndpoint}';
      print('Health check: $url');

      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
}