import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;

  VoiceService() {
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
  }

  Future<bool> initialize() async {
    try {
      // Initialize TTS
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);

      // ✅ FIX: Karen voice को हटाओ, default use करो
      // या फिर en-US-x-sfg-network use करो (जो पहले काम कर रहा था)
      try {
        var voices = await _tts.getVoices;
        for (var voice in voices) {
          String name = voice['name'].toString().toLowerCase();
          if (name.contains('female') || name.contains('en-us-x-sfg')) {
            await _tts.setVoice(voice);
            break;
          }
        }
      } catch (e) {
        print('Voice selection error: $e');
      }

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((error) {
        print('TTS Error: $error');
        _isSpeaking = false;
      });

      try {
        await _tts.setVoice({"name": "en-us-x-sfg-network", "locale": "en-US"});
      } catch (e) {
        print('Voice selection error: $e');
      }

      // Initialize Speech
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (error) {
          print('Speech error: ${error.errorMsg}');
          _isListening = false;
        },
      );

      return _isInitialized;
    } catch (e) {
      print('Voice service init error: $e');
      return false;
    }
  }

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;

  Future<void> startListening(Function(String) onResult) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isListening) {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,  // ✅ true करो
        localeId: 'en_US',
      );
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      await _speech.stop();
    }
  }

  Future<void> speak(String text) async {
    try {
      if (!_isSpeaking) {
        _isSpeaking = true;
        await _tts.speak(text);
      }
    } catch (e) {
      print('Speak error: $e');
      _isSpeaking = false;
    }
  }

  void dispose() {
    _speech.stop();
    _tts.stop();
  }
}