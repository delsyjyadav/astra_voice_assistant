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
      print('Sending to: $baseUrl${Constants.chatEndpoint}');

      final response = await http.post(
        Uri.parse('$baseUrl${Constants.chatEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 10));

      print('Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return ChatResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${Constants.healthEndpoint}'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
}