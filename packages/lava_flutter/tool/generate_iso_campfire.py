#!/usr/bin/env python3
"""Generates 48 frames of Airbnb Lava-style animated isometric Campfire.
Includes:
- Stylized 3D flame organic breathing, stretch/squash and tip wave
- Inner golden flame core breathing glow with bounce light onto logs
- Glowing embers in wood crevices
- Floating gentle spark particles rising from the flame in a seamless loop
- Grounded contact shadow
"""

import math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

WIDTH = 180
HEIGHT = 162
TOTAL_FRAMES = 48

def make_radial_glow(w, h, color, max_alpha):
    arr = np.zeros((h, w, 4), np.float32)
    cx, cy = w / 2.0, h / 2.0
    y_idx, x_idx = np.ogrid[:h, :w]
    dist = np.sqrt(((x_idx - cx) / (w / 2.0)) ** 2 + ((y_idx - cy) / (h / 2.0)) ** 2)
    falloff = np.clip(1.0 - dist, 0.0, 1.0) ** 2.2
    arr[:, :, 0] = color[0]
    arr[:, :, 1] = color[1]
    arr[:, :, 2] = color[2]
    arr[:, :, 3] = falloff * max_alpha
    return Image.fromarray(arr.astype(np.uint8))

def make_campfire_frames(cutout_path, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    base_raw = Image.open(cutout_path).convert("RGBA")
    
    # Crop tightly to object bounding box
    bbox = base_raw.getbbox()
    cropped = base_raw.crop(bbox)
    
    # Scale to fit nicely inside 180x162 with room for sparks above and shadow below
    target_w = 140
    scale = target_w / cropped.width
    target_h = int(cropped.height * scale)
    base_obj = cropped.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    # Identify flame region vs base logs/stones region in base_obj
    arr = np.array(base_obj)
    obj_h, obj_w = arr.shape[:2]
    
    flame_mask = np.zeros((obj_h, obj_w), np.float32)
    logs_mask = np.zeros((obj_h, obj_w), np.float32)
    
    for y in range(obj_h):
        for x in range(obj_w):
            a = arr[y, x, 3] / 255.0
            if a < 0.1:
                continue
            r, g, b = arr[y, x, :3]
            rel_y = y / obj_h
            if rel_y < 0.58 and r > 180 and g > 70 and b < 120 and (abs(x - obj_w/2) < obj_w * 0.35):
                flame_mask[y, x] = a
            else:
                logs_mask[y, x] = a

    # Smooth flame mask
    flame_mask_im = Image.fromarray((flame_mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2))
    flame_mask = np.array(flame_mask_im).astype(np.float32) / 255.0
    
    flame_layer = arr.copy()
    logs_layer = arr.copy()
    flame_layer[:, :, 3] = (flame_layer[:, :, 3].astype(np.float32) * flame_mask).astype(np.uint8)
    logs_layer[:, :, 3] = (logs_layer[:, :, 3].astype(np.float32) * np.clip(1.0 - flame_mask, 0.0, 1.0)).astype(np.uint8)
    
    im_flame = Image.fromarray(flame_layer)
    im_logs = Image.fromarray(logs_layer)
    
    base_x = (WIDTH - target_w) // 2
    base_y = HEIGHT - target_h - 14
    
    # Spark particles: 10 sparks with deterministic seamless loop
    np.random.seed(42)
    sparks = []
    for i in range(10):
        sparks.append({
            'x_rel': np.random.uniform(-0.14, 0.14),
            'speed_y': np.random.uniform(0.8, 1.2),
            'drift_amp': np.random.uniform(2.0, 4.5),
            'drift_freq': np.random.choice([1, 2]),
            'phase': i / 10.0,
            'size': np.random.choice([1.2, 1.6, 2.0]),
            'color': (255, np.random.randint(190, 245), np.random.randint(60, 110))
        })
    
    frame_paths = []
    
    for f in range(TOTAL_FRAMES):
        t = f / float(TOTAL_FRAMES)
        canvas = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        
        # 1. Soft grounded contact shadow
        shadow_w = int(target_w * 0.86)
        shadow_h = 20
        shadow_cx = WIDTH // 2
        shadow_cy = base_y + target_h - 4
        shadow_im = make_radial_glow(shadow_w, shadow_h, (12, 10, 24), 115)
        canvas.alpha_composite(shadow_im, (shadow_cx - shadow_w//2, shadow_cy - shadow_h//2))
        
        # 2. Flame breathing pulsation and tip dance
        sy = 1.0 + 0.045 * math.sin(t * 2 * math.pi) + 0.015 * math.sin(t * 4 * math.pi)
        sx = 1.0 - 0.025 * math.sin(t * 2 * math.pi) - 0.01 * math.sin(t * 4 * math.pi)
        
        new_fw = max(1, int(target_w * sx))
        new_fh = max(1, int(target_h * sy))
        scaled_flame = im_flame.resize((new_fw, new_fh), Image.Resampling.BILINEAR)
        
        flame_anchor_y = int(target_h * 0.55)
        scaled_anchor_y = int(new_fh * 0.55)
        
        fx = base_x + (target_w - new_fw) // 2
        fy = base_y + (flame_anchor_y - scaled_anchor_y)
        
        # Inner flame golden luminance boost
        flame_arr = np.array(scaled_flame).astype(np.float32)
        bright = (flame_arr[:, :, 0] > 180) & (flame_arr[:, :, 1] > 120)
        flame_arr[:, :, 0][bright] = np.clip(flame_arr[:, :, 0][bright] * (1.0 + 0.06 * math.sin(t * 2 * math.pi)), 0, 255)
        flame_arr[:, :, 1][bright] = np.clip(flame_arr[:, :, 1][bright] * (1.0 + 0.10 * math.sin(t * 2 * math.pi)), 0, 255)
        flame_brightened = Image.fromarray(flame_arr.astype(np.uint8))
        
        # 3. Composite flame directly with glowing core
        canvas.alpha_composite(flame_brightened, (fx, fy))
        
        # 4. Composite logs & stones with bounce light
        logs_arr = np.array(im_logs).astype(np.float32)
        warm_bounce = 1.0 + 0.08 * math.sin(t * 2 * math.pi)
        logs_arr[:, :, 0] = np.clip(logs_arr[:, :, 0] * warm_bounce, 0, 255)
        logs_arr[:, :, 1] = np.clip(logs_arr[:, :, 1] * (1.0 + 0.05 * math.sin(t * 2 * math.pi)), 0, 255)
        im_logs_mod = Image.fromarray(logs_arr.astype(np.uint8))
        canvas.alpha_composite(im_logs_mod, (base_x, base_y))
        
        # 6. Floating Sparks & Embers
        draw = ImageDraw.Draw(canvas)
        for sp in sparks:
            p = (sp['phase'] + t * sp['speed_y']) % 1.0
            flame_cx = WIDTH / 2.0 + sp['x_rel'] * target_w
            flame_cy = base_y + int(target_h * 0.45)
            
            sy_pos = flame_cy - p * 50.0
            sx_pos = flame_cx + sp['drift_amp'] * math.sin(p * math.pi * 2 * sp['drift_freq'] + sp['phase'] * 6.28)
            
            sp_alpha = math.sin(p * math.pi) ** 1.3
            if sp_alpha > 0.05:
                rad = sp['size'] * (1.0 - 0.25 * p)
                col = (sp['color'][0], sp['color'][1], sp['color'][2], int(255 * sp_alpha))
                draw.ellipse([sx_pos - rad, sy_pos - rad, sx_pos + rad, sy_pos + rad], fill=col)

        fpath = os.path.join(out_dir, f"frame_{f:03d}.png")
        canvas.save(fpath)
        frame_paths.append(fpath)

    print(f"Generated {len(frame_paths)} campfire frames in {out_dir}")
    return frame_paths

    print(f"Generated {len(frame_paths)} campfire frames in {out_dir}")
    return frame_paths

if __name__ == "__main__":
    cutout = sys.argv[1]
    out = sys.argv[2]
    make_campfire_frames(cutout, out)
