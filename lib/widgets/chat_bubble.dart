import 'package:flutter/material.dart';
import '../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;
    final isSystem = message.type == MessageType.system;

    if (isSystem) {
      return _buildSystemMessage();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAssistantAvatar(),
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Container(
                margin: EdgeInsets.only(
                  left: isUser ? 50 : 8,
                  right: isUser ? 8 : 50,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.neonPink : Colors.grey[900],
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                    bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.grey[300],
                        fontSize: 15,
                      ),
                    ),
                    if (message.isVoiceMessage) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.graphic_eq,
                            size: 14,
                            color: isUser ? Colors.white70 : AppColors.neonPink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Voice',
                            style: TextStyle(
                              fontSize: 11,
                              color: isUser ? Colors.white70 : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAssistantAvatar() {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.neonPink.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.neonPink, width: 1),
      ),
      child: const Icon(
        Icons.auto_awesome,
        size: 18,
        color: AppColors.neonPink,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[600]!, width: 1),
      ),
      child: const Icon(
        Icons.person,
        size: 18,
        color: Colors.white70,
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class AppColors {
  static const neonPink = Color(0xFF1457FF);
  static const lightPink = Color(0xFF68C0E6);
}