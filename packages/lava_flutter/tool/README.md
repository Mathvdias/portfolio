# OpenLava asset pipeline

How the built-in demo bundles (`assets/lava/macintosh`, `assets/lava/sunflower`) were
produced, so new icons can be added with the same look as the Airbnb samples.

Requirements: `python3` with `Pillow` and `numpy` (`python3 -m pip install --user Pillow numpy`).

## 1. Render the still

Generate a single 3D icon on a flat white background (any image model works). Prompt used:

> Premium 3D icon of *\<subject\>*, isometric perspective, high-resolution octane 3D render.
> Soft ambient light from top-right, gentle drop shadow below, mild edge highlights, semi-matte
> satin surfaces, stylized naturalism, crisp edges with no outlines, harmonious muted colors with
> slight saturation boost. Single centered object filling the frame comfortably within margins,
> no text, no props, pure flat white background #FFFFFF.

For a subject with a small "hero" part (the sunflower head), ask for a close-up in the prompt
("the big round flower head is the hero and fills most of the frame, very short stem, small pot at
the bottom edge"): the OpenLava canvas is only 180×162, so whatever must stay legible has to be
large in the still.

The image model kept adding a keyboard whenever the prompt said "computer"; the Macintosh 128K
silhouette came out right only when described geometrically ("a retro beige plastic box, taller
than wide, with a recessed screen in the upper front and a thin horizontal slot in the lower front,
nothing attached to it").

## 2. Key + animate

```sh
python3 tool/animate_icon.py sunflower flower_raw.png   sunflower_frames
python3 tool/animate_icon.py macintosh mac_raw.png       mac_frames
```

`animate_icon.py` keys out the (off-)white studio background with a border flood fill, drops the
baked-in drop shadow, then renders 48 frames (1.6 s loop at 30 fps) at the OpenLava canvas size
(180×162 @2x, rendered at 4x and downsampled). Every subject gets a pseudo-3D yaw rock
(perspective warp), a hover/bob and a synthetic contact shadow that reacts to the motion; on top
of that each `Subject` subclass adds its own secondary animation:

- `Sunflower`: wind bend (row-wise shear that grows with height above the pot rim, which is
  detected from the bottom up), the petal ring turning a few degrees around the seed centre while
  the centre and its highlight stay put, and pollen motes drifting up;
- `Bonsai` (kept as a reference subject): the same wind bend plus two leaves tumbling down;
- `Macintosh`: the rendered face is erased and a pixel face is drawn per frame (blink, glance
  to the side, smile), plus a phosphor glow pulse and a scanline band sweeping the CRT.

Add a new `Subject` subclass (override `layer()` / `motion()`) and a `KEY_PARAMS` entry for a
new icon. Geometric transforms go through the premultiplied-alpha helpers (`rotate_pm`,
`yaw_rock`): bicubic resampling of straight-alpha RGBA leaves dark fringes on every edge.

## 3. Encode to OpenLava

```sh
python3 tool/openlava_encode.py assets/lava/sunflower sunflower_frames/frame_*.png
python3 tool/openlava_encode.py assets/lava/macintosh mac_frames/frame_*.png
```

Produces `image_1.png` (key frame), `image_2.png` (2048px-wide diff tile atlas, 32px cells)
and `manifest.json` (`{"type":"key"}` + `{"type":"diff","diffs":[[srcImage,
srcTile, countX, countY, dstTile], ...]}` per frame), exactly the layout `LavaPainter` consumes.
Packing matters for rendering quality, not just size: every diff entry is a separate
`drawImageRect`, and bilinear sampling reads across tile borders in the atlas. The encoder therefore
stores each frame's changed region as one contiguous block (interior borders stay coherent), copies
the unchanged surroundings from the key frame as at most four bands, and separates blocks with a
one-tile transparent gutter so nothing opaque bleeds in. It re-decodes every frame the way the
painter does and reports the max pixel error (must be 0). Then list the directory under `flutter.assets` in the host `pubspec.yaml` and map it
in `LavaBundle.demoAssetPaths` (or load it directly with `LavaBundle.openLavaAsset`).
