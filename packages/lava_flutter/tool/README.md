# OpenLava asset pipeline

How the built-in demo bundles were produced, so new icons can be added with the same look as the
Airbnb samples. There are three ways to get frames, all ending in `openlava_encode.py`:

| Route | Script | Use it when | Built with it |
| --- | --- | --- | --- |
| Still + motion | `animate_icon.py` | one rendered still, secondary motion is enough | Macintosh, sunflower |
| Lit / unlit pair | `relight_icon.py` | the icon has a light source that must light the rest of it | campfire, Christmas tree |
| Procedural 3D | `sdf_scenes.py` (+ `lava_sdf.py`) | the object has to turn on its own axis | racing helmet |

Sections 1-3 cover the first route; 4 and 5 the other two.

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

Photographic icons whose light changes every pixel of every frame pack badly as PNG (about 2 MB).
`--webp 90` stores the key frame as lossless WebP and the diff atlas as lossy WebP with a lossless
alpha plane - the trade the Airbnb assets make with AVIF - which brings them to about 0.5 MB. 4:2:0
chroma washes out thin saturated lines, so flat hard-edged art (the helmet stripes) takes
`--webp 100` (lossless WebP). `--fps N` sets the manifest frame rate. The decode check reports the
premultiplied error: it must be 0 for lossless bundles and stays around 1/255 on average at q90.

## 4. Icons that emit light: lit / unlit pair

A still cannot flicker. Ask the image model for the icon twice, pixel-aligned: first with the light
source on, then as an *edit of that same image* with it off ("keep exactly the same composition,
camera and background, pixel-aligned; the fire is out; remove the flame and every bit of warm
glow it cast on the logs, stones and ground; nothing else may change"). `lit - unlit` is then a
real light pass - what the source adds to every surface around it - and the frames are rebuilt as
`unlit + light_pass * intensity(t)`:

```sh
python3 tool/relight_icon.py campfire      tool/stills/campfire_lit.webp      tool/stills/campfire_unlit.webp      fire_frames
python3 tool/relight_icon.py christmastree tool/stills/christmastree_lit.webp tool/stills/christmastree_unlit.webp tree_frames
python3 tool/openlava_encode.py assets/lava/campfire      --webp 90 fire_frames/frame_*.png
python3 tool/openlava_encode.py assets/lava/christmastree --webp 90 tree_frames/frame_*.png
```

- `Campfire`: the flame is lifted out of the lit still by colour (a morphological opening drops the
  glowing log ends that hang off it, the pointed tip is kept), then bent row by row, stretched and
  redrawn over the unlit logs; the light pass follows the same flicker with a small radial delay,
  bloom feeds the alpha channel so the glow survives on dark backgrounds, sparks rise and fade.
- `ChristmasTree`: the bright cores of the light pass are split into connected components, one
  per bulb, each owning the pool of light around it; pools blink in sequence along the string and
  the star breathes. Snow falls in front and the whole tree rocks with the pseudo-3D yaw.

Backdrop: white is fine for the campfire (the smooth baked drop shadow is flood-filled away, the
textured stones stop the fill). Anything white at the silhouette (snow) needs a chroma backdrop:
ask for "a perfectly flat uniform pure magenta background #FF00FF (chroma key)"; `key_backdrop`
removes enclosed pockets and despills the outline.

## 5. Icons that turn: procedural 3D

`lava_sdf.py` is a small numpy SDF ray marcher tuned for this look: orthographic three-quarter
camera, soft top-left key light with soft shadows, hemisphere ambient, ambient occlusion, satin
specular, fresnel rim, emissive materials, point lights, bloom and a blurred contact shadow that
fades before the frame edge. A scene is a `Scene` subclass returning `(distance, material)` parts;
materials can be callables of the hit point, so paint jobs (the helmet bands, the visor gasket) are
painted in object space. Every motion is a whole multiple of the loop phase, so loops are seamless.

```sh
python3 tool/sdf_scenes.py senna --still 0.1 preview.png     # look-dev, about 3 s
python3 tool/sdf_scenes.py senna assets/lava/senna           # 72 frames on all cores, about 10 s
python3 tool/openlava_encode.py assets/lava/senna --fps 24 --webp 100 <frames_dir>/frame_*.png
```

The helmet makes one turn in 72 frames at 24 fps; in the app, `dragToRotate` scrubs those frames, so
dragging spins it by hand. `sdf_scenes.py` also carries fully procedural `campfire` and
`christmastree` scenes (flame as an emissive SDF that lights the logs through a point light, fairy
lights as blinking point lights): they need no image model at all, but the lit / unlit route above
gives far richer materials, so the shipped bundles use that.
