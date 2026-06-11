import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/string_util.dart';

void main() {
  group('StringBlinding Extension Tests', () {
    test('blindName masks name correctly', () {
      expect('ธนนันต์'.blindName(), 'ธน*****');
      expect('ธนนันต์ อนุรักษ์ศิลปกุล'.blindName(), 'ธน***** อน******');
      expect('(MB)ธนนันต์ อนุรักษ์ศิลปกุล'.blindName(), '(MB)ธน***** อน******');
      expect('Ab'.blindName(), 'Ab**');
      expect(''.blindName(), '');
    });

    test('blindPhone masks phone numbers correctly', () {
      expect('+66 892616445'.blindPhone(), '+66 89***6445');
      expect('+66892616445'.blindPhone(), '+66 89***6445');
      expect('0892616445'.blindPhone(), '089***6445');
      expect('123'.blindPhone(), '123');
      expect(''.blindPhone(), '');
    });

    test('blindPlate masks license plates correctly', () {
      expect('8กส418'.blindPlate(), '8กส***');
      expect('8ก'.blindPlate(), '8*');
      expect(''.blindPlate(), '');
    });

    test('blindEmailOrUuid masks emails and UUIDs correctly', () {
      expect('user@example.com'.blindEmailOrUuid(), 'us***@example.com');
      expect('ab@test.com'.blindEmailOrUuid(), 'a*@test.com');
      expect('dad534d3-8046-437e-96b4-c13ee6b23fd'.blindEmailOrUuid(), 'dad5***23fd');
      expect('12345678'.blindEmailOrUuid(), '12****78');
      expect(''.blindEmailOrUuid(), '');
    });
  });
}
