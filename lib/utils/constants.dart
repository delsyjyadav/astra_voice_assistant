class Constants {
  // ✅ WINDOWS - cmd में `ipconfig` चलाकर IPv4 Address देखो
  // उदाहरण: 192.168.1.104, 192.168.1.103, 192.168.29.78 etc.
  static const String baseUrl = 'http://192.168.1.104:8000';  // ← अपना IP

  // ❌ Emulator वाला मत डालो
  // static const String baseUrl = 'http://10.0.2.2:8000';

  static const String appName = 'ASTRA Voice Assistant';
  static const String wakeWord = 'hey astra';

  static const String chatEndpoint = '/api/v1/chat';
  static const String healthEndpoint = '/api/v1/health';
}