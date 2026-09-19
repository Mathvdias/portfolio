#!/usr/bin/env python3
"""Generates 48 frames of Airbnb Lava-style animated isometric Christmas Tree.
Includes:
- Gentle, slow, peaceful drifting fluffy snowflakes with organic sway
- Golden 3D star warm breathing glow and specular highlight
- Glossy sphere baubles subtle glint
- Very subtle tactile 3D idle breathing
- Soft contact shadow beneath snow mound base
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

def make_tree_frames(cutout_path, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    base_raw = Image.open(cutout_path).convert("RGBA")
    
    bbox = base_raw.getbbox()
    cropped = base_raw.crop(bbox)
    
    # Scale to fit nicely inside 180x162 with room for the star glow above and snow around
    # Target height ~138px
    target_h = 138
    scale = target_h / cropped.height
    target_w = int(cropped.width * scale)
    base_obj = cropped.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    base_x = (WIDTH - target_w) // 2
    base_y = HEIGHT - target_h - 6
    
    arr = np.array(base_obj)
    obj_h, obj_w = arr.shape[:2]
    
    # Locate star region (top 22% of tree)
    star_mask = np.zeros((obj_h, obj_w), np.float32)
    for y in range(int(obj_h * 0.25)):
        for x in range(obj_w):
            a = arr[y, x, 3] / 255.0
            if a < 0.1:
                continue
            r, g, b = arr[y, x, :3]
            # Star: golden yellow / orange hues
            if r > 180 and g > 130 and b < 100:
                star_mask[y, x] = a
    
    star_mask_im = Image.fromarray((star_mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5))
    star_mask = np.array(star_mask_im).astype(np.float32) / 255.0
    
    # Generate 18 gentle snowflakes (slow drift, floating, wrapping)
    np.random.seed(1234)
    snowflakes = []
    for i in range(18):
        snowflakes.append({
            'init_x': np.random.uniform(8, WIDTH - 8),
            'init_y': np.random.uniform(4, HEIGHT - 10),
            'speed_y': np.random.uniform(22.0, 36.0),  # Slow vertical drift across 48 frames
            'sway_amp': np.random.uniform(2.5, 5.0),
            'sway_freq': np.random.choice([1, 2]),
            'sway_phase': np.random.uniform(0, math.pi * 2),
            'radius': np.random.choice([1.2, 1.5, 1.8, 2.2]),
            'alpha': np.random.uniform(0.65, 0.95),
        })
    
    frame_paths = []
    
    for f in range(TOTAL_FRAMES):
        t = f / float(TOTAL_FRAMES)
        canvas = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        
        # 1. Soft grounded contact shadow under snow mound
        shadow_w = int(target_w * 0.88)
        shadow_h = 18
        shadow_cx = WIDTH // 2
        shadow_cy = base_y + target_h - 2
        shadow_im = make_radial_glow(shadow_w, shadow_h, (15, 15, 28), 110)
        canvas.alpha_composite(shadow_im, (shadow_cx - shadow_w//2, shadow_cy - shadow_h//2))
        
        # 2. Tree subtle breathing and star glow modulation
        sy = 1.0 + 0.008 * math.sin(t * 2 * math.pi)
        sx = 1.0 - 0.004 * math.sin(t * 2 * math.pi)
        
        # Modulate star glow
        star_glow = 1.0 + 0.18 * math.sin(t * 2 * math.pi)
        obj_mod = arr.copy().astype(np.float32)
        
        # Brighten star
        for c in range(3):
            obj_mod[:, :, c] = np.clip(
                obj_mod[:, :, c] * (1.0 - star_mask) + obj_mod[:, :, c] * star_mask * star_glow,
                0, 255
            )
            
        # Modulate subtle sparkle on ornaments
        sparkle_phase = math.sin(t * 2 * math.pi * 2)
        # Red/blue bauble specular boost
        bauble_spec = (obj_mod[:, :, 0] > 200) & (obj_mod[:, :, 1] > 180) & (obj_mod[:, :, 2] > 180)
        obj_mod[:, :, :3][bauble_spec] = np.clip(
            obj_mod[:, :, :3][bauble_spec] * (1.0 + 0.15 * sparkle_phase), 0, 255
        )
        
        im_tree_mod = Image.fromarray(obj_mod.astype(np.uint8))
        
        # Resize with breathing
        new_w = max(1, int(target_w * sx))
        new_h = max(1, int(target_h * sy))
        scaled_tree = im_tree_mod.resize((new_w, new_h), Image.Resampling.BILINEAR)
        
        tx = base_x + (target_w - new_w) // 2
        ty = base_y + (target_h - new_h)  # anchored at base
        
        # 3. Composite tree
        canvas.alpha_composite(scaled_tree, (tx, ty))
        
        # 4. Floating peaceful snowflakes
        draw = ImageDraw.Draw(canvas)
        for sf in snowflakes:
            # y drifts slowly and wraps seamlessly
            y_pos = (sf['init_y'] + t * sf['speed_y']) % (HEIGHT - 4)
            # x sways gently
            x_pos = sf['init_x'] + sf['sway_amp'] * math.sin(t * 2 * math.pi * sf['sway_freq'] + sf['sway_phase'])
            
            # Flake opacity: subtle twinkle
            f_alpha = int(sf['alpha'] * 255 * (0.85 + 0.15 * math.sin(t * 2 * math.pi * 3 + sf['sway_phase'])))
            r = sf['radius']
            
            # Draw soft white snowflake dot
            draw.ellipse([x_pos - r, y_pos - r, x_pos + r, y_pos + r], fill=(255, 255, 255, f_alpha))
            # Subtle soft glow ring around flake
            if r > 1.5:
                draw.ellipse([x_pos - r - 0.8, y_pos - r - 0.8, x_pos + r + 0.8, y_pos + r + 0.8],
                             outline=(240, 248, 255, int(f_alpha * 0.35)))

        fpath = os.path.join(out_dir, f"frame_{f:03d}.png")
        canvas.save(fpath)
        frame_paths.append(fpath)

    print(f"Generated {len(frame_paths)} tree frames in {out_dir}")
    return frame_paths

if __name__ == "__main__":
    cutout = sys.argv[1]
    out = sys.argv[2]
    make_tree_frames(cutout, out)
