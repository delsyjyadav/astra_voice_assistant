import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class TestSpeechScreen extends StatefulWidget {
  const TestSpeechScreen({super.key});

  @override
  State<TestSpeechScreen> createState() => _TestSpeechScreenState();
}

class _TestSpeechScreenState extends State<TestSpeechScreen> {
  final SpeechToText _speech = SpeechToText();
  String _lastWords = '';
  bool _isListening = false;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _isAvailable = await _speech.initialize(
      onStatus: (status) {
        print('🎤 Test Status: $status');
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        print('🎤 Test Error: ${error.errorMsg}');
        setState(() => _isListening = false);
      },
    );

    setState(() {});
    print('🎤 Test Available: $_isAvailable');
  }

  void _startListening() {
    if (!_isAvailable) return;

    setState(() => _isListening = true);
    _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        setState(() {
          _lastWords = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      localeId: 'en_US',
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Microphone Test'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isAvailable
                      ? (_isListening ? Colors.green : Colors.blue)
                      : Colors.red,
                ),
                child: Icon(
                  _isAvailable
                      ? (_isListening ? Icons.mic : Icons.mic_none)
                      : Icons.mic_off,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isAvailable
                    ? (_isListening ? 'Listening...' : 'Ready')
                    : 'Speech not available',
                style: TextStyle(
                  fontSize: 18,
                  color: _isAvailable
                      ? (_isListening ? Colors.green : Colors.blue)
                      : Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _lastWords.isEmpty
                      ? 'Say something...'
                      : 'You said: "$_lastWords"',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              if (_isAvailable)
                ElevatedButton(
                  onPressed: _isListening ? _stopListening : _startListening,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.red : Colors.green,
                    minimumSize: const Size(200, 50),
                  ),
                  child: Text(
                    _isListening ? 'Stop Listening' : 'Start Listening',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}