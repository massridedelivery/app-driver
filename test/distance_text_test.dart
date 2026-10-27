import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/distance_text.dart';

void main() {
  test('metres under a kilometre, to the nearest 10 m', () {
    expect(formatDistanceTh(0), '0 ม.');
    expect(formatDistanceTh(4), '0 ม.');
    expect(formatDistanceTh(568), '570 ม.');
    expect(formatDistanceTh(994), '990 ม.');
  });

  test('kilometres with one decimal from ~1 km', () {
    expect(formatDistanceTh(995), '1.0 กม.');
    expect(formatDistanceTh(3712), '3.7 กม.');
    expect(formatDistanceTh(12345), '12.3 กม.');
  });
}
