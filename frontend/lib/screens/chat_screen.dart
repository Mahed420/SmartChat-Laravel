import 'dart:convert';
import 'package:flutter/material.dart';
import 'chat_bubble.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  final String _apiUrl = 'http://127.0.0.1:8000/api/send-message';

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add({'message': text, 'isMe': true});
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _messages.add({
            'message': data['bot_message']['content'].toString(),
            'isMe': false,
          });
        });
      } else {
        debugPrint('Server Error: ${response.body}');
      }
    } catch (e) {
      debugPrint('Connection Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laravel Chat Bot')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msgData = _messages[index];
                final String messageText =
                    msgData['message']?.toString() ?? 'No message text';
                final bool isMe = msgData['isMe'] ?? false;

                return ChatBubble(message: messageText, isMe: isMe);
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
