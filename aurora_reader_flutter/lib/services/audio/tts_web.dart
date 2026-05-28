import 'dart:js_interop';
import 'package:web/web.dart' as web;

class TTSPlatform {
  bool isSpeaking = false;
  double rate = 1.0;
  double pitch = 1.0;

  Future<void> initialize() async {}

  Future<void> speak(String text) async {
    stop();
    final utterance = web.SpeechSynthesisUtterance(text);
    utterance.rate = rate;
    utterance.pitch = pitch;
    utterance.lang = 'en-US';
    utterance.onend = ((web.Event e) { isSpeaking = false; }).toJS;
    isSpeaking = true;
    web.window.speechSynthesis.speak(utterance);
  }

  Future<void> stop() async {
    isSpeaking = false;
    web.window.speechSynthesis.cancel();
  }

  Future<void> pause() async {
    isSpeaking = false;
    web.window.speechSynthesis.pause();
  }

  Future<void> setRate(double r) async { rate = r; }
  Future<void> setPitch(double p) async { pitch = p; }

  Future<List<dynamic>> getVoices() async {
    return web.window.speechSynthesis.getVoices().toDart.map((v) => v).toList();
  }

  Future<void> dispose() async => stop();
}
