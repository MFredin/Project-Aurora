import 'package:flutter_tts/flutter_tts.dart';

class TTSPlatform {
  final FlutterTts _tts = FlutterTts();
  bool isSpeaking = false;
  double rate = 0.5;
  double pitch = 1.0;

  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    _tts.setCompletionHandler(() { isSpeaking = false; });
  }

  Future<void> speak(String text) async {
    isSpeaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    isSpeaking = false;
    await _tts.stop();
  }

  Future<void> pause() async {
    isSpeaking = false;
    await _tts.pause();
  }

  Future<void> setRate(double r) async {
    rate = r;
    await _tts.setSpeechRate(r);
  }

  Future<void> setPitch(double p) async {
    pitch = p;
    await _tts.setPitch(p);
  }

  Future<List<dynamic>> getVoices() async => await _tts.getVoices ?? [];
  Future<void> dispose() async => await _tts.stop();
}
