import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';

/// Driver preference: when a job offer's countdown elapses, accept it
/// automatically (`true`) or let it expire / auto-cancel (`false`).
///
/// Local-only — there is no API for this. Persisted in GetStorage and defaults
/// **OFF** on first launch, so a driver never auto-accepts until they opt in.
class AutoAcceptController extends Notifier<bool> {
  static const _key = 'auto_accept_jobs';

  GetStorage? _box;

  @override
  bool build() {
    try {
      _box = GetStorage();
    } catch (_) {
      _box = null;
    }
    return _box?.read<bool>(_key) ?? false;
  }

  void setEnabled(bool value) {
    state = value;
    _box?.write(_key, value);
  }
}

final autoAcceptProvider = NotifierProvider<AutoAcceptController, bool>(
  AutoAcceptController.new,
);
