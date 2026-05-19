#include <flutter/runtime_effect.glsl>

// ─── Uniforms ─────────────────────────────────────────────────────────────────
uniform float uSize;   // canvas side in logical pixels (square assumed)
uniform float uRed;
uniform float uGreen;
uniform float uBlue;
uniform float uShape;  // cast to int: index into the if-else chain below

out vec4 fragColor;

// ─── SDF Primitives ───────────────────────────────────────────────────────────

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
  vec2 pa = p - a, ba = b - a;
  return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}

// sc = vec2(sin(halfAngle), cos(halfAngle)); r = radius; w = half-thickness
float sdArc(vec2 p, vec2 sc, float r, float w) {
  p.x = abs(p.x);
  float k = (sc.y * p.x > sc.x * p.y) ? dot(p, sc) : length(p);
  return sqrt(max(dot(p, p) + r * r - 2.0 * r * k, 0.0)) - w;
}

float sdTri(vec2 p, vec2 a, vec2 b, vec2 c) {
  vec2 e0 = b-a, e1 = c-b, e2 = a-c;
  vec2 v0 = p-a, v1 = p-b, v2 = p-c;
  vec2 pq0 = v0 - e0*clamp(dot(v0,e0)/dot(e0,e0), 0.0, 1.0);
  vec2 pq1 = v1 - e1*clamp(dot(v1,e1)/dot(e1,e1), 0.0, 1.0);
  vec2 pq2 = v2 - e2*clamp(dot(v2,e2)/dot(e2,e2), 0.0, 1.0);
  float s = sign(e0.x*e2.y - e0.y*e2.x);
  vec2 d = min(min(vec2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)),
                   vec2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
                   vec2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x)));
  return -sqrt(d.x) * sign(d.y);
}

// ─── Boolean ops ──────────────────────────────────────────────────────────────
float opU(float a, float b)  { return min(a, b); }
float opS(float a, float b)  { return max(a, -b); }  // a minus b

float opSU(float a, float b, float k) {              // smooth union
  float h = clamp(0.5 + 0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

// ─── Icon SDFs — normalized space p ∈ [-0.5, 0.5] ────────────────────────────

// 0  person
float s0(vec2 p) {
  return opU(sdCircle(p - vec2(0.0, 0.22), 0.16),
             sdRBox(p  - vec2(0.0, -0.10), vec2(0.18, 0.20), 0.08));
}

// 1  folder
float s1(vec2 p) {
  return opU(sdRBox(p - vec2(0.0, -0.06), vec2(0.42, 0.26), 0.04),
             sdRBox(p - vec2(-0.20, 0.22), vec2(0.14, 0.06), 0.03));
}

// 2  star  (Inigo Quilez 5-point formula)
float s2(vec2 p) {
  const vec2 k1 = vec2(0.809016994375, -0.587785252192);
  const vec2 k2 = vec2(-0.809016994375, -0.587785252192);
  float r = 0.40, rf = 0.44;
  p.x = abs(p.x);
  p -= 2.0*max(dot(k1,p),0.0)*k1;
  p -= 2.0*max(dot(k2,p),0.0)*k2;
  p.x = abs(p.x); p.y -= r;
  vec2 ba = rf*vec2(-k1.y,k1.x) - vec2(0.0,1.0);
  float h = clamp(dot(p,ba)/dot(ba,ba), 0.0, r);
  return length(p - ba*h)*sign(p.x*ba.y - p.y*ba.x);
}

// 3  terminal  (>_ prompt)
float s3(vec2 p) {
  float caret = opU(sdSeg(p, vec2(-0.32,  0.14), vec2(-0.10,  0.0)),
                    sdSeg(p, vec2(-0.10,  0.0),  vec2(-0.32, -0.14)));
  float cursor = sdSeg(p, vec2(-0.02, -0.14), vec2(0.28, -0.14));
  return opU(caret, cursor) - 0.032;
}

// 4  calculator
float s4(vec2 p) {
  float body = sdRBox(p, vec2(0.34, 0.42), 0.07);
  float disp = sdRBox(p - vec2(0.0, 0.22), vec2(0.26, 0.12), 0.04);
  float d = opS(body, disp);
  float btns = 1e6;
  for (int ri = 0; ri < 4; ri++)
    for (int ci = 0; ci < 3; ci++)
      btns = opU(btns, sdCircle(p - vec2(-0.16+float(ci)*0.16, 0.04-float(ri)*0.16), 0.04));
  return opU(d, btns);
}

// 5  envelope
float s5(vec2 p) {
  float body = sdRBox(p, vec2(0.40, 0.28), 0.04);
  float v1   = sdSeg(p, vec2(-0.40,  0.28), vec2(0.0, 0.0)) - 0.025;
  float v2   = sdSeg(p, vec2( 0.40,  0.28), vec2(0.0, 0.0)) - 0.025;
  return opS(opS(body, v1), v2);
}

// 6  code  (<>)
float s6(vec2 p) {
  float lk = opU(sdSeg(p, vec2(-0.08, 0.0), vec2(-0.30,  0.24)),
                 sdSeg(p, vec2(-0.08, 0.0), vec2(-0.30, -0.24)));
  float rk = opU(sdSeg(p, vec2( 0.08, 0.0), vec2( 0.30,  0.24)),
                 sdSeg(p, vec2( 0.08, 0.0), vec2( 0.30, -0.24)));
  return opU(lk, rk) - 0.032;
}

// 7  book  (open)
float s7(vec2 p) {
  float lp = sdRBox(p - vec2(-0.19, 0.0), vec2(0.16, 0.34), 0.04);
  float rp = sdRBox(p - vec2( 0.19, 0.0), vec2(0.16, 0.34), 0.04);
  return opU(opU(lp, rp), sdBox(p, vec2(0.025, 0.34)));
}

// 8  search  (magnifying glass)
float s8(vec2 p) {
  float ring  = abs(sdCircle(p - vec2(-0.06,  0.08), 0.22)) - 0.045;
  float hndl  = sdSeg(p, vec2(0.11, -0.09), vec2(0.34, -0.32)) - 0.045;
  return opU(ring, hndl);
}

// 9  shield
float s9(vec2 p) {
  return opU(sdRBox(p - vec2(0.0, 0.08), vec2(0.38, 0.30), 0.10),
             sdTri(p, vec2(-0.38, -0.10), vec2(0.38, -0.10), vec2(0.0, -0.46)));
}

// 10 android robot
float s10(vec2 p) {
  float hc    = sdCircle(p - vec2(0.0, 0.16), 0.24);
  float hclip = sdBox(p - vec2(0.0, -0.06), vec2(0.28, 0.12));
  float head  = opS(hc, hclip);
  float a1    = sdSeg(p, vec2(-0.10, 0.36), vec2(-0.20, 0.46)) - 0.025;
  float a2    = sdSeg(p, vec2( 0.10, 0.36), vec2( 0.20, 0.46)) - 0.025;
  float body  = sdRBox(p - vec2(0.0, -0.16), vec2(0.26, 0.22), 0.06);
  float e1    = sdCircle(p - vec2(-0.09, 0.16), 0.04);
  float e2    = sdCircle(p - vec2( 0.09, 0.16), 0.04);
  float d = opU(opU(head, body), opU(a1, a2));
  return opS(opS(d, e1), e2);
}

// 11 gamepad
float s11(vec2 p) {
  float body = sdRBox(p, vec2(0.40, 0.20), 0.14);
  float dh   = sdBox(p - vec2(-0.18, 0.0), vec2(0.12, 0.04));
  float dv   = sdBox(p - vec2(-0.18, 0.0), vec2(0.04, 0.12));
  float b1   = sdCircle(p - vec2( 0.24,  0.07), 0.055);
  float b2   = sdCircle(p - vec2( 0.16, -0.07), 0.055);
  return opU(opU(body, opU(dh, dv)), opU(b1, b2));
}

// 12 phone
float s12(vec2 p) { return sdRBox(p, vec2(0.18, 0.40), 0.09); }

// 13 file / document
float s13(vec2 p) {
  float body = sdBox(p - vec2(-0.04, 0.0), vec2(0.30, 0.42));
  float clip = sdTri(p, vec2(0.10, 0.42), vec2(0.26, 0.42), vec2(0.26, 0.26));
  body = opS(body, clip);
  float flap = sdTri(p, vec2(0.10, 0.42), vec2(0.26, 0.26), vec2(0.10, 0.26));
  float l1   = sdBox(p - vec2(-0.06,  0.10), vec2(0.16, 0.025));
  float l2   = sdBox(p - vec2(-0.06, -0.04), vec2(0.16, 0.025));
  float l3   = sdBox(p - vec2(-0.10, -0.18), vec2(0.12, 0.025));
  float carved = opS(opS(opS(body, l1), l2), l3);
  return opU(carved, flap);
}

// 14 briefcase
float s14(vec2 p) {
  float body = sdRBox(p - vec2(0.0, -0.06), vec2(0.38, 0.26), 0.06);
  float hdl  = sdArc(p - vec2(0.0, 0.12), vec2(sin(1.1), cos(1.1)), 0.18, 0.035);
  float div  = sdBox(p - vec2(0.0, -0.06), vec2(0.38, 0.025));
  return opU(opU(body, hdl), div);
}

// 15 globe
float s15(vec2 p) {
  float ring = abs(sdCircle(p, 0.38)) - 0.04;
  float heq  = sdBox(p, vec2(0.38, 0.030));
  float veq  = sdBox(p, vec2(0.030, 0.38));
  float lon  = abs(length(vec2(p.x * 1.8, p.y)) - 0.38) - 0.04;
  return opU(opU(ring, heq), opU(veq, lon));
}

// 16 bar chart
float s16(vec2 p) {
  float b1   = sdBox(p - vec2(-0.24, -0.08), vec2(0.08, 0.22));
  float b2   = sdBox(p - vec2( 0.0,  -0.02), vec2(0.08, 0.28));
  float b3   = sdBox(p - vec2( 0.24,  0.06), vec2(0.08, 0.20));
  float base = sdBox(p - vec2( 0.0, -0.40),  vec2(0.38, 0.030));
  return opU(opU(b1, b2), opU(b3, base));
}

// 17 wifi
float s17(vec2 p) {
  vec2 ctr = vec2(0.0, -0.30);
  vec2 sc  = vec2(sin(1.10), cos(1.10));
  float dot = sdCircle(p - ctr, 0.055);
  float a1  = sdArc(p - ctr, sc, 0.14, 0.038);
  float a2  = sdArc(p - ctr, sc, 0.27, 0.038);
  float a3  = sdArc(p - ctr, sc, 0.42, 0.038);
  return opU(opU(dot, a1), opU(a2, a3));
}

// 18 download
float s18(vec2 p) {
  float shaft = sdBox(p - vec2(0.0,  0.13), vec2(0.06, 0.21));
  float head  = sdTri(p, vec2(-0.20, -0.08), vec2(0.20, -0.08), vec2(0.0, -0.30));
  float line  = sdBox(p - vec2(0.0, -0.40), vec2(0.32, 0.030));
  return opU(opU(shaft, head), line);
}

// 19 send  (right-pointing triangle = paper plane)
float s19(vec2 p) {
  return sdTri(p, vec2(-0.36, 0.32), vec2(-0.36, -0.32), vec2(0.38, 0.0));
}

// 20 desktop monitor
float s20(vec2 p) {
  float scr   = sdRBox(p - vec2(0.0,  0.10), vec2(0.40, 0.28), 0.06);
  float stand = sdBox(p  - vec2(0.0, -0.22), vec2(0.05, 0.12));
  float base  = sdBox(p  - vec2(0.0, -0.34), vec2(0.18, 0.04));
  return opU(opU(scr, stand), base);
}

// 21 rocket
float s21(vec2 p) {
  float body = sdRBox(p, vec2(0.14, 0.30), 0.10);
  float nose = sdTri(p, vec2(-0.14, 0.18), vec2(0.14, 0.18), vec2(0.0, 0.46));
  float finL = sdTri(p, vec2(-0.14,-0.16), vec2(-0.28,-0.38), vec2(-0.14,-0.38));
  float finR = sdTri(p, vec2( 0.14,-0.16), vec2( 0.28,-0.38), vec2( 0.14,-0.38));
  float exh  = sdCircle(p - vec2(0.0, -0.38), 0.07);
  return opU(opU(opU(body, nose), finL), opU(finR, exh));
}

// 22 trash can
float s22(vec2 p) {
  float body  = sdRBox(p - vec2(0.0, -0.08), vec2(0.28, 0.32), 0.04);
  float lid   = sdRBox(p - vec2(0.0,  0.28), vec2(0.32, 0.06), 0.03);
  float hdl   = sdRBox(p - vec2(0.0,  0.40), vec2(0.12, 0.06), 0.03);
  float inner = sdRBox(p - vec2(0.0, -0.08), vec2(0.21, 0.25), 0.02);
  float l1    = sdBox(p  - vec2(-0.10, -0.08), vec2(0.025, 0.24));
  float l2    = sdBox(p  - vec2( 0.10, -0.08), vec2(0.025, 0.24));
  return opU(opU(opS(opU(opU(body, lid), hdl), inner), l1), l2);
}

// 23 github  (simplified: filled head + ears - eye holes)
float s23(vec2 p) {
  float head = sdCircle(p - vec2(0.0, -0.02), 0.28);
  float earL = sdCircle(p - vec2(-0.20,  0.24), 0.12);
  float earR = sdCircle(p - vec2( 0.20,  0.24), 0.12);
  float d = opU(head, opU(earL, earR));
  float eL = sdCircle(p - vec2(-0.10, 0.04), 0.05);
  float eR = sdCircle(p - vec2( 0.10, 0.04), 0.05);
  return opS(opS(d, eL), eR);
}

// 24 info
float s24(vec2 p) {
  float ring = abs(sdCircle(p, 0.40)) - 0.04;
  float dot  = sdCircle(p - vec2(0.0,  0.22), 0.06);
  float bar  = sdBox(p   - vec2(0.0, -0.04), vec2(0.055, 0.22));
  return opU(ring, opU(dot, bar));
}

// 25 fire  (flame)
float s25(vec2 p) {
  float circle = sdCircle(p + vec2(0.0, 0.10), 0.32);
  float tip    = sdTri(p, vec2(-0.22, 0.12), vec2(0.22, 0.12), vec2(0.0, 0.44));
  return opSU(circle, tip, 0.12);
}

// 26 link  (two interlocked circular rings)
float s26(vec2 p) {
  float r1 = abs(sdCircle(p - vec2(-0.14, 0.0), 0.24)) - 0.05;
  float r2 = abs(sdCircle(p - vec2( 0.14, 0.0), 0.24)) - 0.05;
  return opU(r1, r2);
}

// 27 PDF file  (document + filled bar at bottom)
float s27(vec2 p) {
  float body = sdBox(p - vec2(-0.04, 0.0), vec2(0.30, 0.42));
  float clip = sdTri(p, vec2(0.10, 0.42), vec2(0.26, 0.42), vec2(0.26, 0.26));
  body = opS(body, clip);
  float flap = sdTri(p, vec2(0.10, 0.42), vec2(0.26, 0.26), vec2(0.10, 0.26));
  float bar  = sdRBox(p - vec2(-0.04, -0.28), vec2(0.24, 0.08), 0.04);
  return opU(opU(body, flap), bar);
}

// 28 building (classical columns)
float s28(vec2 p) {
  float base = sdBox(p - vec2(0.0, -0.40), vec2(0.42, 0.06));
  float top  = sdBox(p - vec2(0.0,  0.38), vec2(0.42, 0.06));
  float c0   = sdBox(p - vec2(-0.28, 0.0), vec2(0.055, 0.32));
  float c1   = sdBox(p - vec2(-0.09, 0.0), vec2(0.055, 0.32));
  float c2   = sdBox(p - vec2( 0.09, 0.0), vec2(0.055, 0.32));
  float c3   = sdBox(p - vec2( 0.28, 0.0), vec2(0.055, 0.32));
  return opU(opU(base, top), opU(opU(c0, c1), opU(c2, c3)));
}

// 29 people  (two persons side-by-side)
float s29(vec2 p) {
  float h1 = sdCircle(p - vec2( 0.14, 0.22), 0.12);
  float b1 = sdRBox(p  - vec2( 0.14,-0.08), vec2(0.14, 0.16), 0.06);
  float h2 = sdCircle(p - vec2(-0.14, 0.22), 0.12);
  float b2 = sdRBox(p  - vec2(-0.14,-0.08), vec2(0.14, 0.16), 0.06);
  return opU(opU(h1, b1), opU(h2, b2));
}

// 30 checkmark
float s30(vec2 p) {
  return opU(sdSeg(p, vec2(-0.32,  0.04), vec2(-0.08, -0.22)),
             sdSeg(p, vec2(-0.08, -0.22), vec2( 0.36,  0.28))) - 0.040;
}

// 31 music note
float s31(vec2 p) {
  float head = sdRBox(vec2((p.x+0.10)*1.3, p.y+0.26), vec2(0.12, 0.08), 0.08);
  float stem = sdBox(p - vec2(0.14, 0.06), vec2(0.025, 0.32));
  float flag = sdSeg(p, vec2(0.165, -0.26), vec2(0.34, -0.08)) - 0.025;
  return opU(opU(head, stem), flag);
}

// ─── Main ─────────────────────────────────────────────────────────────────────
void main() {
  vec2 p = (FlutterFragCoord().xy / uSize) - 0.5;
  int  s = int(uShape + 0.5);

  float d;
  if      (s ==  0) d = s0(p);
  else if (s ==  1) d = s1(p);
  else if (s ==  2) d = s2(p);
  else if (s ==  3) d = s3(p);
  else if (s ==  4) d = s4(p);
  else if (s ==  5) d = s5(p);
  else if (s ==  6) d = s6(p);
  else if (s ==  7) d = s7(p);
  else if (s ==  8) d = s8(p);
  else if (s ==  9) d = s9(p);
  else if (s == 10) d = s10(p);
  else if (s == 11) d = s11(p);
  else if (s == 12) d = s12(p);
  else if (s == 13) d = s13(p);
  else if (s == 14) d = s14(p);
  else if (s == 15) d = s15(p);
  else if (s == 16) d = s16(p);
  else if (s == 17) d = s17(p);
  else if (s == 18) d = s18(p);
  else if (s == 19) d = s19(p);
  else if (s == 20) d = s20(p);
  else if (s == 21) d = s21(p);
  else if (s == 22) d = s22(p);
  else if (s == 23) d = s23(p);
  else if (s == 24) d = s24(p);
  else if (s == 25) d = s25(p);
  else if (s == 26) d = s26(p);
  else if (s == 27) d = s27(p);
  else if (s == 28) d = s28(p);
  else if (s == 29) d = s29(p);
  else if (s == 30) d = s30(p);
  else if (s == 31) d = s31(p);
  else              d = sdCircle(p, 0.40);  // fallback

  // fwidth() requires the derivatives extension which Flutter/CanvasKit does
  // not expose.  Use a fixed-width AA of ~1.5 logical pixels instead.
  float aa    = 1.5 / uSize;
  float alpha = 1.0 - smoothstep(-aa, aa, d);

  // Premultiplied alpha — required by Flutter CanvasKit / skwasm.
  vec3 col = vec3(uRed, uGreen, uBlue);
  fragColor = vec4(col * alpha, alpha);
}
