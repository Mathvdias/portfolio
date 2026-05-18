#include <flutter/runtime_effect.glsl>

uniform float uElapsed;
uniform float uWidth;
uniform float uHeight;

out vec4 fragColor;

// Fast deterministic hash — same seed as Dart's Random(42) is irrelevant;
// visual output is statistically identical (70 pseudo-random particles).
float h1(float n) {
  return fract(sin(n) * 43758.5453);
}

// Catppuccin Mocha: blue, green, mauve, peach, teal
vec3 palette(float t) {
  if (t < 0.2) return vec3(0.537, 0.706, 0.980); // blue  #89B4FA
  if (t < 0.4) return vec3(0.651, 0.890, 0.631); // green #A6E3A1
  if (t < 0.6) return vec3(0.796, 0.651, 0.969); // mauve #CBA6F7
  if (t < 0.8) return vec3(0.980, 0.702, 0.529); // peach #FAB387
  return         vec3(0.580, 0.886, 0.835);       // teal  #94E2D5
}

void main() {
  vec2 fc = FlutterFragCoord().xy;
  fragColor = vec4(0.0);

  for (int i = 0; i < 70; i++) {
    float fi = float(i);

    float px    = h1(fi * 1.1 + 0.5) * uWidth;
    float phase = h1(fi * 2.3 + 0.5);
    float speed = 0.012 + h1(fi * 3.7 + 0.5) * 0.025;
    float sz    = floor(h1(fi * 5.1 + 0.5) * 3.0) + 1.0;
    float alpha = 0.15 + h1(fi * 7.3 + 0.5) * 0.3;

    float py = mod(phase + uElapsed * speed, 1.0) * uHeight;

    if (fc.x >= px && fc.x < px + sz && fc.y >= py && fc.y < py + sz) {
      vec3 col = palette(h1(fi * 9.7 + 0.5));
      // Premultiplied alpha output (required by CanvasKit).
      fragColor = vec4(col * alpha, alpha);
      break;
    }
  }
}
