import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart'; // Наш новый парсер
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService();
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); // Контроллер для телефона

  bool _isLoading = false;
  bool _isLoginMode = true; // Переключатель режимов: true = Вход, false = Регистрация
  String _errorMessage = '';

  final Color bgColor = const Color(0xFF031B36);
  final Color neonColor = const Color(0xFF0FDCF7);
  final Color errorColor = const Color(0xFFFF003C);
  final Color textColor = const Color(0xFFFFFFFF);

  void _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'ЗАПОЛНИТЕ ВСЕ ПОЛЯ');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    bool success = false;

    if (_isLoginMode) {
      // --- ЛОГИКА ВХОДА ---
      success = await _apiService.login(username, password);
      if (!success) {
        setState(() => _errorMessage = 'НЕВЕРНЫЙ ЛОГИН ИЛИ ПАРОЛЬ');
      }
    } else {
      // --- ЛОГИКА РЕГИСТРАЦИИ ---
      if (phone.isEmpty) {
        setState(() {
          _errorMessage = 'ВВЕДИТЕ ТЕЛЕФОН';
          _isLoading = false;
        });
        return;
      }

      // ПРОВЕРКА НОМЕРА ТЕЛЕФОНА
      try {
        // Парсим номер. Ожидаем ввод в международном формате (с плюсом)
        final parsedPhone = PhoneNumber.parse(phone);
        
        // isValid() проверяет, существует ли код страны и правильная ли длина
        if (!parsedPhone.isValid()) {
          setState(() {
            _errorMessage = 'НЕСУЩЕСТВУЮЩИЙ НОМЕР ИЛИ КОД СТРАНЫ';
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'ОШИБКА ФОРМАТА (НАЧНИТЕ С +)';
          _isLoading = false;
        });
        return;
      }

      // Если номер прошел проверку, отправляем на сервер
      success = await _apiService.register(username, password, phone);
      if (!success) {
        setState(() => _errorMessage = 'ИМЯ ПОЛЬЗОВАТЕЛЯ УЖЕ ЗАНЯТО');
      }
    }

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = '';
      _phoneController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MESSENGER',
                style: TextStyle(fontFamily: 'PressStart2P', color: neonColor, fontSize: 24),
              ),
              const SizedBox(height: 10),
              Text(
                _isLoginMode ? 'ВХОД' : 'РЕГИСТРАЦИЯ',
                style: TextStyle(fontFamily: 'PressStart2P', color: textColor.withOpacity(0.5), fontSize: 12),
              ),
              const SizedBox(height: 40),
              
              // Поле Логина
              _buildTextField(_usernameController, 'НИКНЕЙМ', false),
              const SizedBox(height: 20),
              
              // Поле Пароля
              _buildTextField(_passwordController, 'ПАРОЛЬ', true),
              
              // Анимация появления поля телефона
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isLoginMode ? 0 : 80, // Если вход - скрываем, если рег - показываем
                curve: Curves.easeInOut,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildTextField(_phoneController, 'ТЕЛЕФОН (+7...)', false),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'PressStart2P', color: errorColor, fontSize: 10),
                  ),
                ),

              _isLoading
                  ? CircularProgressIndicator(color: neonColor)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bgColor,
                          side: BorderSide(color: neonColor, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                        ),
                        onPressed: _submit,
                        child: Text(
                          _isLoginMode ? 'ВОЙТИ' : 'ЗАРЕГИСТРИРОВАТЬСЯ',
                          style: TextStyle(fontFamily: 'PressStart2P', color: neonColor, fontSize: 12),
                        ),
                      ),
                    ),
              
              const SizedBox(height: 20),
              
              // Кнопка переключения режимов
              TextButton(
                onPressed: _toggleMode,
                child: Text(
                  _isLoginMode ? 'НЕТ АККАУНТА? СОЗДАТЬ' : 'УЖЕ ЕСТЬ АККАУНТ? ВОЙТИ',
                  style: TextStyle(fontFamily: 'PressStart2P', color: textColor.withOpacity(0.7), fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isObscure) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: TextStyle(fontFamily: 'PressStart2P', color: textColor, fontSize: 12),
      cursorColor: neonColor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'PressStart2P', color: textColor.withOpacity(0.3), fontSize: 10),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: neonColor.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: neonColor, width: 2),
        ),
      ),
    );
  }
}