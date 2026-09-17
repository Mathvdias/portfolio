import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'sound_service.dart';

@JS()
external JSObject get window;

class SoundServiceWeb implements SoundService {
  bool _muted = false;

  JSObject? get _audio {
    if (!window.hasProperty('mathOsAudio'.toJS).toDart) return null;
    return window.getProperty<JSObject?>('mathOsAudio'.toJS);
  }

  @override
  bool get isMuted {
    final audio = _audio;
    if (audio != null && audio.hasProperty('isMuted'.toJS).toDart) {
      final res = audio.callMethod<JSBoolean>('isMuted'.toJS);
      return res.toDart;
    }
    return _muted;
  }

  @override
  void toggleMute() {
    final audio = _audio;
    if (audio != null && audio.hasProperty('toggleMute'.toJS).toDart) {
      final res = audio.callMethod<JSBoolean>('toggleMute'.toJS);
      _muted = res.toDart;
    } else {
      _muted = !_muted;
    }
  }

  @override
  void playClick() {
    final audio = _audio;
    if (audio != null && audio.hasProperty('playClick'.toJS).toDart) {
      audio.callMethod('playClick'.toJS);
    }
  }

  @override
  void playWindowOpen() {
    final audio = _audio;
    if (audio != null && audio.hasProperty('playWindowOpen'.toJS).toDart) {
      audio.callMethod('playWindowOpen'.toJS);
    }
  }

  @override
  void playWindowClose() {
    final audio = _audio;
    if (audio != null && audio.hasProperty('playWindowClose'.toJS).toDart) {
      audio.callMethod('playWindowClose'.toJS);
    }
  }

  @override
  void playChime() {
    final audio = _audio;
    if (audio != null && audio.hasProperty('playChime'.toJS).toDart) {
      audio.callMethod('playChime'.toJS);
    }
  }

  @override
  void playKeypress() {
    final audio = _audio;
    if (audio != null && audio.hasProperty('playKeypress'.toJS).toDart) {
      audio.callMethod('playKeypress'.toJS);
    }
  }
}

SoundService getSoundService() => SoundServiceWeb();
