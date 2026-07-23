import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/chat_bubble.dart';
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

  List<Color> _selectedGradient = [
    const Color(0xFFE0C3FC),
    const Color(0xFFE0C5FC),
  ];

  String? _selectedBgImage;

  final List<List<Color>> _gradientPresets = [
    [const Color(0xFFE0C3FC), const Color(0xFFE0C5FC)],
    [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
    [const Color(0xFFA1CAFD), const Color(0xFFC2E9FB)],
    [const Color(0xFF84FAB0), const Color(0xFF8FD3F4)],
    [const Color(0xFF232526), const Color(0xFF414345)],
  ];

  final List<String> _bgImagePresets = [
    'https://images.unsplash.com/photo-1611157817797-ed7184b2a12d?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    'https://images.unsplash.com/photo-1628029799784-50d803e64ea0?q=80&w=659&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    'https://plus.unsplash.com/premium_photo-1676478746576-a3e1a9496c23?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    'https://plus.unsplash.com/premium_photo-1666901328578-7fcbe821735e?q=80&w=627&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    'https://images.unsplash.com/photo-1621232082074-1a7750ecc557?q=80&w=627&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  ];

  String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api'; // Flutter Web / Chrome Browser
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api'; // Android Emulator
    } else {
      return 'http://127.0.0.1:8000/api'; // iOS / Desktop
    }
  }

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openThemePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Custome Chat Theme',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  const Text('Select Gradient Color:'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _gradientPresets.length,
                      itemBuilder: (context, index) {
                        final colors = _gradientPresets[index];
                        return GestureDetector(
                          onTap: () => {
                            setState(() {
                              _selectedGradient = colors;
                              _selectedBgImage = null;
                            }),
                            setModalState(() => {}),
                          },
                          child: Container(
                            width: 45,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: colors),
                              border: Border.all(
                                color:
                                    _selectedGradient == colors &&
                                        _selectedBgImage == null
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Select Background Pattern / Image:'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => {
                          setState(() {
                            _selectedBgImage = null;
                          }),
                          setModalState(() {}),
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedBgImage == null
                                  ? Colors.blue
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.disabled_by_default,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      ..._bgImagePresets.map((imgUrl) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBgImage = imgUrl;
                            });
                            setModalState(() {});
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(imgUrl),
                                fit: BoxFit.cover,
                              ),
                              border: Border.all(
                                color: _selectedBgImage == imgUrl
                                    ? Colors.blue
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
      } else {
        _showSnackBar('Failed to load chat history', isError: true);
        debugPrint('History load failed with code: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Failed to load chat history', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() {
      _messages.add(MessageModel(sender: 'user', content: text));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-message'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
      } else {
        _showSnackBar('Failed to get response from server', isError: true);
        final errorData = jsonDecode(response.body);
        String errorMessage =
            errorData['message'] ?? 'Error: Status ${response.statusCode}';
        setState(() {
          _messages.add(MessageModel(sender: 'bot', content: errorMessage));
        });
      }
    } catch (e) {
      _showSnackBar(
        'Network Error! Please check your connection.',
        isError: true,
      );
      setState(() {
        _messages.add(
          MessageModel(sender: 'bot', content: 'Network Error: $e'),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _scrollToBottom();
    }
  }

  void _clearLocalChat() {
    setState(() {
      _messages.clear();
    });
    _showSnackBar('Chat screen cleared successfully!', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                elevation: 0,
                backgroundColor: Colors.white.withOpacity(0.2),
                titleSpacing: 0,
                title: Row(
                  children: [
                    const SizedBox(width: 10),
                    Stack(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF2575FC),
                          child: Icon(
                            Icons.smart_toy_rounded,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent[400],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SmartChat Bot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.greenAccent[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: _openThemePicker,
                    icon: const Icon(
                      Icons.palette_outlined,
                      color: Colors.black87,
                    ),
                    tooltip: 'Change Theme',
                  ),
                  IconButton(
                    onPressed: _clearLocalChat,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.black54,
                    ),
                    tooltip: 'Clear Chat',
                  ),
                ],
              ),
            ),
          ),
        ),

        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _selectedGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            image: _selectedBgImage != null
                ? DecorationImage(
                    image: NetworkImage(_selectedBgImage!),
                    fit: BoxFit.cover,
                    opacity: 0.2,
                  )
                : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    top:
                        MediaQuery.of(context).padding.top +
                        kToolbarHeight +
                        10,
                    left: 10,
                    right: 10,
                    bottom: 80,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msgData = _messages[index];

                    final String content = msgData.content ?? '';
                    final bool isMe = (msgData.sender ?? 'user') == 'user';

                    return ChatBubble(message: content, isMe: isMe);
                  },
                ),
              ),

              if (_isLoading && _messages.isEmpty)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              "Bot is typing...",
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 8),
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 20,
                      top: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.black45),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF2575FC).withOpacity(0.9),
                                  const Color(0xFF6A11CB).withOpacity(0.9),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
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
}
