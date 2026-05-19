import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/models/sdf_shape.dart';

void main() {
  group('SdfShape', () {
    test('has exactly 32 values', () {
      expect(SdfShape.values.length, 32);
    });

    test('all glslIndex values are unique', () {
      final indices = SdfShape.values.map((s) => s.glslIndex).toSet();
      expect(indices.length, SdfShape.values.length,
          reason: 'Duplicate glslIndex detected');
    });

    test('glslIndex values are sequential starting from 0', () {
      for (int i = 0; i < SdfShape.values.length; i++) {
        expect(SdfShape.values[i].glslIndex, i,
            reason: '${SdfShape.values[i]} should have glslIndex $i');
      }
    });

    test('spot-check known shape indices', () {
      expect(SdfShape.person.glslIndex, 0);
      expect(SdfShape.folder.glslIndex, 1);
      expect(SdfShape.star.glslIndex, 2);
      expect(SdfShape.terminal.glslIndex, 3);
      expect(SdfShape.calculator.glslIndex, 4);
      expect(SdfShape.envelope.glslIndex, 5);
      expect(SdfShape.code.glslIndex, 6);
      expect(SdfShape.book.glslIndex, 7);
      expect(SdfShape.search.glslIndex, 8);
      expect(SdfShape.shield.glslIndex, 9);
      expect(SdfShape.android.glslIndex, 10);
      expect(SdfShape.gamepad.glslIndex, 11);
      expect(SdfShape.phone.glslIndex, 12);
      expect(SdfShape.file.glslIndex, 13);
      expect(SdfShape.briefcase.glslIndex, 14);
      expect(SdfShape.globe.glslIndex, 15);
      expect(SdfShape.barChart.glslIndex, 16);
      expect(SdfShape.wifi.glslIndex, 17);
      expect(SdfShape.download.glslIndex, 18);
      expect(SdfShape.send.glslIndex, 19);
      expect(SdfShape.desktop.glslIndex, 20);
      expect(SdfShape.rocket.glslIndex, 21);
      expect(SdfShape.trash.glslIndex, 22);
      expect(SdfShape.github.glslIndex, 23);
      expect(SdfShape.info.glslIndex, 24);
      expect(SdfShape.fire.glslIndex, 25);
      expect(SdfShape.link.glslIndex, 26);
      expect(SdfShape.filePdf.glslIndex, 27);
      expect(SdfShape.building.glslIndex, 28);
      expect(SdfShape.people.glslIndex, 29);
      expect(SdfShape.check.glslIndex, 30);
      expect(SdfShape.musicNote.glslIndex, 31);
    });

    test('glslIndex max is 31 (shader branch count)', () {
      final max = SdfShape.values.map((s) => s.glslIndex).reduce((a, b) => a > b ? a : b);
      expect(max, 31);
    });

    test('all enum names are non-empty strings', () {
      for (final shape in SdfShape.values) {
        expect(shape.name, isNotEmpty);
      }
    });
  });
}
