import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'chat_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _chats = [];
  bool _isLoading = true;

  final Color bgColor = const Color(0xFF031B36);
  final Color neonColor = const Color(0xFF0FDCF7);
  final Color textColor = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  // Загружаем список чатов с сервера
  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    final chats = await _apiService.getMyChats();
    setState(() {
      _chats = chats;
      _isLoading = false;
    });
  }

  // Открываем панель со списком всех пользователей
  void _showUsersBottomSheet() async {
    final users = await _apiService.getUsers();
    
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: Border(top: BorderSide(color: neonColor, width: 2)),
      builder: (context) {
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(
                user['username'],
                style: TextStyle(fontFamily: 'PressStart2P', color: textColor, fontSize: 12),
              ),
              trailing: Icon(Icons.chat, color: neonColor),
              onTap: () async {
                Navigator.pop(context); // Закрываем шторку
                await _apiService.createChat(user['id']); // Создаем чат на сервере
                _loadChats(); // Обновляем список чатов
              },
            );
          },
        );
      },
    );
  }

  void _logout() async {
    await _apiService.storage.delete(key: 'jwt_token');
    if (!mounted) return;
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
            onPressed: _logout,
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: neonColor, height: 1.0),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: neonColor))
        : _chats.isEmpty
          ? Center(
              child: Text(
                'ПУСТО...', 
                style: TextStyle(fontFamily: 'PressStart2P', color: textColor.withOpacity(0.5), fontSize: 12),
              ),
            )
          : ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: neonColor.withOpacity(0.3))),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    title: Text(
                      'ЧАТ #${chat['id']}', 
                      style: TextStyle(fontFamily: 'PressStart2P', color: textColor, fontSize: 12),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: neonColor, size: 16),
                    onTap: () {
                      // Переходим на экран переписки
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(chatId: chat['id']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      // Плавающая кнопка для начала нового диалога
      floatingActionButton: FloatingActionButton(
        backgroundColor: bgColor,
        shape: CircleBorder(side: BorderSide(color: neonColor, width: 2)),
        onPressed: _showUsersBottomSheet,
        child: Icon(Icons.add, color: neonColor),
      ),
    );
  }
}