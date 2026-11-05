import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/features/call/domain/call_ports.dart';

/// [CallRingback] over audioplayers: the Thai ringback (425 Hz, 1 s on /
/// 4 s off) looped on the voice-call stream, so it comes out of the earpiece
/// — or the loudspeaker when the driver keeps it on — like a phone call.
class AudioRingback implements CallRingback {
  AudioPlayer? _player;
  bool _on = false;

  @override
  Future<void> start({required bool speaker}) async {
    if (_on) return;
    _on = true;
    try {
      final player = _player ??= AudioPlayer(playerId: 'call_ringback');
      await player.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: speaker,
            audioMode: AndroidAudioMode.inCommunication,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.voiceCommunication,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
          iOS: AudioContextIOS(
            // The category CallKit and WebRTC use for the call itself, so
            // the tone doesn't fight the call's audio session.
            category: AVAudioSessionCategory.playAndRecord,
            options: {
              AVAudioSessionOptions.allowBluetooth,
              if (speaker) AVAudioSessionOptions.defaultToSpeaker,
            },
          ),
        ),
      );
      await player.setReleaseMode(ReleaseMode.loop);
      // Hung up while the player was being set up.
      if (!_on) return;
      await player.play(AssetSource('sounds/ringback.wav'));
      if (!_on) await player.stop();
    } catch (e) {
      // A missing tone must never stop the call itself.
      debugPrint('AudioRingback: could not play: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (!_on) return;
    _on = false;
    try {
      await _player?.stop();
    } catch (e) {
      debugPrint('AudioRingback: could not stop: $e');
    }
  }
}
