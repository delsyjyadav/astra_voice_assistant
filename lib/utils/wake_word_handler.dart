import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class WakeWordHandler {
  final SpeechToText _speech = SpeechToText();
  bool _isListeningForWake = false;

  final Function() onWakeWordDetected;
  final Function(String) onPartialText;
  final Function(String) onError;

  WakeWordHandler({
    required this.onWakeWordDetected,
    required this.onPartialText,
    required this.onError,
  });

  Future<void> startListeningForWake() async {
    if (_isListeningForWake) return;

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          print('Wake status: $status');
          if (status == 'done' || status == 'notListening') {
            if (_isListeningForWake) {
              Future.delayed(const Duration(milliseconds: 500), () {
                _startWakeListening();
              });
            }
          }
        },
        onError: (error) {
          print('Wake error: $error');
          if (_isListeningForWake) {
            Future.delayed(const Duration(seconds: 2), () {
              _startWakeListening();
            });
          }
        },
      );

      if (available) {
        _isListeningForWake = true;
        _startWakeListening();
      }
    } catch (e) {
      print('Wake init error: $e');
    }
  }

  void _startWakeListening() async {
    if (!_isListeningForWake) return;

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: true,
      );
    } catch (e) {
      print('Wake listen error: $e');
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.toLowerCase();

    if (text.isNotEmpty) {
      onPartialText.call(text);
    }

    if (_containsWakeWord(text)) {
      _stopWakeListening();
      onWakeWordDetected.call();
    }

    if (result.finalResult && _isListeningForWake) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _startWakeListening();
      });
    }
  }

  bool _containsWakeWord(String text) {
    final wakeWords = ['hey astra', 'hello astra', 'hi astra', 'astra'];
    return wakeWords.any((word) => text.contains(word));
  }

  Future<void> _stopWakeListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      print('Error stopping wake: $e');
    }
  }

  Future<void> stopListeningForWake() async {
    _isListeningForWake = false;
    await _speech.stop();
  }

  Future<void> pauseListening() async {
    _isListeningForWake = false;
    await _speech.stop();
  }

  void resumeListening() {
    if (!_isListeningForWake) {
      _isListeningForWake = true;
      _startWakeListening();
    }
  }

  void dispose() {
    _speech.stop();
  }
}