import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/friendly_error.dart';
import 'package:massdrive/features/income/domain/models/topup.dart';

void main() {
  test('request status + reason parsing', () {
    final r = TopupRequest.fromJson({
      'id': 'r1',
      'intent_id': 'manual_settlement_1',
      'amount': 300,
      'status': 'rejected',
      'rejection_reason': 'ยอดในสลิปไม่ตรงกับรายการ',
      'slip_image_url': 'https://example.com/s.jpg',
      'created_at': '2026-10-14T03:00:00Z',
    });
    expect(r.status, TopupRequestStatus.rejected);
    expect(r.status.label, 'ไม่อนุมัติ');
    expect(r.rejectionReason, 'ยอดในสลิปไม่ตรงกับรายการ');
    expect(TopupRequestStatus.parse('pending').label, 'รอตรวจสอบ');
    expect(
      TopupRequestStatus.parse('PENDING_REVIEW'),
      TopupRequestStatus.pending,
    );
  });

  test('a rejected slip can be resent only within 24h of sending it', () {
    TopupRequest at(String status, String created) => TopupRequest.fromJson({
      'id': 'r',
      'amount': 100,
      'status': status,
      'created_at': created,
    });
    final now = DateTime.utc(2026, 10, 14, 12);
    expect(
      at('rejected', '2026-10-14T03:00:00Z').canResubmit(now: now),
      isTrue,
    );
    expect(
      at('rejected', '2026-10-12T03:00:00Z').canResubmit(now: now),
      isFalse,
    );
    expect(
      at('pending', '2026-10-14T03:00:00Z').canResubmit(now: now),
      isFalse,
    );
  });

  test('slip errors by status/code', () {
    expect(
      const SlipSubmitException(409, 'SLIP_ALREADY_SUBMITTED').message,
      contains('ส่งสลิปของรายการนี้ไปแล้ว'),
    );
    expect(const SlipSubmitException(400, null).message, contains('หมดอายุ'));
    expect(const SlipSubmitException(500, null).message, contains('ไม่สำเร็จ'));
  });

  test('manual unavailable shows the PromptPay hint', () {
    expect(
      friendlyErrorMessage(const ManualTopupUnavailable('x')),
      ManualTopupUnavailable.message,
    );
  });
}
