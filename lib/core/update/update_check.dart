import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:massdrive/core/configs/environment_config.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What `GET /api/config/version` says about the installed version.
enum UpdateStatus { ok, suggest, force }

/// The backend's answer for one app version.
class VersionAnswer {
  const VersionAnswer({
    required this.status,
    this.latestVersion,
    this.storeUrl,
    this.message,
    this.messageTh,
  });

  /// An unknown status counts as OK: only an explicit FORCE_UPDATE may block.
  factory VersionAnswer.fromJson(Map<dynamic, dynamic> json) {
    String? text(String key) {
      final v = json[key]?.toString().trim();
      return v == null || v.isEmpty ? null : v;
    }

    final status = switch (json['status']?.toString()) {
      'FORCE_UPDATE' => UpdateStatus.force,
      'SUGGEST_UPDATE' => UpdateStatus.suggest,
      _ => UpdateStatus.ok,
    };
    return VersionAnswer(
      status: status,
      latestVersion: text('latest_version'),
      storeUrl: text('store_url'),
      message: text('message'),
      messageTh: text('message_th'),
    );
  }

  final UpdateStatus status;
  final String? latestVersion;
  final String? storeUrl;
  final String? message;
  final String? messageTh;

  Map<String, dynamic> toJson() => {
    'status': switch (status) {
      UpdateStatus.force => 'FORCE_UPDATE',
      UpdateStatus.suggest => 'SUGGEST_UPDATE',
      UpdateStatus.ok => 'OK',
    },
    'latest_version': latestVersion,
    'store_url': storeUrl,
    'message': message,
    'message_th': messageTh,
  };
}

/// Result of asking the backend. [answer] is null when it gave none: [offline]
/// tells a network failure (no response at all) from a refusal (404/400/5xx or
/// a body we can't read), since only the former may fall back to the cache.
class BackendReply {
  const BackendReply.answered(VersionAnswer this.answer) : offline = false;
  const BackendReply.refused() : answer = null, offline = false;
  const BackendReply.offline() : answer = null, offline = true;

  final VersionAnswer? answer;
  final bool offline;
}

/// The store has a newer build than the one installed.
class StoreUpdate {
  const StoreUpdate({
    required this.storeUrl,
    this.storeVersion,
    this.playImmediate = false,
  });

  final String storeUrl;

  /// The App Store version; null on Android, where Play doesn't expose it.
  final String? storeVersion;

  /// Play allows its full-screen ("immediate") in-app update for this install.
  final bool playImmediate;
}

/// What to show the driver: the blocking screen ([force]) or the dismissible
/// dialog.
class UpdatePrompt {
  const UpdatePrompt({
    required this.force,
    required this.storeUrl,
    this.latestVersion,
    this.message,
    this.messageTh,
    this.playImmediate = false,
  });

  final bool force;
  final String storeUrl;
  final String? latestVersion;
  final String? message;
  final String? messageTh;
  final bool playImmediate;

  /// The backend's message in the driver's language, else the other one.
  String? messageFor({required bool thai}) =>
      thai ? (messageTh ?? message) : (message ?? messageTh);
}

/// True when dotted version [a] is higher than [b]: "1.0.10" beats "1.0.9",
/// "1.1" beats "1.0.9". A build suffix ("+12") is ignored and a non-numeric
/// part counts as 0.
bool isNewerVersion(String a, String b) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .trim()
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final x = parts(a);
  final y = parts(b);
  for (var i = 0; i < x.length || i < y.length; i++) {
    final p = i < x.length ? x[i] : 0;
    final q = i < y.length ? y[i] : 0;
    if (p != q) return p > q;
  }
  return false;
}

/// The update rules. The backend decides; the store can only add a
/// suggestion; and nothing blocks unless the backend said FORCE_UPDATE — now,
/// or last time for this same [appVersion] while it can't be reached.
UpdatePrompt? decideUpdate({
  required String appVersion,
  required BackendReply backend,
  required String fallbackStoreUrl,
  VersionAnswer? cached,
  String? cachedForVersion,
  StoreUpdate? store,
}) {
  UpdatePrompt fromAnswer(VersionAnswer a, {required bool force}) =>
      UpdatePrompt(
        force: force,
        storeUrl: a.storeUrl ?? store?.storeUrl ?? fallbackStoreUrl,
        latestVersion: a.latestVersion ?? store?.storeVersion,
        message: a.message,
        messageTh: a.messageTh,
        playImmediate: store?.playImmediate ?? false,
      );

  final answer = backend.answer;
  if (answer != null && answer.status != UpdateStatus.ok) {
    return fromAnswer(answer, force: answer.status == UpdateStatus.force);
  }
  if (answer == null &&
      backend.offline &&
      cached?.status == UpdateStatus.force &&
      cachedForVersion == appVersion) {
    return fromAnswer(cached!, force: true);
  }
  if (store != null) {
    return UpdatePrompt(
      force: false,
      storeUrl: store.storeUrl,
      latestVersion: store.storeVersion,
      playImmediate: store.playImmediate,
    );
  }
  return null;
}

/// The suggestion dialog shows at most once per 24 h for the same version; a
/// newer version may show right away.
bool shouldShowSuggestion({
  required String version,
  required DateTime now,
  String? lastVersion,
  DateTime? lastShownAt,
}) =>
    lastVersion != version ||
    lastShownAt == null ||
    now.difference(lastShownAt) >= UpdateCheck.suggestEvery;

/// Where [UpdateCheck] gets its facts; swapped out in tests.
abstract class UpdateSources {
  Future<String> appVersion();
  Future<BackendReply> backend(String appVersion);

  /// Null when the store has nothing newer — or can't tell.
  Future<StoreUpdate?> store(String appVersion);

  String get fallbackStoreUrl;
}

class LiveUpdateSources implements UpdateSources {
  static const _appStoreId = '6791101190';

  PackageInfo? _info;

  Future<PackageInfo> _package() async =>
      _info ??= await PackageInfo.fromPlatform();

  @override
  Future<String> appVersion() async => (await _package()).version;

  // Its own Dio: the endpoint is public, and the auth interceptors would turn
  // a logged-out driver's check into a refresh/logout round trip.
  Dio _dio({String? baseUrl}) => Dio(
    BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
    ),
  );

  @override
  Future<BackendReply> backend(String appVersion) async {
    try {
      final res = await _dio(baseUrl: EnvironmentConfig.apiUrl).get(
        Endpoints.configVersion,
        queryParameters: {
          'app': 'driver',
          'platform': Platform.isIOS ? 'ios' : 'android',
          'app_version': appVersion,
        },
      );
      final raw = res.data;
      final data = raw is String ? jsonDecode(raw) : raw;
      if (data is! Map) return const BackendReply.refused();
      return BackendReply.answered(VersionAnswer.fromJson(data));
    } on DioException catch (e) {
      return e.response == null
          ? const BackendReply.offline()
          : const BackendReply.refused();
    } catch (_) {
      return const BackendReply.refused();
    }
  }

  @override
  Future<StoreUpdate?> store(String appVersion) async {
    try {
      if (Platform.isIOS) return await _appStore(appVersion);
      if (Platform.isAndroid) return await _playStore();
    } catch (e) {
      // Offline, not on the store yet, or a sideloaded build Play doesn't own.
      debugPrint('Update check: store lookup skipped: $e');
    }
    return null;
  }

  Future<StoreUpdate?> _appStore(String appVersion) async {
    final info = await _package();
    final res = await _dio().get(
      'https://itunes.apple.com/lookup',
      queryParameters: {'bundleId': info.packageName, 'country': 'th'},
    );
    final raw = res.data;
    final data = raw is String ? jsonDecode(raw) : raw;
    final results = data is Map ? data['results'] : null;
    if (results is! List || results.isEmpty) return null;
    final app = results.first as Map;
    final version = app['version']?.toString();
    if (version == null || !isNewerVersion(version, appVersion)) return null;
    return StoreUpdate(
      storeUrl: app['trackViewUrl']?.toString() ?? fallbackStoreUrl,
      storeVersion: version,
    );
  }

  Future<StoreUpdate?> _playStore() async {
    final update = await InAppUpdate.checkForUpdate();
    if (update.updateAvailability != UpdateAvailability.updateAvailable) {
      return null;
    }
    return StoreUpdate(
      storeUrl: fallbackStoreUrl,
      playImmediate: update.immediateUpdateAllowed,
    );
  }

  @override
  String get fallbackStoreUrl {
    if (!kIsWeb && Platform.isIOS) {
      return 'https://apps.apple.com/th/app/id$_appStoreId';
    }
    final id = _info?.packageName ?? 'com.massapp.massdrive';
    return 'https://play.google.com/store/apps/details?id=$id';
  }
}

/// App-wide update state, a plain singleton like [AccountStatusNotifier] so
/// the router can listen to it.
///
/// [forced] holds the app on `/force-update` (see the router's redirect);
/// [suggestion] is a pending "update available" dialog for [UpdateListener].
/// Every failure leaves both empty: a broken check must never lock drivers
/// out.
class UpdateCheck extends ChangeNotifier {
  UpdateCheck({
    UpdateSources? sources,
    DateTime Function()? clock,
    bool? enabled,
  }) : _sources = sources ?? LiveUpdateSources(),
       _clock = clock ?? DateTime.now,
       // Local debug runs aren't store builds; don't block development.
       _enabled = enabled ?? !(kIsWeb || kDebugMode);

  static final UpdateCheck instance = UpdateCheck();

  /// Re-check on resume once the last check is older than this.
  static const recheckAfter = Duration(hours: 6);
  static const suggestEvery = Duration(hours: 24);

  static const _cacheKey = 'update_check.answer';
  static const _suggestVersionKey = 'update_check.suggest_version';
  static const _suggestAtKey = 'update_check.suggest_at';

  final UpdateSources _sources;
  final DateTime Function() _clock;
  final bool _enabled;

  UpdatePrompt? _forced;
  DateTime? _lastCheck;
  Future<void>? _running;

  UpdatePrompt? get forced => _forced;

  final ValueNotifier<UpdatePrompt?> suggestion = ValueNotifier(null);

  /// Cold start: always check.
  Future<void> check() => _running ??= _check().whenComplete(() {
    _running = null;
  });

  /// Resume: check only when the last one is stale.
  Future<void> checkIfStale() {
    final last = _lastCheck;
    if (last != null && _clock().difference(last) < recheckAfter) {
      return Future.value();
    }
    return check();
  }

  /// Re-run the router's redirect, e.g. once a call that held it off is over.
  void reapply() {
    if (_forced != null) notifyListeners();
  }

  Future<void> _check() async {
    if (!_enabled) return;
    _lastCheck = _clock();
    try {
      final version = await _sources.appVersion();
      final replies = await Future.wait<Object?>([
        _sources.backend(version),
        _sources.store(version).catchError((_) => null),
      ]);
      final backend = replies[0] as BackendReply;
      final store = replies[1] as StoreUpdate?;

      final prefs = await SharedPreferences.getInstance();
      final (cached, cachedFor) = _readCache(prefs);
      if (backend.answer case final answer?) {
        await prefs.setString(
          _cacheKey,
          jsonEncode({'app_version': version, 'answer': answer.toJson()}),
        );
      }

      final prompt = decideUpdate(
        appVersion: version,
        backend: backend,
        fallbackStoreUrl: _sources.fallbackStoreUrl,
        cached: cached,
        cachedForVersion: cachedFor,
        store: store,
      );
      _setForced(prompt != null && prompt.force ? prompt : null);
      if (prompt != null && !prompt.force) {
        await _offerSuggestion(prompt, prefs);
      } else {
        suggestion.value = null;
      }
    } catch (e) {
      debugPrint('Update check skipped: $e');
    }
  }

  (VersionAnswer?, String?) _readCache(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return (null, null);
      final json = jsonDecode(raw) as Map;
      return (
        VersionAnswer.fromJson(json['answer'] as Map),
        json['app_version']?.toString(),
      );
    } catch (_) {
      return (null, null);
    }
  }

  void _setForced(UpdatePrompt? prompt) {
    final changed = (_forced == null) != (prompt == null);
    _forced = prompt;
    if (changed) notifyListeners();
  }

  Future<void> _offerSuggestion(
    UpdatePrompt prompt,
    SharedPreferences prefs,
  ) async {
    final at = prefs.getInt(_suggestAtKey);
    final show = shouldShowSuggestion(
      version: prompt.latestVersion ?? '',
      now: _clock(),
      lastVersion: prefs.getString(_suggestVersionKey),
      lastShownAt: at == null ? null : DateTime.fromMillisecondsSinceEpoch(at),
    );
    if (show) suggestion.value = prompt;
  }

  /// The dialog for [prompt] was shown: start its 24 h quiet period.
  Future<void> markSuggestionShown(UpdatePrompt prompt) async {
    if (identical(suggestion.value, prompt)) suggestion.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_suggestVersionKey, prompt.latestVersion ?? '');
      await prefs.setInt(_suggestAtKey, _clock().millisecondsSinceEpoch);
    } catch (_) {}
  }
}
