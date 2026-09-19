"""OpenLava encoder: frames (RGBA PNG, same size) -> image_1.png (key), image_2.png (diff atlas), manifest.json.

Format consumed by lava_flutter's LavaPainter (identical to the Airbnb sample assets):
  - frames[0]  = {"type": "key", "imageIndex": 0}      -> image_1.png is the full first frame
  - frames[n]  = {"type": "diff", "diffs": [[srcImage, srcTile, countX, countY, dstTile], ...]}
    Each diff blits a countX x countY block of cellSize tiles from srcImage (tile index in that
    image's grid, tilesPerRow = ceil(imageWidth / cellSize)) to the destination tile index.
    A diff frame is drawn on a cleared canvas, so it must list every tile it needs.

Packing strategy (matters for rendering quality, not just size): every blit is a separate
drawImageRect, and bilinear sampling reads across tile borders in the atlas. To avoid seams we
  * store each frame's changed region as ONE contiguous rectangular block (interior borders are
    then spatially coherent),
  * copy the unchanged surroundings from the key frame as at most four rectangular bands,
  * separate blocks in the atlas with a one-tile transparent gutter so nothing opaque bleeds in.
"""
import json, math, sys, os
import numpy as np
from PIL import Image


def load_frames(paths):
    return [np.array(Image.open(p).convert("RGBA")) for p in paths]


def pad(img, cs):
    h, w = img.shape[:2]
    H, W = math.ceil(h / cs) * cs, math.ceil(w / cs) * cs
    out = np.zeros((H, W, 4), np.uint8)
    out[:h, :w] = img
    return out


class Atlas:
    """Shelf packer over a grid of cell-sized tiles, `tpr` tiles per row, with gutters."""

    def __init__(self, cell, tpr, gutter=1):
        self.cell, self.tpr, self.gutter = cell, tpr, gutter
        self.blocks = []          # (x_tile, y_tile, np block)
        self.x = self.y = self.shelf_h = 0
        self.index = {}

    def put(self, block):
        key = block.tobytes()
        if key in self.index:
            return self.index[key]
        bh, bw = block.shape[0] // self.cell, block.shape[1] // self.cell
        if self.x + bw > self.tpr:
            self.y += self.shelf_h + self.gutter
            self.x, self.shelf_h = 0, 0
        pos = (self.x, self.y)
        self.blocks.append((self.x, self.y, block))
        self.x += bw + self.gutter
        self.shelf_h = max(self.shelf_h, bh)
        tile_index = pos[1] * self.tpr + pos[0]
        self.index[key] = tile_index
        return tile_index

    def image(self):
        rows = self.y + self.shelf_h
        img = np.zeros((max(1, rows) * self.cell, self.tpr * self.cell, 4), np.uint8)
        for x, y, b in self.blocks:
            img[y * self.cell:y * self.cell + b.shape[0], x * self.cell:x * self.cell + b.shape[1]] = b
        return img


def encode(frame_paths, out_dir, fps=30, cell=32, diff_w=2048, density=2, gutter=1):
    frames = load_frames(frame_paths)
    h, w = frames[0].shape[:2]
    cols, rows = math.ceil(w / cell), math.ceil(h / cell)
    key = frames[0]
    keyp = pad(key, cell)
    atlas = Atlas(cell, diff_w // cell, gutter)
    manifest_frames = [{"type": "key", "imageIndex": 0}]

    def key_band(c0, r0, c1, r1):                  # inclusive-exclusive tile rect copied from the key
        if c1 <= c0 or r1 <= r0:
            return None
        return [0, int(r0 * cols + c0), int(c1 - c0), int(r1 - r0), int(r0 * cols + c0)]

    for f in frames[1:]:
        fp = pad(f, cell)
        changed = np.zeros((rows, cols), bool)
        for ty in range(rows):
            for tx in range(cols):
                a = fp[ty * cell:(ty + 1) * cell, tx * cell:(tx + 1) * cell]
                b = keyp[ty * cell:(ty + 1) * cell, tx * cell:(tx + 1) * cell]
                changed[ty, tx] = not np.array_equal(a, b)
        diffs = []
        if not changed.any():
            diffs.append([0, 0, cols, rows, 0])
        else:
            rys, rxs = np.where(changed)
            r0, r1, c0, c1 = int(rys.min()), int(rys.max() + 1), int(rxs.min()), int(rxs.max() + 1)
            for band in (key_band(0, 0, cols, r0), key_band(0, r1, cols, rows),
                         key_band(0, r0, c0, r1), key_band(c1, r0, cols, r1)):
                if band:
                    diffs.append(band)
            block = fp[r0 * cell:r1 * cell, c0 * cell:c1 * cell]
            src = atlas.put(block)
            diffs.append([1, int(src), int(c1 - c0), int(r1 - r0), int(r0 * cols + c0)])
        manifest_frames.append({"type": "diff", "diffs": diffs})

    atlas_img = atlas.image()
    os.makedirs(out_dir, exist_ok=True)
    Image.fromarray(key).save(os.path.join(out_dir, "image_1.png"), optimize=True)
    Image.fromarray(atlas_img).save(os.path.join(out_dir, "image_2.png"), optimize=True)
    manifest = {
        "version": 1, "fps": fps, "cellSize": cell, "diffImageSize": diff_w,
        "width": w, "height": h, "density": density, "alpha": True,
        "images": [{"url": "image_1.png"}, {"url": "image_2.png"}],
        "frames": manifest_frames,
    }
    with open(os.path.join(out_dir, "manifest.json"), "w") as fh:
        json.dump(manifest, fh, separators=(",", ":"))
    print(f"{out_dir}: {len(frames)} frames, {len(atlas.blocks)} blocks, atlas {atlas_img.shape[1]}x{atlas_img.shape[0]}")


def decode_check(out_dir, frame_paths, cell=32):
    """Re-render every frame from the manifest exactly like LavaPainter and compare to the source frames."""
    m = json.load(open(os.path.join(out_dir, "manifest.json")))
    imgs = [np.array(Image.open(os.path.join(out_dir, i["url"])).convert("RGBA")) for i in m["images"]]
    w, h = m["width"], m["height"]
    cols = math.ceil(w / cell)
    tpr = [math.ceil(im.shape[1] / cell) for im in imgs]
    src = load_frames(frame_paths)
    worst = 0
    for fi, fr in enumerate(m["frames"]):
        canvas = np.zeros((math.ceil(h / cell) * cell, cols * cell, 4), np.uint8)
        if fr["type"] == "key":
            im = imgs[fr["imageIndex"]]
            canvas[:im.shape[0], :im.shape[1]] = im
        else:
            for si, st, cx, cy, d in fr["diffs"]:
                im = imgs[si]
                sx, sy = (st % tpr[si]) * cell, (st // tpr[si]) * cell
                dx, dy = (d % cols) * cell, (d // cols) * cell
                blk = im[sy:sy + cy * cell, sx:sx + cx * cell]
                canvas[dy:dy + blk.shape[0], dx:dx + blk.shape[1]] = blk
        worst = max(worst, int(np.abs(canvas[:h, :w].astype(int) - src[fi].astype(int)).max()))
    print(f"decode check {out_dir}: max abs pixel error = {worst}")
    return worst


if __name__ == "__main__":
    out = sys.argv[1]; frames = sys.argv[2:]
    encode(frames, out)
    decode_check(out, frames)
