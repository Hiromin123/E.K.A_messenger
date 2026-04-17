import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String chatName; // Добавили переменную для имени
  
  // Обязательно добавляем её в конструктор:
  const ChatScreen({super.key, required this.chatId, required this.chatName}); 

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  WebSocketChannel? _channel;
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // Список сообщений
  
  final Color bgColor = const Color(0xFF031B36);
  final Color neonColor = const Color(0xFF0FDCF7);
  final Color textColor = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _loadHistoryAndConnect();
  }

  // Сначала грузим прошлое, потом подключаемся к будущему
  void _loadHistoryAndConnect() async {
    // 1. Скачиваем историю из базы
    final history = await ApiService().getChatMessages(widget.chatId);
    
    if (mounted) {
      setState(() {
        _messages.addAll(history);
      });
    }

    // 2. Открываем WebSocket туннель для новых сообщений
    _connectWebSocket();
  }

  void _connectWebSocket() async {
    final token = await ApiService().storage.read(key: 'jwt_token');
    if (token == null) return;

    final wsUrl = Uri.parse('ws://10.0.2.2:8000/ws/${widget.chatId}?token=$token');
    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen((data) {
      if (mounted) {
        setState(() {
          _messages.add(jsonDecode(data));
        });
      }
    });
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && _channel != null) {
      // Отправляем текст на сервер
      _channel!.sink.add(_controller.text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: neonColor),
        title: Text(
          widget.chatName, // <-- ТЕПЕРЬ ТУТ ИМЯ
          style: TextStyle(fontFamily: 'PressStart2P', color: neonColor, fontSize: 14),
        ),
        // ... остальной код AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: neonColor, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[${msg['sender']}]: ',
                        style: TextStyle(fontFamily: 'PressStart2P', color: neonColor, fontSize: 10),
                      ),
                      Expanded(
                        child: Text(
                          msg['text'],
                          style: TextStyle(fontFamily: 'PressStart2P', color: textColor, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Панель ввода
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: neonColor.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(fontFamily: 'PressStart2P', color: textColor, fontSize: 10),
                    cursorColor: neonColor,
                    decoration: InputDecoration(
                      hintText: 'СООБЩЕНИЕ...',
                      hintStyle: TextStyle(fontFamily: 'PressStart2P', color: textColor.withOpacity(0.5), fontSize: 10),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: neonColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close(); // Обязательно закрываем туннель при выходе из чата!
    _controller.dispose();
    super.dispose();
  }
}