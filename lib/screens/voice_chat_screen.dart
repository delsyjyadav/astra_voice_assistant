/*import 'package:flutter/material.dart';
import 'dart:math';
import '../services/voice_service.dart';
import '../services/api_service.dart';
import '../models/chat_model.dart';
import 'package:uuid/uuid.dart';

class VoiceChatScreen extends StatefulWidget {
  final VoiceService voiceService;

  const VoiceChatScreen({super.key, required this.voiceService});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  final ApiService _apiService = ApiService();
  final String _sessionId = const Uuid().v4();
  final List<Map<String, String>> _messages = [];
  bool _isListening = false;
  bool _isProcessing = false;
  String _lastCommand = '';

  @override
  void initState() {
    super.initState();
    _addMessage('Welcome to ASTRA! How can I help you today?', 'assistant');
  }

  void _addMessage(String text, String sender) {
    setState(() {
      _messages.add({
        'text': text,
        'sender': sender,
        'time': DateTime.now().toString(),
      });
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await widget.voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _isProcessing = true;
      });

      await widget.voiceService.startListening((recognizedWords) {
        if (recognizedWords.isNotEmpty) {
          setState(() {
            _lastCommand = recognizedWords;
            _isListening = false;
            _isProcessing = true;
          });

          _sendToGemini(recognizedWords);
        }
      });
    }
  }

  Future<void> _sendToGemini(String userMessage) async {
    _addMessage(userMessage, 'user');

    try {
      final request = ChatRequest(
        userMessage: userMessage,
        sessionId: _sessionId,
        context: _messages.lastWhere(
              (msg) => msg['sender'] == 'assistant',
          orElse: () => {'text': ''},
        )['text']!,
        voiceInput: true,
      );

      final response = await _apiService.sendChatMessage(request);

      _addMessage(response.message, 'assistant');
      await widget.voiceService.speak(response.message);

    } catch (e) {
      _addMessage('Sorry, I encountered an error. Please try again.', 'assistant');
      await widget.voiceService.speak('Sorry, I encountered an error. Please try again.');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ASTRA Voice Assistant',
          style: TextStyle(color: Color(0xFFFF1493)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFFFF1493).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message['text']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493)),
              ),
            ),

          // Voice button
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (_lastCommand.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      '"$_lastCommand"',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? const Color(0xFFFF1493)
                          : const Color(0xFFFF1493).withOpacity(0.3),
                      boxShadow: _isListening
                          ? [
                        BoxShadow(
                          color: const Color(0xFFFF1493).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                          : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isListening ? 'Listening...' : 'Tap to speak',
                  style: const TextStyle(color: Colors.white54),
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
    widget.voiceService.dispose();
    super.dispose();
  }
}*/