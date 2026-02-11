import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech service for read-aloud functionality.
///
/// Wraps the flutter_tts plugin, providing chapter-by-chapter reading
/// with adjustable voice, rate, and pitch.
class TTSService {
  final FlutterTts _tts = FlutterTts();

  bool get isSpeaking => _isSpeaking;
  bool _isSpeaking = false;

  double get rate => _rate;
  double _rate = 0.5;

  double get pitch => _pitch;
  double _pitch = 1.0;

  /// Initialize TTS engine with default settings.
  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });
  }

  /// Speak the given text.
  Future<void> speak(String text) async {
    _isSpeaking = true;
    await _tts.speak(text);
  }

  /// Stop speaking.
  Future<void> stop() async {
    _isSpeaking = false;
    await _tts.stop();
  }

  /// Pause speaking.
  Future<void> pause() async {
    _isSpeaking = false;
    await _tts.pause();
  }

  /// Set speech rate (0.0 to 1.0).
  Future<void> setRate(double rate) async {
    _rate = rate;
    await _tts.setSpeechRate(rate);
  }

  /// Set pitch (0.5 to 2.0).
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _tts.setPitch(pitch);
  }

  /// Get available voices/languages.
  Future<List<dynamic>> getVoices() async {
    return await _tts.getVoices ?? [];
  }

  /// Release resources.
  Future<void> dispose() async {
    await _tts.stop();
  }
}
