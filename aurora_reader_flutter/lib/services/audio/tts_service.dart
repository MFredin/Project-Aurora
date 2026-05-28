import 'tts_native.dart' if (dart.library.js_interop) 'tts_web.dart';

class TTSService {
  final TTSPlatform _platform = TTSPlatform();

  bool get isSpeaking => _platform.isSpeaking;
  double get rate => _platform.rate;
  double get pitch => _platform.pitch;

  Future<void> initialize() => _platform.initialize();
  Future<void> speak(String text) => _platform.speak(text);
  Future<void> stop() => _platform.stop();
  Future<void> pause() => _platform.pause();
  Future<void> setRate(double rate) => _platform.setRate(rate);
  Future<void> setPitch(double pitch) => _platform.setPitch(pitch);
  Future<List<dynamic>> getVoices() => _platform.getVoices();
  Future<void> dispose() => _platform.dispose();
}
