import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/services/push_notification_service.dart';
import 'package:massdrive/features/app_popup/data/popup_store.dart';
import 'package:massdrive/features/app_popup/domain/app_popup.dart';
import 'package:massdrive/features/app_popup/presentation/app_popup_dialog.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/router/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

/// The launch pop-up: fetched when the verified home is up and on every
/// return to the foreground, never blocking anything — any error means no
/// pop-up. At most one per launch, the first item not dismissed.
class AppPopups {
  AppPopups({
    Future<List<AppPopup>> Function()? fetch,
    PopupStore store = const PopupStore(),
    Future<bool> Function(BuildContext, AppPopup)? precache,
  }) : _fetch = fetch ?? _fetchActive,
       _store = store,
       _precache = precache ?? _precacheImage;

  static final AppPopups instance = AppPopups();

  final Future<List<AppPopup>> Function() _fetch;
  final PopupStore _store;
  final Future<bool> Function(BuildContext, AppPopup) _precache;

  PopupDismissals? _dismissals;
  bool _busy = false;
  bool _shownThisLaunch = false;

  /// Shows the next pop-up over [context]'s route, if it is the top route.
  Future<void> maybeShow(BuildContext context) async {
    if (_busy || _shownThisLaunch) return;
    if (!SessionNotifier.instance.isAuthenticated) return;
    _busy = true;
    try {
      final List<AppPopup> items;
      try {
        items = await _fetch();
      } catch (_) {
        return;
      }
      final d = _dismissals ??= PopupDismissals(await _store.read());
      if (d.prune(items)) unawaited(_store.write(d.dismissed));
      final next = d.next(items);
      if (next == null || !context.mounted) return;
      // Don't paint over a job, a dialog or another screen.
      if (ModalRoute.of(context)?.isCurrent != true) return;
      if (!await _precache(context, next)) return;
      if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) {
        return;
      }

      _shownThisLaunch = true;
      final outcome = await showAppPopup(context, next);
      if (d.close(next, outcome)) unawaited(_store.write(d.dismissed));
      final action = next.action;
      if (outcome.tapped && action != null && context.mounted) {
        await _open(context, action);
      }
    } finally {
      _busy = false;
    }
  }

  static Future<List<AppPopup>> _fetchActive() async {
    final res = await getIt<Dio>()
        .get<dynamic>(Endpoints.driverPopupsActive)
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return const [];
    return AppPopup.listFrom(res.data);
  }

  /// The image loads before the card shows; one that can't load is skipped
  /// (and not counted as seen).
  static Future<bool> _precacheImage(BuildContext context, AppPopup p) async {
    var ok = true;
    try {
      await precacheImage(
        NetworkImage(p.imageUrl),
        context,
        onError: (_, _) => ok = false,
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      return false;
    }
    return ok;
  }

  Future<void> _open(BuildContext context, PopupAction action) async {
    switch (action.type) {
      case PopupActionType.url:
        final uri = Uri.tryParse(action.value);
        if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
          return;
        }
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      case PopupActionType.deeplink:
        // Same paths as push deeplinks; an unknown one stays on home.
        final target = resolveNotificationRoute(
          action.value,
          AppRouter.isKnownLocation,
        );
        if (target != null && context.mounted) {
          unawaited(context.push(target));
        }
    }
  }
}
