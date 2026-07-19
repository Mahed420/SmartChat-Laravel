import 'dart:convert';
import 'package:flutter/material.dart';
import 'chat_bubble.dart';
import 'package:http/http.dart' as http;
import '../model/MessageModel.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  List<MessageModel> _messages = [];
  bool _isLoading = false;

  final String _sendUrl = 'http://127.0.0.1:8000/api/send-message';
  final String _historyUrl = 'http://127.0.0.1:8000/api/messages';

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(_historyUrl),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _messages = (data['messages'] as List)
                .map((msg) => MessageModel.fromJson(msg))
                .toList();
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add(MessageModel(sender: 'user', content: text));
      _isLoading = true;
      _scrollToBottom();
    });

    try {
      final response = await http.post(
        Uri.parse(_sendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _messages.add(
            MessageModel(
              sender: data['bot_message']['sender'].toString(),
              content: data['bot_message']['content'].toString(),
            ),
          );
        });
        _scrollToBottom();
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
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msgData = _messages[index];

                final bool isMe = msgData.sender == 'user';

                return ChatBubble(message: msgData.content, isMe: isMe);
              },
            ),
          ),

          if (_isLoading && _messages.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_isLoading)
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
