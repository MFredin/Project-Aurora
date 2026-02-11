import 'package:just_audio/just_audio.dart';

/// Manages ambient background soundscapes for immersive reading.
///
/// Plays looping audio tracks (rain, fireplace, coffee shop, etc.)
/// with volume control and crossfade between soundscapes.
class AmbientService {
  final AudioPlayer _player = AudioPlayer();

  String? get currentSoundscape => _currentSoundscape;
  String? _currentSoundscape;

  bool get isPlaying => _player.playing;

  double get volume => _player.volume;

  /// Available soundscape names.
  static const List<String> soundscapes = [
    'Rain',
    'Thunderstorm',
    'Fireplace',
    'Coffee Shop',
    'Forest',
    'Ocean Waves',
    'Library',
    'Night Crickets',
    'Wind',
    'River Stream',
  ];

  /// Start playing a soundscape by name.
  Future<void> play(String soundscape) async {
    // TODO: Load audio asset for the given soundscape
    _currentSoundscape = soundscape;
    await _player.setLoopMode(LoopMode.one);
    // await _player.setAsset('assets/audio/$soundscape.mp3');
    // await _player.play();
  }

  /// Stop playback.
  Future<void> stop() async {
    await _player.stop();
    _currentSoundscape = null;
  }

  /// Pause playback.
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resume playback.
  Future<void> resume() async {
    await _player.play();
  }

  /// Set volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Release resources.
  Future<void> dispose() async {
    await _player.dispose();
  }
}
