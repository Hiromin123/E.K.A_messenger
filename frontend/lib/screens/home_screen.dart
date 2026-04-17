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

  // Открываем панель поиска пользователей
  void _showUsersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Важно! Чтобы шторка могла подняться над клавиатурой
      backgroundColor: bgColor,
      shape: Border(top: BorderSide(color: neonColor, width: 2)),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Сдвиг при открытии клавиатуры
          ),
          child: UserSearchSheet(
            onChatCreated: () {
              _loadChats(); // Обновляем список чатов на главном экране после создания
            },
          ),
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
                      // Если имя пришло с сервера - показываем его (заглавными буквами для стиля), 
                      // если нет (вдруг баг) - оставляем старый формат
                      chat['name'] != null ? chat['name'].toString().toUpperCase() : 'ЧАТ #${chat['id']}', 
                      style: TextStyle(fontFamily: 'PressStart2P', color: textColor, fontSize: 12),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: neonColor, size: 16),
                    onTap: () {
                      // Сначала формируем красивое имя так же, как для отображения в списке
                      final String displayName = chat['name'] != null 
                          ? chat['name'].toString().toUpperCase() 
                          : 'ЧАТ #${chat['id']}';

                      // Переходим на экран переписки и передаем оба параметра
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chat['id'], 
                            chatName: displayName, // Передаем имя!
                          ),
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

// --- НОВЫЙ ВИДЖЕТ ДЛЯ ШТОРКИ ПОИСКА ---
class UserSearchSheet extends StatefulWidget {
  final VoidCallback onChatCreated;

  const UserSearchSheet({super.key, required this.onChatCreated});

  @override
  State<UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<UserSearchSheet> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _users = [];
  bool _isLoading = false;

  final Color neonColor = const Color(0xFF0FDCF7);
  final Color textColor = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _searchUsers(''); // При открытии сразу грузим всех (чтобы было из кого выбирать)
  }

  // Функция реагирует на каждое изменение текста в поле
  void _searchUsers(String query) async {
    setState(() => _isLoading = true);
    final users = await _apiService.getUsers(query);
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6, // Занимаем 60% высоты экрана
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ПОЛЕ ВВОДА
          TextField(
            controller: _searchController,
            style: TextStyle(fontFamily: 'PressStart2P', color: textColor, fontSize: 10),
            cursorColor: neonColor,
            onChanged: _searchUsers, // Ищем при каждом введенном символе!
            decoration: InputDecoration(
              hintText: 'ПОИСК ПО НИКУ...',
              hintStyle: TextStyle(fontFamily: 'PressStart2P', color: textColor.withOpacity(0.5), fontSize: 10),
              prefixIcon: Icon(Icons.search, color: neonColor),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: neonColor.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: neonColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // СПИСОК РЕЗУЛЬТАТОВ
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: neonColor))
                : _users.isEmpty
                    ? Center(
                        child: Text(
                          'НЕ НАЙДЕНО', 
                          style: TextStyle(fontFamily: 'PressStart2P', color: textColor.withOpacity(0.5), fontSize: 10)
                        )
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return ListTile(
                            title: Text(
                              user['username'], 
                              style: TextStyle(fontFamily: 'PressStart2P', color: textColor, fontSize: 12)
                            ),
                            trailing: Icon(Icons.chat, color: neonColor),
                            onTap: () async {
                              Navigator.pop(context); // Закрываем шторку
                              await _apiService.createChat(user['id']);
                              widget.onChatCreated(); // Даем команду обновить чаты
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}