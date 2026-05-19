#include <flutter/runtime_effect.glsl>

// uSampler: the icon widget's rendered texture (setImageSampler(0, image)).
uniform sampler2D uSampler;
// uWidth / uHeight: canvas dimensions in logical pixels.
uniform float uWidth;
uniform float uHeight;
// uGlowR, uGlowG, uGlowB: accent colour for the halo.
uniform float uGlowR;
uniform float uGlowG;
uniform float uGlowB;
// uRadius: glow spread radius in pixels (0 = no glow).
uniform float uRadius;
// uIntensity: peak opacity multiplier for the halo (0–1).
uniform float uIntensity;

out vec4 fragColor;

void main() {
  vec2 fc = FlutterFragCoord().xy;
  vec2 uv = fc / vec2(uWidth, uHeight);

  // Sample the source icon at the current pixel (premultiplied).
  vec4 src = texture(uSampler, uv);

  // Approximate glow: sample the icon at 8 neighbouring offsets
  // and accumulate the alpha.  The neighbourhood is scaled by uRadius.
  float step = uRadius / 4.0;
  float glowAlpha = 0.0;
  vec2 offsets[8];
  offsets[0] = vec2( step,  0.0);
  offsets[1] = vec2(-step,  0.0);
  offsets[2] = vec2( 0.0,  step);
  offsets[3] = vec2( 0.0, -step);
  offsets[4] = vec2( step,  step) * 0.707;
  offsets[5] = vec2(-step,  step) * 0.707;
  offsets[6] = vec2( step, -step) * 0.707;
  offsets[7] = vec2(-step, -step) * 0.707;

  for (int i = 0; i < 8; i++) {
    vec2 sampleUv = uv + offsets[i] / vec2(uWidth, uHeight);
    glowAlpha += texture(uSampler, sampleUv).a;
  }
  glowAlpha /= 8.0;

  // Smooth falloff: glow is strongest near opaque icon pixels.
  float halo = glowAlpha * uIntensity * (1.0 - src.a);

  // Premultiplied halo composite under the source icon.
  vec3 glowCol = vec3(uGlowR, uGlowG, uGlowB) * halo;
  vec4 glowLayer = vec4(glowCol, halo);

  // Porter-Duff src-over: icon on top of glow.
  fragColor = src + glowLayer * (1.0 - src.a);
}
