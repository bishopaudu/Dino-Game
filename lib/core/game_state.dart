/// Defines every possible state the game can be in.
/// This is a state machine - only valid transitions are allowed.
enum GameState {
  /// Waiting for the player to start.
  initial,
 paused,
  /// The game is actively running.
  playing,

  /// The player has collided - show game over screen.
  gameOver,
}