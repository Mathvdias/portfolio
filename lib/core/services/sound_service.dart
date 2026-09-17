import 'sound_service_stub.dart'
    if (dart.library.js_interop) 'sound_service_web.dart';

abstract class SoundService {
  factory SoundService() => getSoundService();

  bool get isMuted;
  void toggleMute();
  void playClick();
  void playWindowOpen();
  void playWindowClose();
  void playChime();
  void playKeypress();
}
