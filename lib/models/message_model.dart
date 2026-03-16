enum MessageType { user, assistant, system }

class MessageModel {
  final String id;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final bool isVoiceMessage;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
    this.isVoiceMessage = false,
    this.metadata,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? DateTime.now().toString(),
      text: json['text'] ?? '',
      type: _parseMessageType(json['type']),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isVoiceMessage: json['isVoiceMessage'] ?? false,
      metadata: json['metadata'],
    );
  }

  static MessageType _parseMessageType(String? type) {
    switch (type?.toLowerCase()) {
      case 'user':
        return MessageType.user;
      case 'assistant':
        return MessageType.assistant;
      default:
        return MessageType.system;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isVoiceMessage': isVoiceMessage,
      'metadata': metadata,
    };
  }
}