#include <flutter/runtime_effect.glsl>

// uSampler: the widget's rendered texture (set by setImageSampler(0, image)).
uniform sampler2D uSampler;
// uPixels: quantisation grid size in cells (1.0 = no effect, 12.0 = chunky).
uniform float uPixels;
// uWidth / uHeight: logical dimensions of the sampled region in pixels.
uniform float uWidth;
uniform float uHeight;

out vec4 fragColor;

void main() {
  vec2 fc = FlutterFragCoord().xy;

  // Snap each coordinate to the nearest cell centre.
  float cellW = uWidth  / uPixels;
  float cellH = uHeight / uPixels;
  float snappedX = (floor(fc.x / cellW) + 0.5) * cellW;
  float snappedY = (floor(fc.y / cellH) + 0.5) * cellH;

  // Convert to normalised [0,1] UV and sample the source texture.
  vec2 uv = vec2(snappedX / uWidth, snappedY / uHeight);
  fragColor = texture(uSampler, uv);
}
