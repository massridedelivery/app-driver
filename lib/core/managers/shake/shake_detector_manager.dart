import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shake/shake.dart';

part 'shake_detector_manager.g.dart';

class ShakeDetectorManager {
  final _shakeController = StreamController<void>.broadcast();
  late final ShakeDetector _detector;

  bool isLogScreenOpen = false;

  ShakeDetectorManager() {
    _detector = ShakeDetector.autoStart(
      onPhoneShake: (event) {
        if (!isLogScreenOpen) {
          _shakeController.add(null);
        }
      },
      shakeThresholdGravity: 3.7,
    );
    debugPrint('[shake] Shake manager initialized and listening.');
  }

  // Expose the stream of shake events
  Stream<void> get onShake => _shakeController.stream;

  void dispose() {
    _detector.stopListening();
    _shakeController.close();
    debugPrint('[shake] Shake manager disposed');
  }
}

@riverpod
ShakeDetectorManager shakeDetectorManager(Ref ref) {
  final manager = ShakeDetectorManager();
  ref.onDispose(() => manager.dispose());
  return manager;
}

@riverpod
Stream<void> shakeEvents(Ref ref) {
  return ref.watch(shakeDetectorManagerProvider).onShake;
}
