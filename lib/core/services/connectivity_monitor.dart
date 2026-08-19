import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/configs/environment_config.dart';

/// Internet quality shown on the settings screen.
enum NetworkQuality {
  /// A probe is in flight and there's no prior verdict yet.
  checking,

  /// Reachable with acceptable latency.
  good,

  /// Reachable but slow/unstable — the "สัญญาณอ่อน" warning.
  weak,

  /// No network carrier, or the internet is unreachable.
  offline,
}

@immutable
class NetworkStatus {
  final NetworkQuality quality;

  /// Round-trip latency of the last successful probe, in ms.
  final int? latencyMs;

  /// True when the OS reports a network carrier (wifi/mobile/…), even if the
  /// internet itself turns out to be unreachable.
  final bool hasCarrier;

  /// True when the active transport is mobile data (for the label only).
  final bool isMobile;

  const NetworkStatus({
    this.quality = NetworkQuality.checking,
    this.latencyMs,
    this.hasCarrier = true,
    this.isMobile = false,
  });

  bool get isAlert =>
      quality == NetworkQuality.weak || quality == NetworkQuality.offline;

  NetworkStatus copyWith({
    NetworkQuality? quality,
    int? latencyMs,
    bool clearLatency = false,
    bool? hasCarrier,
    bool? isMobile,
  }) {
    return NetworkStatus(
      quality: quality ?? this.quality,
      latencyMs: clearLatency ? null : (latencyMs ?? this.latencyMs),
      hasCarrier: hasCarrier ?? this.hasCarrier,
      isMobile: isMobile ?? this.isMobile,
    );
  }
}

/// Monitors internet reachability + quality by probing the API host, so the
/// settings screen can warn on a weak or missing connection. Latency is a
/// proxy for signal strength (the OS exposes no cross-platform RSSI).
class ConnectivityMonitor extends Notifier<NetworkStatus> {
  /// How often the background probe runs.
  static const Duration _interval = Duration(seconds: 8);

  /// A successful probe slower than this is treated as a weak/unstable signal.
  static const int _weakThresholdMs = 1200;

  /// Per-probe timeout; exceeding it counts as unreachable.
  static const Duration _probeTimeout = Duration(seconds: 6);

  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  HttpClient? _client;
  bool _probing = false;

  @override
  NetworkStatus build() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      final isMobile = results.contains(ConnectivityResult.mobile);
      if (!hasNet) {
        state = NetworkStatus(
          quality: NetworkQuality.offline,
          hasCarrier: false,
          isMobile: isMobile,
        );
      } else {
        // Carrier just came back — re-probe to confirm real internet.
        state = state.copyWith(hasCarrier: true, isMobile: isMobile);
        _probe();
      }
    });

    _timer = Timer.periodic(_interval, (_) => _probe());

    ref.onDispose(() {
      _timer?.cancel();
      _sub?.cancel();
      _client?.close(force: true);
    });

    // Kick off the first probe without blocking build().
    Future.microtask(_probe);
    return const NetworkStatus();
  }

  /// User-triggered re-check; flips to `checking` first so the UI shows motion.
  Future<void> refresh() async {
    state = state.copyWith(quality: NetworkQuality.checking);
    await _probe();
  }

  Future<void> _probe() async {
    if (_probing) return;
    _probing = true;
    try {
      final results = await Connectivity().checkConnectivity();
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      final isMobile = results.contains(ConnectivityResult.mobile);
      if (!hasNet) {
        state = NetworkStatus(
          quality: NetworkQuality.offline,
          hasCarrier: false,
          isMobile: isMobile,
        );
        return;
      }

      final client = _client ??= HttpClient()
        ..connectionTimeout = _probeTimeout;
      final uri = Uri.parse(EnvironmentConfig.apiUrl);
      final sw = Stopwatch()..start();
      try {
        final req = await client.headUrl(uri).timeout(_probeTimeout);
        final resp = await req.close().timeout(_probeTimeout);
        await resp.drain<void>();
        sw.stop();
        final ms = sw.elapsedMilliseconds;
        // Any HTTP status means the host answered → internet is reachable.
        state = NetworkStatus(
          quality: ms > _weakThresholdMs
              ? NetworkQuality.weak
              : NetworkQuality.good,
          latencyMs: ms,
          hasCarrier: true,
          isMobile: isMobile,
        );
      } on TimeoutException {
        // Carrier present but the host never answered in time.
        state = NetworkStatus(
          quality: NetworkQuality.offline,
          hasCarrier: true,
          isMobile: isMobile,
        );
      } on SocketException {
        state = NetworkStatus(
          quality: NetworkQuality.offline,
          hasCarrier: true,
          isMobile: isMobile,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('ConnectivityMonitor: probe error $e');
        state = NetworkStatus(
          quality: NetworkQuality.weak,
          hasCarrier: true,
          isMobile: isMobile,
        );
      }
    } finally {
      _probing = false;
    }
  }
}

/// Under Riverpod 3.x providers are autoDispose by default, so the probe timer
/// only runs while the settings screen (its sole watcher) is mounted and is
/// torn down (via [ref.onDispose]) on leaving — no background battery drain.
final connectivityMonitorProvider =
    NotifierProvider<ConnectivityMonitor, NetworkStatus>(
      ConnectivityMonitor.new,
    );
