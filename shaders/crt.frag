#include <flutter/runtime_effect.glsl>

// Pure overlay — no image sampler needed.
// Draws a dark semi-transparent layer with scanlines, vignette, and flicker
// that composites on top of the desktop via Porter-Duff src-over.
uniform float uWidth;
uniform float uHeight;
uniform float uElapsed;
// uIntensity: 0.0 = invisible, 1.0 = full CRT feel
uniform float uIntensity;

out vec4 fragColor;

void main() {
  vec2 fc = FlutterFragCoord().xy;
  vec2 uv = fc / vec2(uWidth, uHeight);

  // --- Scanlines: alternating dark/light bands every 2 px ---
  float line  = step(0.5, fract(fc.y * 0.5));   // 0 or 1, 2-px period
  float dark  = 1.0 - 0.18 * uIntensity * line; // dim every other line

  // --- Slow flicker ---
  float flicker = 1.0 - 0.018 * uIntensity * sin(uElapsed * 31.7);

  // --- Radial vignette ---
  vec2 vp = uv * 2.0 - 1.0;
  float vig = 1.0 - smoothstep(0.45, 1.1, length(vp) * (1.0 + 0.3 * uIntensity));

  // darkness = how much we darken; 0 = transparent, 1 = fully black
  float darkness = (1.0 - dark * flicker * vig) * uIntensity;

  // Premultiplied black overlay: composites via src-over on top of desktop.
  fragColor = vec4(0.0, 0.0, 0.0, darkness);
}
