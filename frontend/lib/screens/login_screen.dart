import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  // Наши фирменные цвета
  final Color bgColor = const Color(0xFF031B36);
  final Color neonColor = const Color(0xFF0FDCF7);
  final Color textColor = const Color(0xFFFFFFFF);

  void _attemptLogin() async {
    setState(() {
      _isLoading = true;
    });

    final success = await _apiService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (!mounted) return;
      // Переходим на главный экран и закрываем экран логина
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
// ... дальше остается код с ошибкой (красный SnackBar)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ОШИБКА ДОСТУПА', style: TextStyle(fontFamily: 'PressStart2P', color: neonColor, fontSize: 10),),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Вспомогательный метод для создания стилизованного поля ввода
  Widget _buildNeonTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(fontFamily: 'PressStart2P', color: neonColor, fontSize: 12),
      cursorColor: neonColor,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.pressStart2p(color: textColor.withOpacity(0.5), fontSize: 10),
        // Тонкая овальная обводка (обычное состояние)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: neonColor, width: 1.0),
        ),
        // Обводка при нажатии (фокусе)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: neonColor, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Заголовок
              Text(
                'MESSENGER\nv1.0',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'PressStart2P', 
                  color: neonColor,
                  fontSize: 24,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 50),
              
              // Поле Логин
              _buildNeonTextField(
                controller: _usernameController,
                hintText: 'USERNAME',
              ),
              const SizedBox(height: 20),
              
              // Поле Пароль
              _buildNeonTextField(
                controller: _passwordController,
                hintText: 'PASSWORD',
                isPassword: true,
              ),
              const SizedBox(height: 40),
              
              // Кнопка входа
              _isLoading
                  ? CircularProgressIndicator(color: neonColor)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            side: BorderSide(color: neonColor, width: 2.0),
                          ),
                        ),
                        onPressed: _attemptLogin,
                        child: Text(
                          'START',
                          style: TextStyle(fontFamily: 'PressStart2P',
                            color: neonColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}