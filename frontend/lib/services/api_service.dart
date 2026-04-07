import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Для Android эмулятора используем 10.0.2.2. 
  // Если тестируешь в браузере или iOS-симуляторе, поменяй на 127.0.0.1
  static const String baseUrl = 'http://10.0.2.2:8000';
  final storage = const FlutterSecureStorage();

  // Функция авторизации
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        
        // Надежно сохраняем токен на устройстве
        await storage.write(key: 'jwt_token', value: token);
        return true;
      } else {
        // Обработка ошибки (например, неверный пароль)
        print('Ошибка авторизации: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Сетевая ошибка: $e');
      return false;
    }
  }

  // Вспомогательная функция для проверки, есть ли уже токен
  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'jwt_token');
    return token != null;
  }
}