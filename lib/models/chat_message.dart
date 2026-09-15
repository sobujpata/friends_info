/// Chat message model mapped to the PocketSync messages table.
class ChatMessage {
  final int? id; // SQLite auto-increment primary key
  final String senderId; // sender personnelNo
  final String message; // message body
  final String createdAt; // ISO-8601 timestamp string

  const ChatMessage({
    this.id,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  /// Converts this object to a database row. Remove the auto-generated id before insert.
  Map<String, dynamic> toMap() => {
        'id': id,
        'sender_id': senderId,
        'message': message,
        'created_at': createdAt,
      };

  /// Creates a message object from a database row.
  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] as int?,
        senderId: m['sender_id'] as String,
        message: m['message'] as String,
        createdAt: m['created_at'] as String,
      );

  ChatMessage copyWith({
    int? id,
    String? senderId,
    String? message,
    String? createdAt,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        senderId: senderId ?? this.senderId,
        message: message ?? this.message,
        createdAt: createdAt ?? this.createdAt,
      );
}