enum StartupDestination { onboarding, home }

/// Outcome of app startup. When [resumeRoute] is set, the app should navigate
/// straight to an in-progress job (found on cold launch) instead of the normal
/// [destination] landing.
class StartupResult {
  final StartupDestination destination;
  final String? resumeRoute;
  final Object? resumeExtra;

  const StartupResult(
    this.destination, {
    this.resumeRoute,
    this.resumeExtra,
  });

  static const onboarding = StartupResult(StartupDestination.onboarding);
  static const home = StartupResult(StartupDestination.home);
}
