import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Which build of the app is calling, sent on every API request so the back
/// office can see each account's version (and decide on forced updates):
///
///   X-App-Version:  1.0.2+143   (PackageInfo version + "+" + build number)
///   X-App-Platform: ios | android
///
/// Read once at startup ([load]); nothing about the device or the user goes
/// in these headers.
class AppClient {
  AppClient._();

  static const versionHeader = 'X-App-Version';
  static const platformHeader = 'X-App-Platform';

  static String? _version;

  /// Reads the package info once. A failure leaves the version unsent.
  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _version = appVersionHeaderOf(info.version, info.buildNumber);
    } catch (e) {
      debugPrint('AppClient: package info unavailable: $e');
    }
  }

  /// "1.0.2+143", or null before [load] or when the package info is unusable.
  static String? get version => _version;

  static String get platform {
    if (kIsWeb) return 'web';
    return Platform.isIOS ? 'ios' : 'android';
  }

  /// The two headers; the version only once it is known.
  static Map<String, String> get headers => {
    versionHeader: ?_version,
    platformHeader: platform,
  };

  @visibleForTesting
  static set debugVersion(String? value) => _version = value;
}

/// `<version>+<build>` as the server accepts it: plain printable ASCII, at
/// most 64 characters, starting with the numeric part. Null otherwise, so a
/// malformed value is never sent.
String? appVersionHeaderOf(String version, String buildNumber) {
  final v = version.trim();
  final b = buildNumber.trim();
  final value = b.isEmpty ? v : '$v+$b';
  if (value.length > 64) return null;
  if (!RegExp(r'^[0-9][\x21-\x7E]*$').hasMatch(value)) return null;
  return value;
}
