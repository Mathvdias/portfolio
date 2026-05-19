#include <flutter/runtime_effect.glsl>

// uSampler: the composited desktop rendered as a texture.
uniform sampler2D uSampler;
// uWidth / uHeight: canvas dimensions in logical pixels.
uniform float uWidth;
uniform float uHeight;
// uElapsed: seconds since start (drives scanline flicker).
uniform float uElapsed;
// uIntensity: overall CRT effect strength 0.0–1.0.
uniform float uIntensity;

out vec4 fragColor;

void main() {
  vec2 fc    = FlutterFragCoord().xy;
  vec2 uv    = fc / vec2(uWidth, uHeight);

  // --- Slight barrel distortion ---
  vec2 cUv = uv * 2.0 - 1.0;
  float barrel = 0.03 * uIntensity;
  cUv *= 1.0 + barrel * dot(cUv, cUv);
  vec2 distUv = cUv * 0.5 + 0.5;

  // Sample with mild chromatic aberration on the distorted UV.
  float aberr = 0.003 * uIntensity;
  float r = texture(uSampler, distUv + vec2( aberr,  0.0)).r;
  float g = texture(uSampler, distUv).g;
  float b = texture(uSampler, distUv + vec2(-aberr,  0.0)).b;
  float a = texture(uSampler, distUv).a;

  // Clamp: outside barrel distortion → black.
  float inside = step(0.0, distUv.x) * step(distUv.x, 1.0)
               * step(0.0, distUv.y) * step(distUv.y, 1.0);
  vec4 src = vec4(r, g, b, a) * inside;

  // --- Scanlines ---
  float lineFreq  = 2.0;
  float lineDark  = 0.12 * uIntensity;
  float scanline  = sin(fc.y * lineFreq * 3.14159) * 0.5 + 0.5;
  float lineAlpha = 1.0 - lineDark * (1.0 - scanline);

  // Slow flicker: subtle brightness pulse.
  float flicker = 1.0 - 0.015 * uIntensity * sin(uElapsed * 37.3);

  // --- Vignette ---
  vec2 vUv = uv * 2.0 - 1.0;
  float vignette = 1.0 - smoothstep(0.55, 1.05, length(vUv) * (1.0 + 0.25 * uIntensity));

  // Compose: source * scanline * flicker * vignette.
  vec3 col = src.rgb * lineAlpha * flicker * vignette;
  fragColor = vec4(col, src.a);
}
