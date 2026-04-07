import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Сохраняем нашу палитру
  final Color bgColor = const Color(0xFF031B36);
  final Color neonColor = const Color(0xFF0FDCF7);
  final Color textColor = const Color(0xFFFFFFFF);

  void _logout(BuildContext context) async {
    // Удаляем токен из безопасного хранилища
    await ApiService().storage.delete(key: 'jwt_token');
    
    if (!context.mounted) return;
    // Возвращаемся на экран логина, уничтожая историю навигации
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(
          'CHATS', 
          style: TextStyle(fontFamily: 'PressStart2P', color: neonColor, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: neonColor),
            onPressed: () => _logout(context),
          )
        ],
        // Неоновая линия под AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: neonColor, height: 1.0),
        ),
      ),
      body: Center(
        child: Text(
          'ПОКА ПУСТО...', 
          style: GoogleFonts.pressStart2p(color: textColor, fontSize: 12),
        ),
      ),
    );
  }
}