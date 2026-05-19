/// Identifies which icon the GPU-side SDF shader should draw.
///
/// [glslIndex] must match the if-else branch index in shaders/icons.frag.
/// Never reorder values — only append at the end.
enum SdfShape {
  person(0),
  folder(1),
  star(2),
  terminal(3),
  calculator(4),
  envelope(5),
  code(6),
  book(7),
  search(8),
  shield(9),
  android(10),
  gamepad(11),
  phone(12),
  file(13),
  briefcase(14),
  globe(15),
  barChart(16),
  wifi(17),
  download(18),
  send(19),
  desktop(20),
  rocket(21),
  trash(22),
  github(23),
  info(24),
  fire(25),
  link(26),
  filePdf(27),
  building(28),
  people(29),
  check(30),
  musicNote(31);

  const SdfShape(this.glslIndex);

  /// The integer passed as the `uShape` uniform to the fragment shader.
  final int glslIndex;
}
