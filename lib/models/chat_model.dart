class ChatRequest {
  final String userMessage;
  final String sessionId;
  final String context;
  final String? fieldName;
  final bool voiceInput;

  ChatRequest({
    required this.userMessage,
    required this.sessionId,
    this.context = '',
    this.fieldName,
    this.voiceInput = false,
  });

  Map<String, dynamic> toJson() => {
    'user_message': userMessage,
    'session_id': sessionId,
    'context': context,
    'field_name': fieldName,
    'voice_input': voiceInput,
  };
}

class ChatResponse {
  final String message;
  final String sessionId;
  final bool isVoiceResponse;

  ChatResponse({
    required this.message,
    required this.sessionId,
    this.isVoiceResponse = false,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      message: json['message'] ?? '',
      sessionId: json['session_id'] ?? '',
      isVoiceResponse: json['is_voice_response'] ?? false,
    );
  }
}