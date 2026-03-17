import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import '../widgets/chat_bubble.dart';
import '../utils/constants.dart';
import '../models/chat_model.dart';

class ChatScreen extends StatefulWidget{
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver{
  final List<MessageModel> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final VoiceService _voiceService = VoiceService();
  final String _sessionId = const Uuid().v4();

  bool _isProcessing = false;
  bool _isListening = false;
  bool _isApiAvailable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    _checkApiHealth();
  }

  Future<void> _initializeChat() async {
    await _voiceService.initialize();
    _addMessage(
      'Welcome to ASTRA! How can I help you today?',
      MessageType.assistant,
    );


    _toggleListening();
  }

  Future<void> _checkApiHealth() async {
    final isHealthy = await _apiService.checkHealth();
    setState(() => _isApiAvailable = isHealthy);

    if (!isHealthy) {
      _addMessage(
        '⚠️ Backend server not connected. Please check if the server is running.',
        MessageType.system,
      );
    }
  }

  void _addMessage(String text, MessageType type, {bool isVoice = false}) {
    setState(() {
      _messages.add(
        MessageModel(
          id: const Uuid().v4(),
          text: text,
          type: type,
          timestamp: DateTime.now(),
          isVoiceMessage: isVoice,
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }



  Future<void> _processVoiceInput(String recognizedText) async {
    if (recognizedText.isEmpty || _isProcessing) return;

    _addMessage(recognizedText, MessageType.user, isVoice: true);
    setState(() => _isProcessing = true);

    try {
      if (!_isApiAvailable) {
        _addMessage(
          '⚠️ Backend server not connected. Please check if the server is running.',
          MessageType.system,
        );
        setState(() => _isProcessing = false);
        return;
      }

      final request = ChatRequest(
        userMessage: recognizedText,
        sessionId: _sessionId,
        context: _getLastAssistantMessage(),
        voiceInput: true,
      );

      final response = await _apiService.sendChatMessage(request);


      _addMessage(response.message, MessageType.assistant, isVoice: true);


      await _voiceService.speak(response.message);

    } catch (e) {
      print('❌ Error: $e');
      _addMessage(
        'Sorry, I encountered an error. Please try again.',
        MessageType.assistant,
      );
    } finally {
      setState(() => _isProcessing = false);


      _toggleListening();
    }
  }

  String _getLastAssistantMessage() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].type == MessageType.assistant) {
        return _messages[i].text;
      }
    }
    return '';
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);

      await _voiceService.startListening((recognizedWords) {
        if (recognizedWords.isNotEmpty && recognizedWords.length > 2) {
          setState(() => _isListening = false);
          _processVoiceInput(recognizedWords);
        }
      });
    }
  }

  void _showMessageOptions(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.type == MessageType.assistant)
              ListTile(
                leading: const Icon(Icons.volume_up, color: Colors.white70),
                title: const Text('Speak again', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _voiceService.speak(message.text);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isApiAvailable ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),

            const Text(
              'ASTRA Voice Assistant',
              style: TextStyle(color: AppColors.neonPink, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : AppColors.neonPink,
            ),
            onPressed: _toggleListening,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
              child: Text(
                'Tap the microphone and start speaking',
                style: TextStyle(color: Colors.white54),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return ChatBubble(
                  message: message,
                  onLongPress: message.type == MessageType.assistant
                      ? () => _showMessageOptions(message)
                      : null,
                );
              },
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonPink),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ASTRA is thinking...',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          if (_isListening)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neonPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.neonPink.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.graphic_eq, color: AppColors.neonPink),
                  SizedBox(width: 8),
                  Text(
                    'Listening... Speak now',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AppColors {
  static const neonPink = Color(0xFF1457FF);
}

















/*import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import '../widgets/chat_bubble.dart';
import '../utils/constants.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final List<MessageModel> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final VoiceService _voiceService = VoiceService();
  final String _sessionId = const Uuid().v4();

  bool _isProcessing = false;
  bool _isListening = false;
  bool _isApiAvailable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    _checkApiHealth();
  }

  Future<void> _initializeChat() async {
    await _voiceService.initialize();
    _addMessage(
      'Welcome to ASTRA! How can I help you today?',
      MessageType.assistant,
    );
  }

  Future<void> _checkApiHealth() async {
    final isHealthy = await _apiService.checkHealth();
    setState(() => _isApiAvailable = isHealthy);

    if (!isHealthy) {
      _addMessage(
        '⚠️ Backend server not connected. Please check if the server is running.',
        MessageType.system,
      );
    }
  }

  void _addMessage(String text, MessageType type, {bool isVoice = false}) {
    setState(() {
      _messages.add(
        MessageModel(
          id: const Uuid().v4(),
          text: text,
          type: type,
          timestamp: DateTime.now(),
          isVoiceMessage: isVoice,
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? text, bool isVoice = false}) async {
    final messageText = text ?? _textController.text.trim();

    if (messageText.isEmpty || _isProcessing) return;

    if (!isVoice) {
      _textController.clear();
    }

    _addMessage(messageText, MessageType.user, isVoice: isVoice);

    setState(() => _isProcessing = true);

    try {
      if (!_isApiAvailable) {
        _addMessage(
          'Backend server is not available. Please make sure the server is running.',
          MessageType.assistant,
        );
        setState(() => _isProcessing = false);
        return;
      }

      final request = ChatRequest(
        userMessage: messageText,
        sessionId: _sessionId,
        context: _getLastAssistantMessage(),
        voiceInput: isVoice,
      );

      final response = await _apiService.sendChatMessage(request);

      _addMessage(response.message, MessageType.assistant);

      if (isVoice) {
        await _voiceService.speak(response.message);
      }

    } catch (e) {
      print('Error sending message: $e');
      _addMessage(
        'Sorry, I encountered an error. Please check if the backend server is running.',
        MessageType.assistant,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  String _getLastAssistantMessage() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].type == MessageType.assistant) {
        return _messages[i].text;
      }
    }
    return '';
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);

      await _voiceService.startListening((recognizedWords) {
        if (recognizedWords.isNotEmpty) {
          setState(() => _isListening = false);
          _sendMessage(text: recognizedWords, isVoice: true);
        }
      });
    }
  }

  void _showMessageOptions(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white70),
              title: const Text('Copy', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Copy to clipboard
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied')),
                );
              },
            ),
            if (message.type == MessageType.assistant)
              ListTile(
                leading: const Icon(Icons.volume_up, color: Colors.white70),
                title: const Text('Speak again', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _voiceService.speak(message.text);
                  Navigator.pop(context);
                },
              ),
            if (message.type == MessageType.user)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() {
                    _messages.remove(message);
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isApiAvailable ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'ASTRA Chat',
              style: TextStyle(color: AppColors.neonPink),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _checkApiHealth,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
              child: Text(
                'Start a conversation with ASTRA',
                style: TextStyle(color: Colors.white54),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return ChatBubble(
                  message: message,
                  onLongPress: () => _showMessageOptions(message),
                );
              },
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonPink),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ASTRA is thinking...',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isApiAvailable
                    ? 'Type a message...'
                    : 'Server not connected...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
              enabled: _isApiAvailable && !_isProcessing,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: _isApiAvailable && !_isProcessing
                  ? AppColors.neonPink
                  : Colors.grey[600],
            ),
            onPressed: _isApiAvailable && !_isProcessing
                ? () => _sendMessage()
                : null,
          ),
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening
                  ? Colors.red
                  : (_isApiAvailable ? AppColors.neonPink : Colors.grey[600]),
            ),
            onPressed: _isApiAvailable && !_isProcessing
                ? _toggleListening
                : null,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _scrollController.dispose();
    _voiceService.dispose();
    super.dispose();
  }
}

class AppColors {
  static const neonPink = Color(0xFF1457FF); // Keep your blue color
  static const lightPink = Color(0xFF68C0E6);
}*/













/*import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/message_model.dart';
import '../widgets/chat_bubble.dart';
import '../utils/tts_handler.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/message_model.dart';
import '../widgets/chat_bubble.dart';
import '../utils/tts_handler.dart';
import '../services/gemini_service.dart';

class ChatScreen extends StatefulWidget{
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>{
  final List<MessageModel> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final TtsHandler _ttsHandler = TtsHandler();
  late final GeminiService _gemini;


  bool _isListening = false;
  bool _isAstraTyping = false;
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState(){
    super.initState();
    _gemini = GeminiService();
    _gemini.initialize();
    _initSpeech();
  }


  Future<void> _initSpeech() async{
    _speechEnabled = await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );

    if (_speechEnabled){

      _messages.add(MessageModel.astra('Hello! I am Astra. I am always listening.'));
      _ttsHandler.speak('Hello! I am Astra. I am always listening.');
      _startListening();
    }

  }


  void _startListening(){
    _speech.listen(
      onResult: (SpeechRecognitionResult result){
        setState(() => _lastWords = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _processCommand(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      localeId: 'en_US',
    );
  }


  Future<void> _processCommand(String text) async{
    setState(() => _isAstraTyping = true);

    String response = await _gemini.askQuestion(text);

    setState((){

      _messages.add(MessageModel.user(text));
      _messages.add(MessageModel.astra(response));
      _isAstraTyping = false;
    }
    );

    await _ttsHandler.speak(response);
    _scrollToBottom();

    _startListening();
  }


  void _scrollToBottom(){

    if(_scrollController.hasClients){

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,

      );
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(

      backgroundColor: Colors.black,


      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        title: Row(
          children: [

            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.neonPink.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neonPink, width: 1),
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.neonPink),
            ),


            const SizedBox(width: 8),
            const Text(
              'Astra',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [

          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              children: [

                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? Colors.green : AppColors.neonPink,
                  ),
                ),
                const SizedBox(width: 4),


                Text(
                  _isListening ? 'Listening' : 'Ready',
                  style: TextStyle(
                    color: _isListening ? Colors.green : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(


              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => ChatBubble(message: _messages[index]),
            ),
          ),


          Container(

            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],

              borderRadius: const BorderRadius.only(

                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),

            child: Row(
              children: [

                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? Colors.green.withOpacity(0.2)
                        : AppColors.neonPink.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 14,
                    color: _isListening ? Colors.green : AppColors.neonPink,
                  ),
                ),
                const SizedBox(width: 12),


                Expanded(
                  child: Text(
                    _isAstraTyping
                        ? 'Astra is thinking...'
                        : (_isListening
                        ? 'Listening... speak now'
                        : 'Tap mic to speak'),
                    style: TextStyle(
                      color: _isAstraTyping
                          ? Colors.orange
                          : (_isListening ? Colors.green : Colors.white70),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),


                if (!_isListening)

                  IconButton(
                    icon: Icon(Icons.mic, color: AppColors.neonPink, size: 20),
                    onPressed: _startListening,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

              ],
            ),

          ),


          if (_isListening && _lastWords.isEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neonPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neonPink.withOpacity(0.3)),

              ),

              child: Row(
                children: [

                  SizedBox(
                    width: 40,
                    height: 20,


                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,


                      children: List.generate(4, (index) =>
                          AnimatedContainer(
                            duration: Duration(milliseconds: 400 + (index * 100)),
                            width: 4,
                            height: 10 + (index * 3).toDouble(),

                            decoration: BoxDecoration(
                              color: AppColors.neonPink,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'I\'m listening...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),


          if (_lastWords.isNotEmpty && _isListening)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neonPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neonPink.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.graphic_eq, color: AppColors.neonPink, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Heard: "$_lastWords"',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),


          if (_isAstraTyping)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Astra is thinking...',
                    style: TextStyle(color: Colors.orange, fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AppColors {
  static const neonPink = Color(0xFF1457FF);
}*/






/*import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/message_model.dart';
import '../widgets/chat_bubble.dart';


import '../utils/tts_handler.dart';
import '../services/gemini_service.dart';

class ChatScreen extends StatefulWidget{


  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>{
  final List<MessageModel> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final TtsHandler _ttsHandler = TtsHandler();
  late final GeminiService _gemini;

  bool _isListening = false;
  bool _isAstraTyping = false;
  bool _speechEnabled = false;
  String _recognizedText = '';
  bool _isProcessing = false;
  bool _isAstraSpeaking = false;
  bool _welcomeShown = false;


  Timer? _noSpeechTimer;

  @override
  void initState() {
    super.initState();
    print('🔵 [INIT] ChatScreen started');
    _gemini = GeminiService();
    const String apiKey = String.fromEnvironment('GEMINI_API_KEY');
    _gemini.initialize(apiKey);

    Future.delayed(const Duration(seconds: 3), () {
      _testMicrophoneDirectly();
    });
    _initAll();
  }

  @override
  void dispose() {
    print('🔴 [DISPOSE] ChatScreen disposed');
    _noSpeechTimer?.cancel();
    _speech.stop();
    _ttsHandler.dispose();
    super.dispose();
  }

  Future<void> _initAll() async {
    await _initSpeech();
    await _ttsHandler.initTts();
    await _ttsHandler.setFemaleVoice();

    if (!_welcomeShown && mounted) {
      setState(() {
        _welcomeShown = true;
        _messages.add(MessageModel.astra('Hello! I am Astra. I am always listening.'));
      });

      setState(() => _isAstraSpeaking = true);
      await _ttsHandler.speak('Hello! I am Astra. I am always listening.');
      setState(() => _isAstraSpeaking = false);

      if (_speechEnabled) {
        _startListening();
      }
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
              // Auto restart
              if (!_isProcessing && !_isAstraSpeaking && mounted) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) _startListening();
                });
              }
            }
          }
        },
        onError: (error) {
          print('Speech error: $error');
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
      );
      print('✅ Speech initialized: $_speechEnabled');
    } catch (e) {
      print('Speech init error: $e');
      _speechEnabled = false;
    }
  }



  Future<void> _startListening() async {
    if (!_speechEnabled) {
      print('❌ Speech not enabled');
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    print('🎤 Chat listening started...');

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });

          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            String text = result.recognizedWords.trim();
            print('✅ Chat heard: "$text"');
            _stopListeningAndProcess(text);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        localeId: 'en_US',
        cancelOnError: false,
      );
    } catch (e) {
      print('❌ Chat listen error: $e');
      setState(() => _isListening = false);
    }
  }


  void _testMicrophoneDirectly() async {
    print('🎤 ===== MICROPHONE DIRECT TEST =====');
    print('🎤 Speech enabled: $_speechEnabled');

    try {
      final bool available = await _speech.isAvailable ?? false;
      print('🎤 Is speech recognition available: $available');

      final locales = await _speech.locales();
      print('🎤 Available locales: ${locales.length}');
      for (var l in locales) {
        print('   - ${l.localeId}: ${l.name}');
      }

      // Try to listen for 2 seconds and see if we get any audio
      print('🎤 Testing short listen...');
      await _speech.listen(
        onResult: (result) {
          print('🎤 GOT RESULT: ${result.recognizedWords}');
        },
        listenFor: const Duration(seconds: 2),
      );
      await Future.delayed(const Duration(seconds: 2));
      await _speech.stop();
      print('🎤 Test complete');

    } catch (e) {
      print('🎤 TEST ERROR: $e');
    }
  }


  /*void _resetNoSpeechTimer() {
    _noSpeechTimer?.cancel();
    _noSpeechTimer = Timer(const Duration(seconds: 7), () {
      if (_isListening && _recognizedText.isEmpty && mounted) {
        print('⚠️ No speech for 7 seconds, but staying on...');

        setState(() {

        });
      }
    });
  }*/

  Future<void> _stopListeningAndProcess(String text) async {
    if (_isProcessing) return;

    await _speech.stop();
    setState(() {
      _isListening = false;
      _isProcessing = true;
    });

    // Add user message
    setState(() => _messages.add(MessageModel.user(text)));
    _scrollToBottom();

    // Show typing indicator
    setState(() => _isAstraTyping = true);

    // Get response from Gemini
    String response = await _gemini.askQuestion(text);

    // Add Astra response
    setState(() {
      _isAstraTyping = false;
      _messages.add(MessageModel.astra(response));
      _isProcessing = false;
    });

    // Speak response
    setState(() => _isAstraSpeaking = true);
    await _ttsHandler.speak(response);
    setState(() => _isAstraSpeaking = false);

    _scrollToBottom();

    // Restart listening after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _startListening();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.neonPink.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neonPink, width: 1),
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.neonPink),
            ),
            const SizedBox(width: 8),
            const Text('Astra', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: AppColors.neonPink),
            onPressed: _startListening,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => ChatBubble(message: _messages[index]),
            ),
          ),

          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAstraSpeaking ? Colors.orange : (_isListening ? Colors.green : AppColors.neonPink),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isAstraSpeaking
                        ? 'Astra is speaking...'
                        : (_isListening ? 'Listening... (always on)' : 'Ready'),
                    style: TextStyle(
                      color: _isAstraSpeaking ? Colors.orange : (_isListening ? Colors.green : AppColors.neonPink),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Listening indicator with partial text
          if (_isListening)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neonPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.neonPink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _recognizedText.isEmpty
                          ? 'Listening... (say something)'
                          : 'Heard: "$_recognizedText"',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

          // Astra thinking indicator
          if (_isAstraTyping)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neonPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.neonPink,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Astra is thinking...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AppColors {
  static const neonPink = Color(0xFF1457FF);
}

*/