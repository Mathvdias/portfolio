/// Metadata and coordinate specifications for a tile-based Lava animation.
class LavaManifest {
  const LavaManifest({
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    required this.totalFrames,
    this.version = 1,
    this.frameRate = 30,
    this.loop = true,
    this.loopStartFrame = 0,
    int? loopEndFrame,
  }) : loopEndFrame = loopEndFrame ?? (totalFrames - 1);

  /// Schema version identifier.
  final int version;

  /// Target playback frame rate (e.g. 30, 60).
  final int frameRate;

  /// Width in pixels of each individual animation tile frame.
  final int tileWidth;

  /// Height in pixels of each individual animation tile frame.
  final int tileHeight;

  /// Number of columns in the tile atlas grid.
  final int columns;

  /// Number of rows in the tile atlas grid.
  final int rows;

  /// Total count of frames in the sequence.
  final int totalFrames;

  /// Whether the animation loops continuously.
  final bool loop;

  /// Starting frame index for loop iterations (zero-indexed).
  final int loopStartFrame;

  /// Ending frame index for loop iterations (inclusive).
  final int loopEndFrame;

  /// Duration of a single frame based on the configured [frameRate].
  Duration get frameDuration {
    final effectiveFps = frameRate > 0 ? frameRate : 30;
    return Duration(microseconds: (1000000 / effectiveFps).round());
  }

  /// Total duration of one complete playback sequence.
  Duration get totalDuration => frameDuration * totalFrames;

  /// Parses a [LavaManifest] from a JSON map.
  factory LavaManifest.fromJson(Map<String, dynamic> json) {
    final tileWidth = (json['tileWidth'] as num?)?.toInt() ?? 64;
    final tileHeight = (json['tileHeight'] as num?)?.toInt() ?? 64;
    final columns = (json['columns'] as num?)?.toInt() ?? 1;
    final rows = (json['rows'] as num?)?.toInt() ?? 1;
    final totalFrames =
        (json['totalFrames'] as num?)?.toInt() ?? (columns * rows);

    return LavaManifest(
      version: (json['version'] as num?)?.toInt() ?? 1,
      frameRate: (json['frameRate'] as num?)?.toInt() ?? 30,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columns: columns,
      rows: rows,
      totalFrames: totalFrames,
      loop: json['loop'] as bool? ?? true,
      loopStartFrame: (json['loopStartFrame'] as num?)?.toInt() ?? 0,
      loopEndFrame:
          (json['loopEndFrame'] as num?)?.toInt() ?? (totalFrames - 1),
    );
  }

  /// Serializes the manifest into a JSON map.
  Map<String, dynamic> toJson() => {
    'version': version,
    'frameRate': frameRate,
    'tileWidth': tileWidth,
    'tileHeight': tileHeight,
    'columns': columns,
    'rows': rows,
    'totalFrames': totalFrames,
    'loop': loop,
    'loopStartFrame': loopStartFrame,
    'loopEndFrame': loopEndFrame,
  };

  LavaManifest copyWith({
    int? version,
    int? frameRate,
    int? tileWidth,
    int? tileHeight,
    int? columns,
    int? rows,
    int? totalFrames,
    bool? loop,
    int? loopStartFrame,
    int? loopEndFrame,
  }) {
    return LavaManifest(
      version: version ?? this.version,
      frameRate: frameRate ?? this.frameRate,
      tileWidth: tileWidth ?? this.tileWidth,
      tileHeight: tileHeight ?? this.tileHeight,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      totalFrames: totalFrames ?? this.totalFrames,
      loop: loop ?? this.loop,
      loopStartFrame: loopStartFrame ?? this.loopStartFrame,
      loopEndFrame: loopEndFrame ?? this.loopEndFrame,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LavaManifest &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          frameRate == other.frameRate &&
          tileWidth == other.tileWidth &&
          tileHeight == other.tileHeight &&
          columns == other.columns &&
          rows == other.rows &&
          totalFrames == other.totalFrames &&
          loop == other.loop &&
          loopStartFrame == other.loopStartFrame &&
          loopEndFrame == other.loopEndFrame;

  @override
  int get hashCode => Object.hash(
    version,
    frameRate,
    tileWidth,
    tileHeight,
    columns,
    rows,
    totalFrames,
    loop,
    loopStartFrame,
    loopEndFrame,
  );
}
