import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Which build of the app is calling, sent on every API request so the back
/// office can see each account's version (and decide on forced updates):
///
///   X-App-Version:  1.0.2+143   (PackageInfo version + "+" + build number)
///   X-App-Platform: ios | android
///   X-Device-ID:    the device id the app also sends as `device_id` when it
///                   asks for a sign-in OTP (Android `androidInfo.id`, iOS
///                   `identifierForVendor`); loans keep it as evidence of
///                   the acceptance. Best-effort: left out when unknown.
///
/// Read once at startup ([load]); nothing about the user goes in these
/// headers.
class AppClient {
  AppClient._();

  static const versionHeader = 'X-App-Version';
  static const platformHeader = 'X-App-Platform';
  static const deviceIdHeader = 'X-Device-ID';

  static String? _version;
  static String? _deviceId;

  /// Reads the package and device info once. A failure leaves that header
  /// unsent.
  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _version = appVersionHeaderOf(info.version, info.buildNumber);
    } catch (e) {
      debugPrint('AppClient: package info unavailable: $e');
    }
    try {
      if (!kIsWeb && Platform.isAndroid) {
        _deviceId = deviceIdHeaderOf((await DeviceInfoPlugin().androidInfo).id);
      } else if (!kIsWeb && Platform.isIOS) {
        _deviceId = deviceIdHeaderOf(
          (await DeviceInfoPlugin().iosInfo).identifierForVendor,
        );
      }
    } catch (e) {
      // Some device images throw from inside the plugin; the id is optional.
      debugPrint('AppClient: device id unavailable: $e');
    }
  }

  /// "1.0.2+143", or null before [load] or when the package info is unusable.
  static String? get version => _version;

  static String get platform {
    if (kIsWeb) return 'web';
    return Platform.isIOS ? 'ios' : 'android';
  }

  /// The headers; the version and the device id only once they are known.
  static Map<String, String> get headers => {
    versionHeader: ?_version,
    platformHeader: platform,
    deviceIdHeader: ?_deviceId,
  };

  @visibleForTesting
  static set debugVersion(String? value) => _version = value;

  @visibleForTesting
  static set debugDeviceId(String? value) => _deviceId = value;
}

/// The device id as a header value: trimmed, printable ASCII (a header can't
/// carry anything else), at most 128 characters as the server keeps it. Null
/// when there is nothing usable.
String? deviceIdHeaderOf(String? id) {
  final v = id?.trim() ?? '';
  if (v.isEmpty || !RegExp(r'^[\x20-\x7E]+$').hasMatch(v)) return null;
  return v.length > 128 ? v.substring(0, 128) : v;
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
