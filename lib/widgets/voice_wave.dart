import 'package:flutter/material.dart';

import '../main.dart';

class VoiceWave extends StatelessWidget {

  const VoiceWave({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 800),

      curve: Curves.easeInOut,

      builder: (context, double value, child) {

        return Container(
          width: 200 * value,
          height: 200 * value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonPinkWithOpacity(0.1),
          ),
        );
      },
    );
  }
}



/*
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../widgets/voice_wave.dart';
import '../widgets/feature_chip.dart';
import '../utils/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  //permission
  bool _hasPermission = false;
  bool _isChecking = true;
  bool _isListening = false;

  //speech to text
  final SpeechToText _speech = SpeechToText();
  bool _speechEnabled = false;
  String _recognizedText = '';
  String _lastCommand = '';
  List<String> _recentCommands = [];

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  //initialize speech recognition - call AFTER permission granted
  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
        onError: (error) {
          print('Speech error: ${error.errorMsg}');
          // Don't show error for client errors
          if (error.errorMsg != 'error_client') {
            if (mounted) {
              _showErrorSnackBar('Please try again');
            }
          }
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        },
        debugLogging: true,
      );
    } catch (e) {
      print('Speech initialization error: $e');
      _speechEnabled = false;
    }
  }

  //check permission
  Future<void> _checkPermission() async {
    final hasPermission = await PermissionsHandler.checkMicrophonePermission();
    setState(() {
      _hasPermission = hasPermission;
      _isChecking = false;
    });

    if (!hasPermission) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog();
      });
    }
  }

  //request permission
  Future<void> _requestPermission() async {
    final granted = await PermissionsHandler.requestMicrophonePermission();
    setState(() {
      _hasPermission = granted;
    });

    if (granted) {
      // Initialize speech ONLY after permission is granted
      await _initSpeech();
    }
  }

  //permission dialog
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Enable Microphone',
          style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Astra needs microphone access to hear your voice commands.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermission();
            },
            child: Text('Allow', style: TextStyle(color: AppColors.neonPink)),
          ),
        ],
      ),
    );
  }

  //start listening
  Future<void> _startListening() async {
    if (!_hasPermission) {
      _requestPermission();
      return;
    }

    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        _showErrorSnackBar('Speech recognition not available');
        return;
      }
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    try {
      // Get available locales
      final locales = await _speech.locales();
      print('Available locales: $locales');

      // Find English locale
      var englishLocale = locales.firstWhere(
            (l) => l.localeId.contains('en_US') || l.localeId.contains('en_US'),
        orElse: () => locales.first,
      );

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });

          if (result.finalResult) {
            _processCommand(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: englishLocale.localeId, // Dynamic locale
        cancelOnError: false, // CHANGE this to false
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      print('Listen error: $e');
      setState(() {
        _isListening = false;
      });
      _showErrorSnackBar('Please check your internet connection');
    }
  }

  //stop listening
  Future<void> _stopListening() async {
    try {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });

      //save last commnd
      if (_recognizedText.isNotEmpty) {
        setState(() {
          _lastCommand = _recognizedText;
          _recentCommands.insert(0, _recognizedText);
          if (_recentCommands.length > 5) {
            _recentCommands.removeLast();
          }
        });
      }
    } catch (e) {
      print('Error stopping speech: $e');
    }
  }

  //process voice commnds
  void _processCommand(String text) {
    if (text.trim().isEmpty) return;

    final lowerText = text.toLowerCase();

    //basic commnds
    if (lowerText.contains('hello') || lowerText.contains('hi') || lowerText.contains('hey')) {
      _showCommandFeedback('Hello! How can I help you?');
    }
    else if (lowerText.contains('time')) {
      final now = DateTime.now();
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      _showCommandFeedback('Current time is $hour:$minute');
    }
    else if (lowerText.contains('date')) {
      final now = DateTime.now();
      _showCommandFeedback('Today is ${now.day}/${now.month}/${now.year}');
    }
    else if (lowerText.contains('who are you') || lowerText.contains('your name')) {
      _showCommandFeedback('I am Astra, your voice companion');
    }
    else if (lowerText.contains('how are you')) {
      _showCommandFeedback('I am doing great! Ready to help you.');
    }
    else if (lowerText.contains('thank')) {
      _showCommandFeedback('You are welcome!');
    }
    else {
      // For any other command, just acknowledge
      if (text.length > 3) {
        _showCommandFeedback('You said: "$text"');
      }
    }
  }

  // Show command feedback snackbar
  void _showCommandFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.neonPink,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Mic button handlers
  void _onMicTapDown(TapDownDetails details) {
    if (!_hasPermission) {
      _requestPermission();
      return;
    }
    _startListening();
  }

  void _onMicTapUp(TapUpDetails details) {
    _stopListening();
  }

  void _onMicTapCancel() {
    _stopListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundGradient(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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

  Decoration _buildBackgroundGradient() {
    return BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          AppColors.neonPinkWithOpacity(0.15),
          Colors.black,
          Colors.black,
        ],
        stops: const [0.2, 0.7, 1.0],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 40),
        _buildLogo(),
        const SizedBox(height: 16),
        _buildTagline(),
      ],
    );
  }

  Widget _buildLogo() {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [AppColors.lightPink, AppColors.neonPink],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: const Text(
        'ASTRA',
        style: TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.bold,
          letterSpacing: 8,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Text(
      'Your personal voice companion',
      style: TextStyle(
        fontSize: 18,
        color: AppColors.neonPinkWithOpacity(0.9),
        letterSpacing: 2,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  Widget _buildCenterContent() {
    return Column(
      children: [
        const SizedBox(height: 40),
        _buildVoiceCircle(),
        const SizedBox(height: 30),

        // Recognized Text Display
        if (_recognizedText.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neonPinkWithOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  _isListening ? 'Listening...' : 'You said:',
                  style: TextStyle(
                    color: _isListening ? AppColors.neonPink : Colors.grey[400],
                    fontSize: 14,
                    fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _recognizedText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Recent Commands
        if (_recentCommands.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent commands:',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    if (_recentCommands.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _recentCommands.clear();
                          });
                        },
                        child: Icon(
                          Icons.clear_all,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._recentCommands.take(3).map((cmd) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $cmd',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ],
            ),
          ),
        ],

        const SizedBox(height: 30),
        _buildFeatures(),
      ],
    );
  }

  Widget _buildVoiceCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.neonPinkWithOpacity(0.3),
                AppColors.neonPinkWithOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Middle circle with wave animation
        if (_isListening)
          const VoiceWave(),

        // Mic button
        _buildMicButton(),

        //permission indicatorr
        if (_isChecking)
          const Positioned(
            bottom: 0,
            child: CircularProgressIndicator(
              color: AppColors.neonPink,
              strokeWidth: 2,
            ),
          ),

        if (!_hasPermission && !_isChecking)
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: const Text(
                'Permission Required',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // Speech not available indicator
        if (_hasPermission && !_speechEnabled && !_isChecking)
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: const Text(
                'Initializing...',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  //mic button
  Widget _buildMicButton() {
    return GestureDetector(
      onTapDown: _onMicTapDown,
      onTapUp: _onMicTapUp,
      onTapCancel: _onMicTapCancel,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _hasPermission
              ? (_isListening
              ? AppColors.neonPink.withOpacity(0.3)
              : AppColors.neonPinkWithOpacity(0.2))
              : Colors.grey.withOpacity(0.2),
          boxShadow: _hasPermission && _isListening
              ? [
            BoxShadow(
              color: AppColors.neonPinkWithOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ]
              : null,
        ),
        child: Icon(
          _isListening
              ? Icons.mic
              : (_hasPermission ? Icons.mic : Icons.mic_off),
          size: 60,
          color: _isListening
              ? Colors.white
              : (_hasPermission ? AppColors.neonPink : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    return Column(
      children: [
        // Voice commands chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.neonPinkWithOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            _isListening
                ? 'Listening... Speak now'
                : 'Voice commands, powered by Astra',
            style: TextStyle(
              fontSize: 16,
              color: _isListening ? AppColors.neonPink : Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Main motto
        Text(
          'Astra - Speak. Listen. Achieve.',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.neonPink,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: AppColors.neonPinkWithOpacity(0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(
          color: AppColors.neonPink,
          thickness: 0.5,
          indent: 50,
          endIndent: 50,
        ),
        const SizedBox(height: 20),

        // Status indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getStatusText(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ],
        ),


        const SizedBox(height: 20),
      ],
    );
  }

  Color _getStatusColor() {
    if (_isChecking) return Colors.grey;
    if (!_hasPermission) return Colors.red;
    if (!_speechEnabled) return Colors.orange;
    if (_isListening) return Colors.green;
    return AppColors.neonPink;
  }

  String _getStatusText() {
    if (_isChecking) return 'Checking permissions...';
    if (!_hasPermission) return 'Microphone access required';
    if (!_speechEnabled) return 'Initializing speech...';
    if (_isListening) return 'Listening for "Hey Astra"...';
    return 'Tap mic to speak';
  }
}

//appp colors
class AppColors {
  static const neonPink = Color(0xFF1457FF);
  static const lightPink = Color(0xFF68C0E6);

  static Color neonPinkWithOpacity(double opacity) => neonPink.withOpacity(opacity);
  static Color lightPinkWithOpacity(double opacity) => lightPink.withOpacity(opacity);
}
*/