/// Driver support contact details.
class SupportConstant {
  const SupportConstant._();

  /// Call-center number the driver dials from the help sheet.
  ///
  /// Empty until the real number is known — the UI checks [hasCallCenter] and
  /// tells the driver it is unavailable rather than dialing something wrong.
  static const String callCenterNumber = '';

  static bool get hasCallCenter => callCenterNumber.trim().isNotEmpty;

  /// Digits only, for the `tel:` URI.
  static String get callCenterDialable =>
      callCenterNumber.replaceAll(RegExp(r'[^0-9+]'), '');
}
