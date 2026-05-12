import 'package:audioplayers/audioplayers.dart';
import 'storage_service.dart';

/// Manages all game audio.
/// 
/// Architecture decisions:
/// - Singleton so any system can trigger sounds without passing references
/// - Pre-loaded AudioPlayers for zero-latency playback
/// - Silently skips playback when sound is disabled — no if-checks at call sites
/// - Separate player per sound so overlapping sounds work correctly
///   (e.g. milestone sound can play over a jump sound)
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // One player per sound effect.
  // Using separate players means sounds can overlap without cutting each other off.
  final AudioPlayer _jumpPlayer      = AudioPlayer();
  final AudioPlayer _diePlayer       = AudioPlayer();
  final AudioPlayer _milestonePlayer = AudioPlayer();
  final AudioPlayer _pointPlayer     = AudioPlayer();
  final AudioPlayer _buttonPlayer    = AudioPlayer();

  bool _soundEnabled   = true;
  bool _isInitialized  = false;

  bool get soundEnabled => _soundEnabled;

  /// Call once at app startup. Loads all audio into memory.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load saved preference
    _soundEnabled = await StorageService.loadSoundEnabled();

    // Pre-load all audio files into memory.
    // ReleaseMode.stop means the sound stops at the end (not loop).
    await _jumpPlayer.setSource(AssetSource('audio/jump.mp3'));
    await _diePlayer.setSource(AssetSource('audio/die.mp3'));
    await _milestonePlayer.setSource(AssetSource('audio/milestone.mp3'));
    await _pointPlayer.setSource(AssetSource('audio/point.mp3'));
    await _buttonPlayer.setSource(AssetSource('audio/button.mp3'));

    for (final player in _allPlayers) {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.6);
    }

    _isInitialized = true;
  }

  List<AudioPlayer> get _allPlayers => [
    _jumpPlayer, _diePlayer, _milestonePlayer, _pointPlayer, _buttonPlayer,
  ];

  // ── Playback ───────────────────────────────────────────────

  /// Plays the jump sound. Called when dino jumps.
  Future<void> playJump() => _play(_jumpPlayer);

  /// Plays the death sound. Called on game over.
  Future<void> playDie() => _play(_diePlayer);

  /// Plays the milestone sound. Called every 500 points.
  Future<void> playMilestone() => _play(_milestonePlayer);

  /// Plays the score tick. Called periodically while playing.
  Future<void> playPoint() => _play(_pointPlayer);

  /// Plays the UI button click sound.
  Future<void> playButton() => _play(_buttonPlayer);

  /// Core play method. Stops any current playback on that player
  /// then plays from the beginning — ensures snappy response.
  Future<void> _play(AudioPlayer player) async {
    if (!_soundEnabled || !_isInitialized) return;
    try {
      await player.stop();
      await player.resume();
    } catch (_) {
      // Never let audio errors crash the game
    }
  }

  // ── Settings ───────────────────────────────────────────────

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await StorageService.saveSoundEnabled(enabled);
    if (!enabled) {
      // Stop any currently playing sounds immediately
      for (final player in _allPlayers) {
        await player.stop();
      }
    }
  }

  Future<void> dispose() async {
    for (final player in _allPlayers) {
      await player.dispose();
    }
  }
}