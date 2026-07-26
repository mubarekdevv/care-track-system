class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String senderRole;
  final String senderName;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  bool isMine(String userId) => senderId == userId;

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    DateTime createdAt = DateTime.now();
    final raw = map['createdAt'];
    if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? createdAt;
    }

    return ChatMessage(
      id: id,
      threadId: map['threadId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      senderRole: map['senderRole']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'threadId': threadId,
      'senderId': senderId,
      'senderRole': senderRole,
      'senderName': senderName,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
