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

  Future<bool> initialize() async{
    try {

      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);


      try {
        await _tts.setVoice({"name": "en-us-x-sfg-network", "locale": "en-US"});
        print("Voice set to en-us-x-sfg-network");
      } catch (e) {
        print("Could not set specific voice, using default");
      }

      _tts.setCompletionHandler((){
        _isSpeaking = false;
      });

      _tts.setErrorHandler((error){
        print('TTS Error: $error');
        _isSpeaking = false;
      });


      _isInitialized = await _speech.initialize(
        onStatus: (status){
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (error){
          print('Speech error: ${error.errorMsg}');
          _isListening = false;
        },
      );

      return _isInitialized;
    } catch (e){
      print('Voice service init error: $e');
      return false;
    }
  }

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;

  Future<void> startListening(Function(String) onResult) async{
    if (!_isInitialized){
      await initialize();
    }

    if (!_isListening) {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {

          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,

        localeId: 'en_US',
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
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

  void dispose(){
    _speech.stop();
    _tts.stop();
  }
}