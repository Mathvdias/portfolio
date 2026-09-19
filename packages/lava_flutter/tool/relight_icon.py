"""Animate an icon from a lit / unlit pair of stills so its light sources really light it.

An image model renders the icon twice, pixel-aligned: once with its light source on (flame
burning, fairy lights glowing) and once with it off. `lit - unlit` is then a genuine light pass:
what the source adds to every surface around it. Frames are rebuilt as

    unlit + light_pass * intensity(t)          (per light source, each with its own phase)

plus the emitter itself (warped flame sprite / bulbs), bloom that also feeds the alpha channel so
the glow survives on dark backgrounds, particles and a contact shadow. That is the same trick the
Airbnb hot-air balloon uses: the burner visibly lights the envelope.

    python3 tool/relight_icon.py campfire      fire_lit.png fire_unlit.png frames/
    python3 tool/relight_icon.py christmastree tree_lit.png tree_unlit.png frames/
    python3 tool/openlava_encode.py assets/lava/campfire frames/frame_*.png
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from animate_icon import H, SCALE, W, components, fill_holes, largest_component, yaw_rock

SS = 4
TAU = 2.0 * math.pi


# ----------------------------------------------------------------------------- helpers
def blur(a, radius):
    """Gaussian blur of a float array in [0, 255] (2D or HxWx3)."""
    if a.ndim == 3:
        return np.dstack([blur(a[..., c], radius) for c in range(a.shape[2])])
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    return np.array(img.filter(ImageFilter.GaussianBlur(radius))).astype(np.float32)


def grow(mask, px):
    return np.array(Image.fromarray(mask.astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(2 * px + 1))) > 0


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def shrink(mask, px):
    return np.array(Image.fromarray(mask.astype(np.uint8) * 255).filter(ImageFilter.MinFilter(2 * px + 1))) > 0


def key_backdrop(img, thr=34, matte=70.0, shadow_min=None):
    """Flat-backdrop keyer (white or chroma): flood fill from the border on colour distance, soft
    matte on the outline, colours unpremultiplied against the backdrop. Returns float RGBA."""
    rgb = np.array(img.convert("RGB")).astype(np.float32)
    h, w = rgb.shape[:2]
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    bgcol = np.median(border, axis=0)
    dist = np.abs(rgb - bgcol).max(axis=2)
    fill = Image.fromarray((dist < thr).astype(np.uint8) * 255).copy()
    for x in range(0, w, 16):
        for seed in ((x, 0), (x, h - 1), (0, min(x, h - 1)), (w - 1, min(x, h - 1))):
            if fill.getpixel(seed) == 255:
                ImageDraw.floodfill(fill, seed, 128)
    bg = np.array(fill) == 128
    if shadow_min is not None:
        # baked drop shadow: neutral light grey hanging off the backdrop in the lower half
        # (it is smooth, so the flood stops at the textured, hard-edged stones and logs)
        mn = rgb.min(axis=2)
        gy, gx = np.gradient(blur(mn, 1.0))
        lower = (np.arange(h) > 0.45 * h)[:, None]
        cand = bg | ((rgb.max(axis=2) - mn < 24) & (mn > shadow_min) & (np.hypot(gx, gy) < 5.0) & lower)
        fill = Image.fromarray(cand.astype(np.uint8) * 255).copy()
        ys, xs = np.where(bg)
        ImageDraw.floodfill(fill, (int(xs[0]), int(ys[0])), 128)
        bg = np.array(fill) == 128
    alpha = np.where(bg, 0.0, 1.0).astype(np.float32)
    ring = grow(bg, 3) & ~bg
    a = np.clip(dist[ring] / matte, 0.0, 1.0)
    alpha[ring] = a
    keep = a > 0.06
    fixed = rgb[ring]
    fixed[keep] = np.clip((fixed[keep] - (1.0 - a[keep, None]) * bgcol) / a[keep, None], 0, 255)
    rgb[ring] = fixed
    if bgcol[1] < 90 and bgcol[0] > 180 and bgcol[2] > 180:
        # magenta chroma key: nothing in the subject is magenta, so enclosed pockets go too and
        # the outline loses whatever red + blue it has in excess of green
        pocket = dist < thr * 1.6
        alpha[pocket] = 0.0
        edge = grow(bg | pocket, 12)
        spill = np.clip(np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1], 0, None) * edge
        rgb[..., 0] -= spill
        rgb[..., 2] -= spill
    alpha *= largest_component(alpha > 0.5) | (grow(largest_component(alpha > 0.5), 4) & (alpha > 0))
    return np.dstack([rgb, alpha * 255.0])


def crop_box(alpha, pad=6):
    ys, xs = np.where(alpha > 8)
    return (max(xs.min() - pad, 0), max(ys.min() - pad, 0),
            min(xs.max() + pad, alpha.shape[1] - 1), min(ys.max() + pad, alpha.shape[0] - 1))


def row_warp(rgba, shift):
    """Shift every row horizontally by shift[y] pixels (premultiplied, linear interpolation)."""
    h, w = rgba.shape[:2]
    pm = rgba.astype(np.float32).copy()
    pm[..., :3] *= pm[..., 3:4] / 255.0
    xs = np.arange(w, dtype=np.float32)
    out = np.zeros_like(pm)
    for y in range(h):
        src = xs - shift[y]
        for c in range(4):
            out[y, :, c] = np.interp(src, xs, pm[y, :, c], left=0.0, right=0.0)
    al = out[..., 3:4]
    out[..., :3] = np.where(al > 1.0, out[..., :3] / np.maximum(al / 255.0, 1e-3), 0.0)
    return out


def over(dst, src):
    """Straight-alpha float `src` over `dst` (both HxWx4, 0..255)."""
    sa, da = src[..., 3:4] / 255.0, dst[..., 3:4] / 255.0
    oa = sa + da * (1.0 - sa)
    rgb = (src[..., :3] * sa + dst[..., :3] * da * (1.0 - sa)) / np.maximum(oa, 1e-4)
    return np.dstack([rgb, oa * 255.0])


def add_glow(frame, energy, gain=1.0):
    """Additive light that also lifts alpha, so a glow is visible over any background."""
    a = frame[..., 3:4] / 255.0
    pm = frame[..., :3] * a + energy * gain
    na = np.maximum(a, np.clip(energy.max(axis=2, keepdims=True) * gain / 255.0 * 1.15, 0.0, 1.0))
    return np.dstack([np.clip(pm / np.maximum(na, 1e-4), 0, 255), na * 255.0])


# ----------------------------------------------------------------------------- subjects
class Relit:
    n_frames, fps = 48, 30
    fill, base_y = 0.84, 0.90
    key = dict(thr=34, matte=70.0)

    def __init__(self, lit, unlit):
        keyed = key_backdrop(unlit, **self.key)
        keyed_lit = key_backdrop(lit, **self.key)
        alpha = np.maximum(keyed[..., 3], keyed_lit[..., 3])
        x0, y0, x1, y1 = crop_box(alpha)
        scale = min(self.fill * H * SS / (y1 - y0), 0.94 * W * SS / (x1 - x0))
        size = (int((x1 - x0) * scale), int((y1 - y0) * scale))

        def fit(a):
            return np.array(Image.fromarray(np.clip(a[y0:y1, x0:x1], 0, 255).astype(np.uint8)).resize(size, Image.LANCZOS)).astype(np.float32)

        # transparent margin so glow and bloom can spill past the silhouette
        self.margin = m = int(0.14 * max(size))
        self.unlit, self.lit = (np.pad(fit(a), ((m, m), (m, m), (0, 0))) for a in (keyed, keyed_lit))
        self.h, self.w = self.unlit.shape[:2]
        self.prepare()

    def prepare(self):
        pass

    def frame(self, t):
        """-> (float RGBA layer, yaw degrees, shadow alpha)"""
        raise NotImplementedError


class Campfire(Relit):
    key = dict(thr=34, matte=70.0, shadow_min=150)
    flame_scale = 1.30
    LIGHT_LEVELS = 8

    def prepare(self):
        lit = self.lit
        r, g, b = lit[..., 0], lit[..., 1], lit[..., 2]
        flame = (r > 205) & (g > 95) & (r - b > 85) & (lit[..., 3] > 128)
        # glowing log ends hang off the flame through thin necks: open the mask to drop them
        neck = max(2, int(0.020 * self.w))
        ys = np.where(flame.any(axis=1))[0]
        upper = np.arange(self.h)[:, None] < ys.min() + 0.45 * (ys.max() - ys.min())   # the tip is thin too
        flame = fill_holes(largest_component((grow(largest_component(shrink(flame, neck)), neck + 1) | upper) & flame))
        soft = blur(flame.astype(np.float32) * 255.0, 1.2)
        sprite = np.dstack([lit[..., :3], soft])
        ys, xs = np.where(flame)
        x0, x1, y0, y1 = xs.min() - 3, xs.max() + 4, ys.min() - 3, ys.max() + 1
        # a slightly bigger flame reads better on the tiny canvas; it grows from its base
        big = Image.fromarray(np.clip(sprite[y0:y1, x0:x1], 0, 255).astype(np.uint8))
        big = np.array(big.resize((int((x1 - x0) * self.flame_scale), int((y1 - y0) * self.flame_scale)), Image.LANCZOS)).astype(np.float32)
        self.flame = np.zeros_like(sprite)
        bx = int((x0 + x1) / 2 - big.shape[1] / 2)
        self.flame[y1 - big.shape[0]:y1, bx:bx + big.shape[1]] = big
        ys, xs = np.where(self.flame[..., 3] > 128)
        self.fy0, self.fy1, self.fcx = ys.min(), ys.max(), xs.mean()

        gain = np.clip(lit[..., :3] - self.unlit[..., :3], 0, None)
        gain *= (1.0 - blur(grow(flame, 5).astype(np.float32) * 255.0, 4) / 255.0)[..., None]
        self.light = gain * (self.unlit[..., 3:4] / 255.0)
        yy, xx = np.mgrid[0:self.h, 0:self.w].astype(np.float32)
        self.radius = np.hypot(xx - self.fcx, (yy - self.fy1) * 1.6) / self.w
        self.base = np.dstack([self.unlit[..., :3], self.unlit[..., 3]])
        rng = np.random.default_rng(5)
        self.sparks = rng.uniform(0.0, 1.0, (7, 3))

    @staticmethod
    def flicker(t, ph=0.0):
        return (1.0 + 0.17 * math.sin(TAU * (3 * t + ph)) + 0.10 * math.sin(TAU * (7 * t + 1.7 * ph) + 1.3)
                + 0.05 * math.sin(TAU * (11 * t + ph)))

    def frame(self, t):
        f = self.flicker(t)
        # Tile economy: the light pass only takes LIGHT_LEVELS distinct intensities, so every tile
        # the flame does not touch repeats across the loop and is stored once per level instead of
        # once per frame (the steps are ~4 % of brightness: invisible in motion).
        level = round((f - 0.70) / 0.60 * (self.LIGHT_LEVELS - 1)) / (self.LIGHT_LEVELS - 1) * 0.60 + 0.70
        out = self.base.copy()
        out[..., :3] = np.clip(out[..., :3] + self.light * level * 1.08, 0, 255)

        # flame: rows bend more the higher they are, the whole tongue stretches and breathes
        rows = np.arange(self.h, dtype=np.float32)
        lift = np.clip((self.fy1 - rows) / max(self.fy1 - self.fy0, 1), 0.0, 1.0)
        shift = self.w * lift ** 1.7 * (0.050 * np.sin(TAU * (2 * t) + 3.2 * lift)
                                        + 0.022 * np.sin(TAU * (5 * t) + 7.0 * lift))
        flame = row_warp(self.flame, shift)
        stretch = 1.0 + 0.085 * math.sin(TAU * (4 * t)) + 0.04 * math.sin(TAU * (9 * t) + 0.8)
        fh = self.fy1 - self.fy0 + 1
        crop = Image.fromarray(np.clip(flame[self.fy0:self.fy1 + 1], 0, 255).astype(np.uint8))
        crop = np.array(crop.resize((self.w, max(2, int(fh * stretch))), Image.BICUBIC)).astype(np.float32)
        top = self.fy1 + 1 - crop.shape[0]
        layer = np.zeros_like(flame)
        layer[max(top, 0):self.fy1 + 1] = crop[max(-top, 0):]
        layer[..., :3] = np.clip(layer[..., :3] * (0.96 + 0.07 * f), 0, 255)
        out = over(out, layer)

        energy = blur(layer[..., 3], 0.030 * self.w)[..., None] * np.array([1.0, 0.52, 0.12], np.float32)
        energy += blur(layer[..., 3], 0.085 * self.w)[..., None] * np.array([0.85, 0.36, 0.06], np.float32)
        energy = np.where(energy.max(axis=2, keepdims=True) < 10.0, 0.0, energy)   # no invisible tails: they dirty far tiles
        out = add_glow(out, energy, 0.33 * f)

        dots = Image.new("L", (self.w, self.h), 0)
        draw = ImageDraw.Draw(dots)
        for s0, s1, s2 in self.sparks:
            life = (t + s0) % 1.0
            x = self.fcx + self.w * ((s1 - 0.5) * 0.20 + 0.05 * math.sin(TAU * (life * 1.5 + s2)))
            y = self.fy0 + fh * 0.35 - life * (self.fy0 + fh * 0.35) * 0.98
            rad = 0.0065 * self.w * math.sin(math.pi * life) ** 0.6
            draw.ellipse([x - rad, y - rad, x + rad, y + rad], fill=255)
        d = np.array(dots).astype(np.float32)
        spark = (d + 1.6 * blur(d, 0.012 * self.w))[..., None] * np.array([1.0, 0.72, 0.30], np.float32)
        return add_glow(out, spark, 1.0), 0.0, 0.85 + 0.15 * (2.0 - level)   # quantised like the light


class ChristmasTree(Relit):
    n_frames, fps = 60, 30
    fill, base_y = 0.90, 0.93
    key = dict(thr=60, matte=110.0)

    def prepare(self):
        body = self.unlit[..., 3:4] / 255.0
        gain = np.clip(self.lit[..., :3] - self.unlit[..., :3], 0, None) * body
        luma = gain @ np.array([0.30, 0.59, 0.11], np.float32)
        cores = luma > max(60.0, float(np.percentile(luma[body[..., 0] > 0.5], 97.5)))
        boxes = sorted(components(cores, min_px=max(6, int(2e-5 * self.w * self.h))), key=lambda b: (b[1] + b[3]))
        masks = []
        for x0, y0, x1, y1 in boxes[:40]:
            m = np.zeros((self.h, self.w), np.float32)
            m[y0:y1 + 1, x0:x1 + 1] = cores[y0:y1 + 1, x0:x1 + 1] * 255.0
            masks.append(blur(m, 0.035 * self.w) + 1e-3)
        self.star = 0
        if masks:
            total = np.sum(masks, axis=0)
            self.pools = [gain * (m / total)[..., None] * smoothstep(0.0, 6.0, total)[..., None] for m in masks]
            areas = [(b[2] - b[0]) * (b[3] - b[1]) for b in boxes[:40]]
            top = [i for i, b in enumerate(boxes[:40]) if b[1] < 0.22 * self.h]
            self.star = max(top, key=lambda i: areas[i]) if top else 0
        else:
            self.pools = []
        self.rest = gain - (np.sum(self.pools, axis=0) if self.pools else 0.0)
        self.base = self.unlit.copy()
        rng = np.random.default_rng(11)
        self.flakes = rng.uniform(0.0, 1.0, (7, 4))
        print(f"christmastree: {len(self.pools)} light pools (star = #{self.star})")

    # Tile economy (see Campfire.LIGHT_LEVELS): a bulb is off, half way or on - which is also how a
    # real blinker behaves - and the ambient share of the light is constant. The pseudo-3D rock makes
    # every tile of the tree unique per frame, but it is what makes the icon feel alive and it only
    # costs ~77 KB (307 -> 384 KB as AVIF), so it stays.
    BLINK_LEVELS = (0.04, 0.70, 1.30)
    ROCK_DEGREES = 9.0

    def power(self, t):
        i = np.arange(len(self.pools))
        ramp = smoothstep(-0.05, 0.35, np.sin(TAU * (2.0 * t + i * 0.29)))
        p = np.array(self.BLINK_LEVELS)[np.round(ramp * (len(self.BLINK_LEVELS) - 1)).astype(int)]
        if len(p):
            p[self.star] = (0.75, 0.90, 1.05)[int(round(1.0 + math.sin(TAU * 2 * t)))]
        return p

    def frame(self, t):
        p = self.power(t)
        light = self.rest * 0.65
        for pool, k in zip(self.pools, p):
            light = light + pool * k
        out = self.base.copy()
        out[..., :3] = np.clip(out[..., :3] + light, 0, 255)
        hot = np.clip(light - 70.0, 0, None)
        glow = blur(hot, 0.012 * self.w) * 0.9 + blur(hot, 0.04 * self.w) * 0.9
        out = add_glow(out, np.where(glow.max(axis=2, keepdims=True) < 10.0, 0.0, glow), 1.0)
        return out, self.ROCK_DEGREES * math.sin(TAU * t), 1.0

    def particles(self, canvas, t):
        cw, ch = canvas.size
        dots = Image.new("L", (cw, ch), 0)
        draw = ImageDraw.Draw(dots)
        for s0, s1, s2, s3 in self.flakes:
            life = (t + s0) % 1.0
            x = cw * (0.06 + 0.88 * s1) + 0.02 * cw * math.sin(TAU * (life + s3))
            y = ch * (-0.02 + 0.98 * life)
            rad = ch * (0.008 + 0.006 * s2) * math.sin(math.pi * life) ** 0.5
            draw.ellipse([x - rad, y - rad, x + rad, y + rad], fill=235)
        dots = dots.filter(ImageFilter.GaussianBlur(0.7 * SS * SCALE))
        flakes = Image.new("RGBA", (cw, ch), (250, 252, 255, 0))
        flakes.putalpha(dots)
        canvas.alpha_composite(flakes)


SUBJECTS = {"campfire": Campfire, "christmastree": ChristmasTree}


def render(kind, lit, unlit, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    subj = SUBJECTS[kind](lit, unlit)
    cw, ch = W * SS, H * SS
    cx, base = cw / 2, subj.base_y * ch
    pad = int(0.16 * max(subj.w, subj.h))
    paths = []
    for i in range(subj.n_frames):
        t = i / subj.n_frames
        layer, yaw, shadow_alpha = subj.frame(t)
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        sh = Image.new("L", (cw, ch), 0)
        body_w, body_h = subj.w - 2 * subj.margin, subj.h - 2 * subj.margin
        sw, shh = body_w * 0.44, body_h * 0.05
        ImageDraw.Draw(sh).ellipse([cx - sw, base - shh, cx + sw, base + shh], fill=int(95 * shadow_alpha))
        canvas.paste(Image.new("RGBA", (cw, ch), (20, 16, 12, 255)), (0, 0), sh.filter(ImageFilter.GaussianBlur(9 * SS * SCALE)))
        big = Image.new("RGBA", (subj.w + 2 * pad, subj.h + 2 * pad), (0, 0, 0, 0))
        big.alpha_composite(Image.fromarray(np.clip(layer, 0, 255).astype(np.uint8)), (pad, pad))
        if yaw:
            big = yaw_rock(big, yaw)
        canvas.alpha_composite(big, (int(round(cx - big.width / 2)), int(round(base - pad - subj.h + subj.margin))))
        if hasattr(subj, "particles"):
            subj.particles(canvas, t)
        path = os.path.join(out_dir, f"frame_{i:03d}.png")
        canvas.resize((W, H), Image.LANCZOS).save(path)
        paths.append(path)
    print(f"{kind}: {len(paths)} frames @ {subj.fps} fps -> {out_dir}")
    return paths


if __name__ == "__main__":
    render(sys.argv[1], Image.open(sys.argv[2]), Image.open(sys.argv[3]), sys.argv[4])
