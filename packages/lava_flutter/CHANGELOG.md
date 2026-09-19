## 0.2.0

* Built-in demo icons (`LavaDemoType.macintosh`, `LavaDemoType.sunflower`,
  `LavaDemoType.lavaLamp`, `LavaDemoType.campfire`, `LavaDemoType.rocket`,
  `LavaDemoType.senna`, `LavaDemoType.christmasTree`) are real OpenLava diff tilesets
  (3D-rendered key frame + 32px diff atlas + manifest). The procedural Canvas renderer stays
  available through `LavaBundle.procedural` for offline fallbacks.
* `LavaBundle.demoAssetPaths` maps every demo type to its asset directory.
* `LavaIcon` reconfigures an externally supplied `LavaController` from the decoded bundle
  manifest (frame count, fps, loop bounds) when they do not match.
* `LavaPainter` blits tiles with edge anti-aliasing disabled: adjacent tile rectangles no longer
  leave hairline seams once the canvas is scaled.
* `tool/` ships the Python pipeline used to key, animate and encode new OpenLava bundles.

## 0.1.0

* Initial release of `lava_flutter`.
* Tile-based frame blitting engine with subpixel coordinate mapping (`TileMath`).
* Native 32-bit alpha channel transparency support.
* Ticker-driven `LavaController` with play, pause, stop, scrubbing, and variable speed.
* Interactive 3D perspective tilt (`Matrix4`) and spring-physics touch bounce.
* Zero-allocation `LavaPainter` using pre-cached paint pipelines.
* Built-in procedural 3D demo icon generator (`LavaDemoBaker`).
