import 'package:flutter/services.dart';
import 'storage_service.dart';

/// Manages haptic feedback throughout the game.
/// 
/// Wraps Flutter's HapticFeedback with a preference toggle.
/// Call sites never need to check the toggle themselves.
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _hapticsEnabled = true;
  bool get hapticsEnabled => _hapticsEnabled;

  Future<void> initialize() async {
    _hapticsEnabled = await StorageService.loadHapticsEnabled();
  }

  /// Light tap — used for jumps and button presses.
  Future<void> lightTap() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Heavy impact — used for death/collision.
  Future<void> heavyImpact() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Subtle vibration — used for milestone celebrations.
  Future<void> mediumTap() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    _hapticsEnabled = enabled;
    await StorageService.saveHapticsEnabled(enabled);
  }
}