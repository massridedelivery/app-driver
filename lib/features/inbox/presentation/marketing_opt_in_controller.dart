import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/features/inbox/data/inbox_api.dart';

@immutable
class MarketingOptIn {
  const MarketingOptIn({this.enabled = true, this.available = false});

  /// On by default (PDPA consent the driver can withdraw).
  final bool enabled;

  /// The backend answered `GET /api/notifications/prefs`. Before it ships
  /// (404) the switch shows on and can't be changed.
  final bool available;
}

/// "ข่าวสารและโปรโมชั่น" in settings: whether marketing campaigns reach this
/// driver. Per account; jobs, chat, calls and account pushes don't depend on
/// it.
class MarketingOptInController extends Notifier<MarketingOptIn> {
  InboxApi get _api => ref.read(inboxApiProvider);

  @override
  MarketingOptIn build() {
    Future.microtask(load);
    return const MarketingOptIn();
  }

  Future<void> load() async {
    // The provider is autoDispose: settings closed before the answer came
    // back left `ref` dead ("Cannot use the Ref … after it has been
    // disposed", a Crashlytics issue).
    if (!ref.mounted) return;
    MarketingOptIn next;
    try {
      next = MarketingOptIn(
        enabled: await _api.marketingOptIn(),
        available: true,
      );
    } catch (e) {
      debugPrint('Marketing opt-in: load failed: $e');
      next = const MarketingOptIn();
    }
    if (ref.mounted) state = next;
  }

  /// Flips at once; false (and back to the old value) if the backend refused.
  Future<bool> set(bool enabled) async {
    final before = state;
    if (!before.available || before.enabled == enabled) return true;
    state = MarketingOptIn(enabled: enabled, available: true);
    try {
      final saved = await _api.setMarketingOptIn(enabled);
      if (ref.mounted) state = MarketingOptIn(enabled: saved, available: true);
      return true;
    } catch (e) {
      debugPrint('Marketing opt-in: save failed: $e');
      if (ref.mounted) state = before;
      return false;
    }
  }
}

final marketingOptInProvider =
    NotifierProvider.autoDispose<MarketingOptInController, MarketingOptIn>(
      MarketingOptInController.new,
    );
