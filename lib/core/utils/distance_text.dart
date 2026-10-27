/// "570 ม." under a kilometre (to the nearest 10 m), "3.7 กม." from there.
String formatDistanceTh(double meters) {
  if (meters < 0 || meters.isNaN) return '';
  if (meters < 995) {
    final m = (meters / 10).round() * 10;
    return '$m ม.';
  }
  return '${(meters / 1000).toStringAsFixed(1)} กม.';
}
