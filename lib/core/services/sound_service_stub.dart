import 'sound_service.dart';

class SoundServiceStub implements SoundService {
  bool _muted = false;

  @override
  bool get isMuted => _muted;

  @override
  void toggleMute() {
    _muted = !_muted;
  }

  @override
  void playClick() {}

  @override
  void playWindowOpen() {}

  @override
  void playWindowClose() {}

  @override
  void playChime() {}

  @override
  void playKeypress() {}
}

SoundService getSoundService() => SoundServiceStub();
