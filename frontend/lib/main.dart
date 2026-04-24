import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MessengerApp());
}

class MessengerApp extends StatelessWidget {
  const MessengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Self-Hosted Messenger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // Используем FutureBuilder для определения стартового экрана
      home: FutureBuilder<bool>(
        future: ApiService().isLoggedIn(),
        builder: (context, snapshot) {
          // Пока ждем ответа от хранилища, показываем экран загрузки
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: const Color(0xFF031B36),
              body: Center(
                child: CircularProgressIndicator(color: const Color(0xFF0FDCF7)),
              ),
            );
          }
          
          // Если проверка прошла успешно и токен есть — идем в чаты
          if (snapshot.hasData && snapshot.data == true) {
            return const HomeScreen();
          }
          
          // Иначе — на экран авторизации
          return const LoginScreen();
        },
      ),
    );
  }
}
//goyda
//zzz