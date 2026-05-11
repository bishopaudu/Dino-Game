/// Tracks score milestones and drives the celebration effect.
class MilestoneSystem {
  static const int _interval = 500; // celebrate every 500 points

  int _lastMilestone = 0;

  /// How long the celebration text has been showing (counts down).
  double celebrationTimer = 0.0;
  static const double celebrationDuration = 1.2;

  /// The milestone score being celebrated (shown in the text).
  int celebrationScore = 0;

  void reset() {
    _lastMilestone = 0;
    celebrationTimer = 0;
    celebrationScore = 0;
  }

  /// Call every frame. Returns true the frame a milestone is hit.
  bool update(int score, double dt) {
    // Tick down the celebration timer
    if (celebrationTimer > 0) {
      celebrationTimer = (celebrationTimer - dt).clamp(0, celebrationDuration);
    }

    // Check if we've crossed a new milestone
    final milestone = (score ~/ _interval) * _interval;
    if (milestone > 0 && milestone != _lastMilestone) {
      _lastMilestone = milestone;
      celebrationScore = milestone;
      celebrationTimer = celebrationDuration;
      return true;
    }
    return false;
  }

  bool get isCelebrating => celebrationTimer > 0;

  /// Opacity for the celebration text — fades in then out.
  double get celebrationOpacity {
    if (celebrationTimer <= 0) return 0;
    final t = celebrationTimer / celebrationDuration;
    // Fade in quickly, hold, then fade out
    if (t > 0.8) return (1.0 - t) / 0.2;   // fade in (last 20% of countdown = first 20% of display)
    if (t < 0.2) return t / 0.2;            // fade out
    return 1.0;                              // full opacity
  }
}