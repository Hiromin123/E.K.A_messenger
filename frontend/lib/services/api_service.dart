import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  final storage = const FlutterSecureStorage();

// Скачать историю сообщений
  Future<List<Map<String, dynamic>>> getChatMessages(int chatId) async {
    final url = Uri.parse('$baseUrl/chats/$chatId/messages');
    final headers = await _getHeaders();
    
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      // Приводим данные к нужному типу List<Map<String, dynamic>>
      return data.cast<Map<String, dynamic>>(); 
    }
    return [];
  }
  // --- МЕТОДЫ АВТОРИЗАЦИИ ---

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'jwt_token', value: data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'jwt_token');
    return token != null;
  }

  // --- НОВЫЕ МЕТОДЫ ДЛЯ ЧАТОВ ---

  // Вспомогательная функция для получения заголовков с токеном
  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Получить список моих чатов
  Future<List<dynamic>> getMyChats() async {
    final url = Uri.parse('$baseUrl/chats');
    final headers = await _getHeaders();
    
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      // Используем utf8.decode, чтобы русские символы (если будут) не сломались
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return [];
  }

  // Получить список всех пользователей (для поиска собеседника)
  Future<List<dynamic>> getUsers() async {
    final url = Uri.parse('$baseUrl/users');
    final headers = await _getHeaders();
    
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return [];
  }

  // Создать новый чат
  Future<Map<String, dynamic>?> createChat(int targetUserId) async {
    final url = Uri.parse('$baseUrl/chats');
    final headers = await _getHeaders();
    
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'target_user_id': targetUserId, 'is_group': false}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return null;
  }
}

