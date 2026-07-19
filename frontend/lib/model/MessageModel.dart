class MessageModel {
  final String sender;
  final String content;

  MessageModel({required this.sender, required this.content});

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      sender: json['sender'] ?? '',
      content: json['content'] ?? '',
    );
  }
}
