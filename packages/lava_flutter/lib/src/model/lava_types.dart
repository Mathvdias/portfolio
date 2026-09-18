/// Represents the current playback status of a Lava animation.
enum LavaPlaybackStatus {
  /// The animation is stopped and positioned at the initial frame.
  stopped,

  /// The animation is actively ticking and playing frames.
  playing,

  /// The animation is paused at the current frame.
  paused,

  /// The non-looping animation reached its final frame.
  completed,
}

/// Represents the interaction state for tactile 3D feedback.
enum LavaInteractiveState {
  /// Default resting state.
  idle,

  /// Pointer is hovering over the icon (3D perspective tilt active).
  hover,

  /// Pointer is actively pressing the icon (spring compression active).
  pressed,
}

/// Built-in procedural 3D demo icon types.
enum LavaDemoType {
  /// Classic 1984 Macintosh 128K with glowing phosphor CRT screen, scanlines, and retro badge.
  macintosh,

  /// Stylized procedural 3D nature tree with foliage canopy puffs, wind sway physics, and ruby apples.
  tree,
}
