// handle deeplink, onelink, internal link
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/enum/links.dart';
import 'package:massdrive/features/dependency_injection.dart';

enum NavigationMethod { go, push, pushReplacement }

@singleton
class DeeplinkManager {
  var schema = 'treg://';
  var host = 'treg';

  /// [destinationType] possible values:
  /// - `external` → เปิดลิงก์ภายนอก เช่น URL
  /// - `internal` → เปิดลิงก์ภายใน app
  /// - `deeplink` → เปิด deeplink
  /// - `scheme` → เปิด scheme link
  void handleLink(
    DestinationType destinationType,
    String destinationLink, [
    NavigationMethod method = NavigationMethod.go,
    Object? extra,
  ]) {
    switch (destinationType) {
      case DestinationType.external:
        _openExternal(destinationLink, extra);
        break;
      case DestinationType.internal:
        _openInternalLink(destinationLink, method, extra);
        break;
      case DestinationType.deeplink || DestinationType.scheme:
        _openInternalLink(destinationLink, method, extra);
        break;
    }
  }

  Future<void> openLink(Uri uri, NavigationMethod method, Object? extra) async {
    String path = uri.path;
    switch (path) {
      case _
          when path.contains(AppRoutes.checkoutName) ||
              uri.toString().contains(AppRoutes.checkoutName):
        _handleWithQueryParams(AppRoutes.checkoutPath, uri, method, extra);
      case _ when path.contains(AppRoutes.checkoutPath):
        _handleWithQueryParams(AppRoutes.checkoutPath, uri, method, extra);
      default:
        _handleMethod(path, method, extra: extra);
    }
  }

  // MARK: Pop
  /// Pop all routes until the root route is reached.
  void popToRoot(BuildContext context, {bool rootNavigator = false}) {
    final navigator = Navigator.maybeOf(context, rootNavigator: rootNavigator);
    if (navigator != null && navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  // MARK: Pop until
  /// Pop until the route with the given name is reached.
  ///
  /// Example:
  /// Profile -> ProfileEdited -> ProfileInfo > SetPassword
  /// ```dart
  /// DeeplinkManager().popTo(context, name: AppRoutes.profileEditedName);
  /// ```
  void popTo(
    BuildContext context, {
    required String name,
    bool rootNavigator = false,
  }) {
    final navigator = Navigator.maybeOf(context, rootNavigator: rootNavigator);
    if (navigator != null && navigator.canPop()) {
      final found = navigator.widget.pages.any((e) => e.name == name);
      if (found) {
        navigator.popUntil(ModalRoute.withName(name));
      } else {
        navigator.pop();
      }
    }
  }

  /// [destinationPath] possible values: `/home` or `/product`
  void _openInternalLink(
    String destinationPath,
    NavigationMethod method,
    Object? extra,
  ) {
    var uri = Uri.parse(schema + host + destinationPath);
    openLink(uri, method, extra);
  }

  void _handleWithQueryParams(
    String path,
    Uri uri,
    NavigationMethod method,
    Object? extra,
  ) {
    final queryParameters = uri.queryParameters;
    _handleMethod(
      path,
      method,
      extra: queryParameters.isNotEmpty ? queryParameters : extra,
    );
  }

  void _handleMethod(String path, NavigationMethod method, {Object? extra}) {
    final router = getIt<GoRouter>();
    switch (method) {
      case NavigationMethod.go:
        router.go(path, extra: extra);
        break;
      case NavigationMethod.push:
        router.push(path, extra: extra);
        break;
      case NavigationMethod.pushReplacement:
        router.pushReplacement(path, extra: extra);
        break;
    }
  }

  void _openExternal(String url, Object? extra) {
    final String title = (extra as String?) ?? '';
    getIt<GoRouter>().pushNamed(
      AppRoutes.webViewName,
      extra: (url: url, title: title),
    );
  }
}
