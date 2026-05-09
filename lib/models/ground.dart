/// Manages the infinite scrolling ground state.
/// 
/// We only store a single offset value. The renderer uses
/// modulo arithmetic to draw infinite tiles from this one number.
class Ground {
  /// How far the ground has scrolled in total (pixels).
  /// Increases every frame. The renderer wraps this with modulo.
  double scrollOffset;

  Ground({this.scrollOffset = 0});
}