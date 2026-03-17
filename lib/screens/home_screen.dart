import 'package:astra_voice_assistant/screens/test_speech_screen.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/voice_wave.dart';
import '../utils/tts_handler.dart';
import '../utils/wake_word_handler.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver{


  bool _hasPermission = false;

  bool _isChecking = true;

  bool _isListening = false;
  bool _isWakeWordActive = true;

  final SpeechToText _speech = SpeechToText();

  bool _speechEnabled = false;

  final TtsHandler _ttsHandler = TtsHandler();


  bool _ttsReady = false;

  late WakeWordHandler _wakeWordHandler;

  void _onAITap(){

    if(!_hasPermission){
      _requestPermission();
      return;

    }

    setState(() => _isWakeWordActive = false);
    _wakeWordHandler.pauseListening();


    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatScreen()),
    ).then((_) {
      setState(() => _isWakeWordActive = true);
      if (_isWakeWordActive) {
        _wakeWordHandler.startListeningForWake();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _initTts();
    _initWakeWordHandler();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wakeWordHandler.dispose();
    _ttsHandler.dispose();
    super.dispose();
  }

  void _initWakeWordHandler() {
    _wakeWordHandler = WakeWordHandler(
      onWakeWordDetected: _onWakeWordDetected,
      onPartialText: (text) {},
      onError: (error) {},
    );
  }

  Future<void> _onWakeWordDetected() async {
    await _wakeWordHandler.pauseListening();
    setState(() => _isWakeWordActive = false);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatScreen()),
      ).then((_) {
        setState(() => _isWakeWordActive = true);
        _wakeWordHandler.startListeningForWake();
      });
    }
  }

  Future<void> _initTts() async {
    await _ttsHandler.initTts();
    await _ttsHandler.setFemaleVoice();
    setState(() => _ttsReady = true);
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          print('Speech error: ${error.errorMsg}');
          setState(() => _isListening = false);
        },
      );
      if (_speechEnabled && _hasPermission && mounted && _isWakeWordActive) {
        _wakeWordHandler.startListeningForWake();
      }
    } catch (e) {
      print('Speech init error: $e');
      _speechEnabled = false;
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    setState(() {
      _hasPermission = status.isGranted;
      _isChecking = false;
    });

    if (!status.isGranted) {
      _requestPermission();
    } else {
      _initSpeech();
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    setState(() => _hasPermission = status.isGranted);
    if (status.isGranted) {
      _initSpeech();
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog();
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: const Text('Please enable microphone in settings'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _onMicTap() {
    if (!_hasPermission) {
      _requestPermission();
      return;
    }
    setState(() => _isWakeWordActive = false);
    _wakeWordHandler.pauseListening();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatScreen()),
    ).then((_) {
      setState(() => _isWakeWordActive = true);
      _wakeWordHandler.startListeningForWake();
    });
  }

  void _toggleWakeWord() {
    setState(() => _isWakeWordActive = !_isWakeWordActive);
    if (_isWakeWordActive) {
      _wakeWordHandler.startListeningForWake();
    } else {
      _wakeWordHandler.stopListeningForWake();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              AppColors.neonPink.withOpacity(0.15),
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeader(),
                _buildCenterContent(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 40),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppColors.lightPink, AppColors.neonPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'ASTRA',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: Colors.white,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.settings,
                color: _isWakeWordActive ? AppColors.neonPink : Colors.grey[400],
                size: 24,
              ),
              onPressed: _toggleWakeWord,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Your personal voice companion',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.neonPink.withOpacity(0.9),
            letterSpacing: 1.5,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildCenterContent() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildVoiceCircle(),
        const SizedBox(height: 20),


        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neonPink.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _isWakeWordActive ? 'Say "Hey Astra"' : 'Tap mic to start',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ),

        const SizedBox(height: 20),


        GestureDetector(
          onTap: _onAITap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.neonPink, AppColors.lightPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonPink.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'AI Chat Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

      ],
    );
  }

  Widget _buildVoiceCircle() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.neonPink.withOpacity(0.3),
                  AppColors.neonPink.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          if (_isListening)
            const VoiceWave(),
          GestureDetector(
            onTap: _onMicTap,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hasPermission ? AppColors.neonPink.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
              ),
              child: Icon(
                _hasPermission ? Icons.mic : Icons.mic_off,
                size: 40,
                color: _hasPermission ? AppColors.neonPink : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: AppColors.neonPink, thickness: 0.5, indent: 50, endIndent: 50),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _getStatusColor()),
            ),
            const SizedBox(width: 6),
            Text(_getStatusText(), style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Color _getStatusColor() {
    if (_isChecking) return Colors.grey;
    if (!_hasPermission) return Colors.red;
    if (!_speechEnabled) return Colors.orange;
    if (!_ttsReady) return Colors.orange;
    return AppColors.neonPink;
  }

  String _getStatusText() {
    if (_isChecking) return 'Checking...';
    if (!_hasPermission) return 'Permission required';
    if (!_speechEnabled) return 'Initializing...';
    if (!_ttsReady) return 'Initializing...';
    if (_isWakeWordActive) return 'Say "Hey Astra"';
    return 'Tap mic';
  }
}

class AppColors {
  static const neonPink = Color(0xFF1457FF);
  static const lightPink = Color(0xFF68C0E6);
}