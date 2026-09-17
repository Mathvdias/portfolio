import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/services/sound_service.dart';

void main() {
  group('SoundService (Stub)', () {
    late SoundService service;

    setUp(() {
      service = SoundService();
    });

    test('initial isMuted is false', () {
      expect(service.isMuted, isFalse);
    });

    test('toggleMute toggles mute state', () {
      service.toggleMute();
      expect(service.isMuted, isTrue);
      service.toggleMute();
      expect(service.isMuted, isFalse);
    });

    test('sound play methods run without error on stub platform', () {
      expect(() => service.playClick(), returnsNormally);
      expect(() => service.playWindowOpen(), returnsNormally);
      expect(() => service.playWindowClose(), returnsNormally);
      expect(() => service.playChime(), returnsNormally);
      expect(() => service.playKeypress(), returnsNormally);
    });
  });
}
