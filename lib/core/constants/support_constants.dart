/// Driver support contact details.
class SupportConstant {
  const SupportConstant._();

  /// Call-center number the driver dials from the help sheet.
  ///
  /// Populated at runtime from `GET /api/config/support` (`support_phone`) via
  /// [loadSupportConfig] — never hardcoded, so ops can change the number without
  /// a release. Stays empty until the config loads; the UI checks
  /// [hasCallCenter] and tells the driver it is unavailable rather than dialing
  /// something wrong.
  static String callCenterNumber = '';

  static bool get hasCallCenter => callCenterNumber.trim().isNotEmpty;

  /// Digits only, for the `tel:` URI.
  static String get callCenterDialable =>
      callCenterNumber.replaceAll(RegExp(r'[^0-9+]'), '');
}
