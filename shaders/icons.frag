#include <flutter/runtime_effect.glsl>

// ─── Uniforms ─────────────────────────────────────────────────────────────────
uniform float uSize;
uniform float uRed;
uniform float uGreen;
uniform float uBlue;
uniform float uShape;

out vec4 fragColor;

// Star constants at global scope (avoids local-const depth issues).
const vec2 _sk1 = vec2(0.809016994375, -0.587785252192);
const vec2 _sk2 = vec2(-0.809016994375, -0.587785252192);

// ─── Primitives ───────────────────────────────────────────────────────────────

float sdCircle(vec2 p, float r) { return length(p) - r; }

float sdBox(vec2 p, vec2 b) {
  vec2 d = abs(p) - b;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdRBox(vec2 p, vec2 b, float r) {
  vec2 d = abs(p) - b + r;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

float sdSeg(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

// step()-based arc avoids the ternary operator that inflates SPIRV-Cross depth.
float sdArc(vec2 p, vec2 sc, float r, float w) {
  p.x = abs(p.x);
  float cond = step(0.0, sc.y * p.x - sc.x * p.y);
  float k = mix(length(p), dot(p, sc), cond);
  return sqrt(max(dot(p, p) + r * r - 2.0 * r * k, 0.0)) - w;
}

float sdTri(vec2 p, vec2 a, vec2 b, vec2 c) {
  vec2 e0 = b - a; vec2 e1 = c - b; vec2 e2 = a - c;
  vec2 v0 = p - a; vec2 v1 = p - b; vec2 v2 = p - c;
  vec2 pq0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
  vec2 pq1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
  vec2 pq2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);
  float s = sign(e0.x * e2.y - e0.y * e2.x);
  vec2 d0 = vec2(dot(pq0, pq0), s * (v0.x * e0.y - v0.y * e0.x));
  vec2 d1 = vec2(dot(pq1, pq1), s * (v1.x * e1.y - v1.y * e1.x));
  vec2 d2 = vec2(dot(pq2, pq2), s * (v2.x * e2.y - v2.y * e2.x));
  vec2 dm = min(min(d0, d1), d2);
  return -sqrt(dm.x) * sign(dm.y);
}

// ─── Icon SDFs ────────────────────────────────────────────────────────────────
// Rules: (a) sequential min/max — no nested calls in return;
//        (b) unused slots return sdCircle(p,0.40) to keep the switch flat.

float s0(vec2 p) { // person
  float d = sdCircle(p - vec2(0.0, 0.22), 0.16);
  d = min(d, sdRBox(p - vec2(0.0, -0.10), vec2(0.18, 0.20), 0.08));
  return d;
}

float s1(vec2 p) { // folder
  float d = sdRBox(p - vec2(0.0, -0.06), vec2(0.42, 0.26), 0.04);
  d = min(d, sdRBox(p - vec2(-0.20, 0.22), vec2(0.14, 0.06), 0.03));
  return d;
}

float s2(vec2 p) { // star (IQ 5-point)
  float r = 0.40;
  float rf = 0.44;
  p.x = abs(p.x);
  p -= 2.0 * max(dot(_sk1, p), 0.0) * _sk1;
  p -= 2.0 * max(dot(_sk2, p), 0.0) * _sk2;
  p.x = abs(p.x);
  p.y -= r;
  vec2 ba = rf * vec2(-_sk1.y, _sk1.x) - vec2(0.0, 1.0);
  float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
  return length(p - ba * h) * sign(p.x * ba.y - p.y * ba.x);
}

float s3(vec2 p) { // terminal  >_
  float d = sdSeg(p, vec2(-0.32,  0.14), vec2(-0.10,  0.0));
  d = min(d, sdSeg(p, vec2(-0.10,  0.0),  vec2(-0.32, -0.14)));
  d = min(d, sdSeg(p, vec2(-0.02, -0.14), vec2( 0.28, -0.14)));
  return d - 0.032;
}

float s4(vec2 p) { // calculator  (loop unrolled → no for loop)
  float d = sdRBox(p, vec2(0.34, 0.42), 0.07);
  float disp = sdRBox(p - vec2(0.0, 0.22), vec2(0.26, 0.12), 0.04);
  d = max(d, -disp);
  d = min(d, sdCircle(p - vec2(-0.16,  0.04), 0.04));
  d = min(d, sdCircle(p - vec2( 0.00,  0.04), 0.04));
  d = min(d, sdCircle(p - vec2( 0.16,  0.04), 0.04));
  d = min(d, sdCircle(p - vec2(-0.16, -0.10), 0.04));
  d = min(d, sdCircle(p - vec2( 0.00, -0.10), 0.04));
  d = min(d, sdCircle(p - vec2( 0.16, -0.10), 0.04));
  d = min(d, sdCircle(p - vec2(-0.16, -0.24), 0.04));
  d = min(d, sdCircle(p - vec2( 0.00, -0.24), 0.04));
  d = min(d, sdCircle(p - vec2( 0.16, -0.24), 0.04));
  d = min(d, sdCircle(p - vec2(-0.16, -0.38), 0.04));
  d = min(d, sdCircle(p - vec2( 0.00, -0.38), 0.04));
  d = min(d, sdCircle(p - vec2( 0.16, -0.38), 0.04));
  return d;
}

float s5(vec2 p) { // envelope
  float d = sdRBox(p, vec2(0.40, 0.28), 0.04);
  float v1 = sdSeg(p, vec2(-0.40, 0.28), vec2(0.0, 0.0)) - 0.025;
  float v2 = sdSeg(p, vec2( 0.40, 0.28), vec2(0.0, 0.0)) - 0.025;
  d = max(d, -v1);
  d = max(d, -v2);
  return d;
}

float s6(vec2 p) { // code  < >
  float d = sdSeg(p, vec2(-0.08, 0.0), vec2(-0.30,  0.24));
  d = min(d, sdSeg(p, vec2(-0.08, 0.0), vec2(-0.30, -0.24)));
  d = min(d, sdSeg(p, vec2( 0.08, 0.0), vec2( 0.30,  0.24)));
  d = min(d, sdSeg(p, vec2( 0.08, 0.0), vec2( 0.30, -0.24)));
  return d - 0.032;
}

float s7(vec2 p) { // book
  float d = sdRBox(p - vec2(-0.19, 0.0), vec2(0.16, 0.34), 0.04);
  d = min(d, sdRBox(p - vec2( 0.19, 0.0), vec2(0.16, 0.34), 0.04));
  d = min(d, sdBox(p, vec2(0.025, 0.34)));
  return d;
}

float s9(vec2 p) { // shield
  float top = sdRBox(p - vec2(0.0, 0.08), vec2(0.38, 0.30), 0.10);
  float bot = sdTri(p, vec2(-0.38, -0.10), vec2(0.38, -0.10), vec2(0.0, -0.46));
  return min(top, bot);
}

float s10(vec2 p) { // android
  float hc    = sdCircle(p - vec2(0.0, 0.16), 0.24);
  float hclip = sdBox(p   - vec2(0.0, -0.06), vec2(0.28, 0.12));
  float head  = max(hc, -hclip);
  float body  = sdRBox(p  - vec2(0.0, -0.16), vec2(0.26, 0.22), 0.06);
  float a1    = sdSeg(p, vec2(-0.10, 0.36), vec2(-0.20, 0.46)) - 0.025;
  float a2    = sdSeg(p, vec2( 0.10, 0.36), vec2( 0.20, 0.46)) - 0.025;
  float e1    = sdCircle(p - vec2(-0.09, 0.16), 0.04);
  float e2    = sdCircle(p - vec2( 0.09, 0.16), 0.04);
  float d     = min(head, body);
  d = min(d, a1);
  d = min(d, a2);
  d = max(d, -e1);
  d = max(d, -e2);
  return d;
}

float s11(vec2 p) { // gamepad
  float d = sdRBox(p, vec2(0.40, 0.20), 0.14);
  d = min(d, sdBox(p - vec2(-0.18, 0.0), vec2(0.12, 0.04)));
  d = min(d, sdBox(p - vec2(-0.18, 0.0), vec2(0.04, 0.12)));
  d = min(d, sdCircle(p - vec2( 0.24,  0.07), 0.055));
  d = min(d, sdCircle(p - vec2( 0.16, -0.07), 0.055));
  return d;
}

float s12(vec2 p) { // phone
  return sdRBox(p, vec2(0.18, 0.40), 0.09);
}

float s13(vec2 p) { // file / document
  float body = sdBox(p - vec2(-0.04, 0.0), vec2(0.30, 0.42));
  float clip  = sdTri(p, vec2(0.10, 0.42), vec2(0.26, 0.42), vec2(0.26, 0.26));
  float flap  = sdTri(p, vec2(0.10, 0.42), vec2(0.26, 0.26), vec2(0.10, 0.26));
  float l1    = sdBox(p - vec2(-0.06,  0.10), vec2(0.16, 0.025));
  float l2    = sdBox(p - vec2(-0.06, -0.04), vec2(0.16, 0.025));
  float l3    = sdBox(p - vec2(-0.10, -0.18), vec2(0.12, 0.025));
  body = max(body, -clip);
  body = max(body, -l1);
  body = max(body, -l2);
  body = max(body, -l3);
  return min(body, flap);
}

float s14(vec2 p) { // briefcase
  vec2 sc = vec2(sin(1.1), cos(1.1));
  float d  = sdRBox(p - vec2(0.0, -0.06), vec2(0.38, 0.26), 0.06);
  d = min(d, sdArc(p - vec2(0.0, 0.12), sc, 0.18, 0.035));
  d = min(d, sdBox(p - vec2(0.0, -0.06), vec2(0.38, 0.025)));
  return d;
}

float s15(vec2 p) { // globe
  float ring = abs(sdCircle(p, 0.38)) - 0.04;
  float heq  = sdBox(p, vec2(0.38, 0.030));
  float veq  = sdBox(p, vec2(0.030, 0.38));
  float lon  = abs(length(vec2(p.x * 1.8, p.y)) - 0.38) - 0.04;
  float d    = min(ring, heq);
  d = min(d, veq);
  d = min(d, lon);
  return d;
}

float s16(vec2 p) { // bar chart
  float d = sdBox(p - vec2(-0.24, -0.08), vec2(0.08, 0.22));
  d = min(d, sdBox(p - vec2( 0.0,  -0.02), vec2(0.08, 0.28)));
  d = min(d, sdBox(p - vec2( 0.24,  0.06), vec2(0.08, 0.20)));
  d = min(d, sdBox(p - vec2( 0.0,  -0.40), vec2(0.38, 0.030)));
  return d;
}

float s17(vec2 p) { // wifi
  vec2 ctr = vec2(0.0, -0.30);
  vec2 sc  = vec2(sin(1.10), cos(1.10));
  float d  = sdCircle(p - ctr, 0.055);
  d = min(d, sdArc(p - ctr, sc, 0.14, 0.038));
  d = min(d, sdArc(p - ctr, sc, 0.27, 0.038));
  d = min(d, sdArc(p - ctr, sc, 0.42, 0.038));
  return d;
}

float s21(vec2 p) { // rocket
  float d = sdRBox(p, vec2(0.14, 0.30), 0.10);
  d = min(d, sdTri(p, vec2(-0.14,  0.18), vec2( 0.14,  0.18), vec2( 0.0,  0.46)));
  d = min(d, sdTri(p, vec2(-0.14, -0.16), vec2(-0.28, -0.38), vec2(-0.14,-0.38)));
  d = min(d, sdTri(p, vec2( 0.14, -0.16), vec2( 0.28, -0.38), vec2( 0.14,-0.38)));
  d = min(d, sdCircle(p - vec2(0.0, -0.38), 0.07));
  return d;
}

float s23(vec2 p) { // github (simplified cat face)
  float d  = sdCircle(p - vec2(0.0, -0.02), 0.28);
  d = min(d, sdCircle(p - vec2(-0.20,  0.24), 0.12));
  d = min(d, sdCircle(p - vec2( 0.20,  0.24), 0.12));
  float e1 = sdCircle(p - vec2(-0.10, 0.04), 0.05);
  float e2 = sdCircle(p - vec2( 0.10, 0.04), 0.05);
  d = max(d, -e1);
  d = max(d, -e2);
  return d;
}

float s25(vec2 p) { // fire
  float circle = sdCircle(p + vec2(0.0, 0.10), 0.32);
  float tip    = sdTri(p, vec2(-0.22, 0.12), vec2(0.22, 0.12), vec2(0.0, 0.44));
  float k      = 0.12;
  float h      = clamp(0.5 + 0.5 * (tip - circle) / k, 0.0, 1.0);
  return mix(tip, circle, h) - k * h * (1.0 - h);
}

float s27(vec2 p) { // PDF file
  float body = sdBox(p - vec2(-0.04, 0.0), vec2(0.30, 0.42));
  float clip  = sdTri(p, vec2(0.10, 0.42), vec2(0.26, 0.42), vec2(0.26, 0.26));
  float flap  = sdTri(p, vec2(0.10, 0.42), vec2(0.26, 0.26), vec2(0.10, 0.26));
  float bar   = sdRBox(p - vec2(-0.04, -0.28), vec2(0.24, 0.08), 0.04);
  body = max(body, -clip);
  float d = min(body, flap);
  d = min(d, bar);
  return d;
}

float s28(vec2 p) { // building / columns
  float d = sdBox(p - vec2(0.0, -0.40), vec2(0.42, 0.06));
  d = min(d, sdBox(p - vec2(0.0,  0.38), vec2(0.42, 0.06)));
  d = min(d, sdBox(p - vec2(-0.28, 0.0), vec2(0.055, 0.32)));
  d = min(d, sdBox(p - vec2(-0.09, 0.0), vec2(0.055, 0.32)));
  d = min(d, sdBox(p - vec2( 0.09, 0.0), vec2(0.055, 0.32)));
  d = min(d, sdBox(p - vec2( 0.28, 0.0), vec2(0.055, 0.32)));
  return d;
}

// ─── Main ─────────────────────────────────────────────────────────────────────
// switch → OpSwitch in SPIR-V → flat SkSL switch (no if-else nesting depth).
void main() {
  vec2  p = (FlutterFragCoord().xy / uSize) - 0.5;
  int   s = int(uShape + 0.5);
  float d;

  switch (s) {
    case  0: d = s0(p);  break;
    case  1: d = s1(p);  break;
    case  2: d = s2(p);  break;
    case  3: d = s3(p);  break;
    case  4: d = s4(p);  break;
    case  5: d = s5(p);  break;
    case  6: d = s6(p);  break;
    case  7: d = s7(p);  break;
    case  9: d = s9(p);  break;
    case 10: d = s10(p); break;
    case 11: d = s11(p); break;
    case 12: d = s12(p); break;
    case 13: d = s13(p); break;
    case 14: d = s14(p); break;
    case 15: d = s15(p); break;
    case 16: d = s16(p); break;
    case 17: d = s17(p); break;
    case 21: d = s21(p); break;
    case 23: d = s23(p); break;
    case 25: d = s25(p); break;
    case 27: d = s27(p); break;
    case 28: d = s28(p); break;
    default: d = sdCircle(p, 0.40); break;
  }

  // Fixed ~1.5-pixel AA — fwidth() not available on all Flutter backends.
  float aa    = 1.5 / uSize;
  float alpha = 1.0 - smoothstep(-aa, aa, d);

  // Premultiplied alpha required by Flutter CanvasKit / skwasm.
  vec3 col = vec3(uRed, uGreen, uBlue);
  fragColor = vec4(col * alpha, alpha);
}
