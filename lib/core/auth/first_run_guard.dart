import 'package:flutter/foundation.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iOS keeps Keychain items after an app is uninstalled, so a stored access
/// token can survive a delete-and-reinstall (or moving between builds that
/// share a bundle id) and make the app cold-start straight into a stale
/// session. On the first launch after install we clear secure storage once,
/// gated by a SharedPreferences flag — SharedPreferences *is* wiped on
/// uninstall — so a fresh install always starts logged out.
class FirstRunGuard {
  static const _hasRunBeforeKey = 'has_run_before';

  /// Clears secure storage exactly once, the first time the app runs after a
  /// fresh install. Best-effort: any failure is swallowed so it can never block
  /// startup.
  static Future<void> clearSecureStorageOnFreshInstall() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_hasRunBeforeKey) ?? false) return;

    try {
      await SecureStorageManager().deleteAll();
    } catch (e) {
      debugPrint('FirstRunGuard: secure storage clear failed: $e');
    }
    await prefs.setBool(_hasRunBeforeKey, true);
  }
}
