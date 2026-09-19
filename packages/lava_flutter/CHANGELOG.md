## 0.2.0

* Built-in demo icons (`LavaDemoType.macintosh`, `LavaDemoType.sunflower`,
  `LavaDemoType.lavaLamp`, `LavaDemoType.campfire`, `LavaDemoType.rocket`,
  `LavaDemoType.senna`, `LavaDemoType.christmasTree`) are real OpenLava diff tilesets
  (3D-rendered key frame + 32px diff atlas + manifest). The procedural Canvas renderer stays
  available through `LavaBundle.procedural` for offline fallbacks.
* `LavaBundle.demoAssetPaths` maps every demo type to its asset directory.
* `LavaIcon` reconfigures an externally supplied `LavaController` from the decoded bundle
  manifest (frame count, fps, loop bounds) when they do not match.
* New `LavaFrameCompositor`: the manifest is compiled once into typed-data blit plans and every
  diff frame is assembled 1:1 with one `drawRawAtlas` call per source image, then scaled as a
  single image. No per-frame parsing or allocation, no seams or atlas bleeding whatever the
  packing, and composed frames sit in an LRU cache (16 MB budget) so a looping icon stops
  compositing after its first pass. The compositor lives in the `LavaBundle`, so every widget
  showing the same bundle shares it.
* `LavaBundle.openLavaAsset` caches decoded bundles per asset path (`evictOpenLavaCache` releases
  them): a category bar and a preview showing the same icon decode it once.
* Fixed: dragging an interactive icon paused playback for good (`LavaInteractive` now resumes it
  when the drag ends or is cancelled).
* Fixed: `LavaController.configure` did not notify listeners, leaving timelines on stale bounds.
* Fixed: `LavaIcon` could show the bundle of a previously selected demo type when loads finished
  out of order, leaked bundles decoded by `LavaIcon.asset`, and swallowed load errors (they are
  now reported through `FlutterError.reportError`). With an external controller,
  `autoPlay: true` starts it once the bundle is ready.
* Bundles may reference WebP images; the campfire and Christmas tree ship a lossy atlas.
* New campfire, Christmas tree and helmet bundles: the flame and the fairy lights really relight
  the icon (lit / unlit light pass), the helmet is rendered in 3D and turns on its own axis.
* `tool/` ships the Python pipeline used to key, animate, relight, render and encode new OpenLava
  bundles (`animate_icon.py`, `relight_icon.py`, `lava_sdf.py` + `sdf_scenes.py`,
  `openlava_encode.py`).

## 0.1.0

* Initial release of `lava_flutter`.
* Tile-based frame blitting engine with subpixel coordinate mapping (`TileMath`).
* Native 32-bit alpha channel transparency support.
* Ticker-driven `LavaController` with play, pause, stop, scrubbing, and variable speed.
* Interactive 3D perspective tilt (`Matrix4`) and spring-physics touch bounce.
* Zero-allocation `LavaPainter` using pre-cached paint pipelines.
* Built-in procedural 3D demo icon generator (`LavaDemoBaker`).
