import 'package:flutter_tts/flutter_tts.dart';

class TtsHandler {
  late FlutterTts flutterTts;

  TtsHandler() {
    flutterTts = FlutterTts();
  }

  Future<void> initTts() async {


    try {
      await flutterTts.setLanguage('en-US');

      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setPitch(1.0);
      await flutterTts.setVolume(1.0);
    } catch (e) {
      print('TTS init error: $e');
    }
  }

  Future<void> setFemaleVoice() async {
    try {
      var voices = await flutterTts.getVoices;
      if (voices.isNotEmpty) {
        // Convert to proper type
        List<Map<String, String>> voiceList = [];

        for (var voice in voices) {
          // Safely convert each voice to Map<String, String>
          Map<String, String> convertedVoice = {};
          voice.forEach((key, value) {
            convertedVoice[key.toString()] = value.toString();
          });
          voiceList.add(convertedVoice);
        }

        // Try to find female voice
        for (var voice in voiceList) {
          String name = voice['name']?.toLowerCase() ?? '';
          if (name.contains('female') || name.contains('en-us-x-sfg')) {
            await flutterTts.setVoice(voice);
            print('✅ Female voice set: $name');
            return;
          }
        }

        // If no female voice, use first available
        if (voiceList.isNotEmpty) {
          await flutterTts.setVoice(voiceList.first);
          print('✅ Voice set: ${voiceList.first['name']}');
        }
      }
    } catch (e) {
      print('❌ Voice set error: $e');
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      await flutterTts.speak(text);
      print('🔊 Speaking: $text');
    } catch (e) {
      print('❌ TTS Error: $e');
    }
  }

  Future<void> stop() async {
    await flutterTts.stop();
  }

  Future<void> dispose() async {
    await flutterTts.stop();
  }
}