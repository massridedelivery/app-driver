import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Review state of a MANUAL top-up slip (GET /api/driver/settle-debt/requests).
enum TopupRequestStatus {
  pending,
  approved,
  rejected,
  unknown;

  static TopupRequestStatus parse(String? raw) => switch (raw?.toLowerCase()) {
    'pending' || 'pending_review' => TopupRequestStatus.pending,
    'approved' => TopupRequestStatus.approved,
    'rejected' => TopupRequestStatus.rejected,
    _ => TopupRequestStatus.unknown,
  };

  String get label => switch (this) {
    TopupRequestStatus.pending => 'รอตรวจสอบ',
    TopupRequestStatus.approved => 'อนุมัติแล้ว',
    TopupRequestStatus.rejected => 'ไม่อนุมัติ',
    TopupRequestStatus.unknown => 'ไม่ทราบสถานะ',
  };
}

/// One submitted transfer slip and where its review stands.
@immutable
class TopupRequest {
  final String id;
  final String intentId;
  final double amount;
  final TopupRequestStatus status;

  /// Always set by the admin when rejecting; shown to the driver as-is.
  final String? rejectionReason;
  final String? slipImageUrl;
  final DateTime? createdAt;
  final DateTime? processedAt;

  const TopupRequest({
    required this.id,
    required this.intentId,
    required this.amount,
    required this.status,
    this.rejectionReason,
    this.slipImageUrl,
    this.createdAt,
    this.processedAt,
  });

  factory TopupRequest.fromJson(Map<String, dynamic> j) {
    String? text(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return TopupRequest(
      id: j['id']?.toString() ?? '',
      intentId: j['intent_id']?.toString() ?? '',
      amount: (j['amount'] as num?)?.toDouble() ?? 0,
      status: TopupRequestStatus.parse(j['status']?.toString()),
      rejectionReason: text(j['rejection_reason']),
      slipImageUrl: text(j['slip_image_url']),
      createdAt: DateTime.tryParse(
        j['created_at']?.toString() ?? '',
      )?.toLocal(),
      processedAt: DateTime.tryParse(
        j['processed_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}

/// MANUAL transfer can't be used: the company hasn't set its receiving bank
/// account yet (POST /settle-debt answers 400). The app hides that option.
class ManualTopupUnavailable implements Exception {
  const ManualTopupUnavailable(this.serverMessage);

  final String? serverMessage;

  static const message =
      'ยังไม่เปิดให้โอนเงินเข้าบัญชี กรุณาชำระผ่าน PromptPay';

  @override
  String toString() => 'Exception: $message';
}

/// A refused slip submission, translated for the driver.
class SlipSubmitException implements Exception {
  const SlipSubmitException(this.statusCode, this.code);

  final int? statusCode;
  final String? code;

  factory SlipSubmitException.from(DioException e) {
    final data = e.response?.data;
    return SlipSubmitException(
      e.response?.statusCode,
      data is Map ? data['code']?.toString() : null,
    );
  }

  /// One transfer = one slip; a pending/approved slip already exists.
  bool get alreadySubmitted =>
      code == 'SLIP_ALREADY_SUBMITTED' || statusCode == 409;

  /// The 24-hour transfer session expired (or doesn't exist).
  bool get sessionExpired => !alreadySubmitted && statusCode == 400;

  String get message {
    if (alreadySubmitted) {
      return 'ส่งสลิปของรายการนี้ไปแล้ว อยู่ระหว่างการตรวจสอบ';
    }
    if (sessionExpired) {
      return 'รายการโอนนี้หมดอายุแล้ว (เกิน 24 ชั่วโมง) กรุณาเริ่มรายการโอนใหม่';
    }
    return 'ส่งสลิปไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
  }

  @override
  String toString() => 'Exception: $message';
}

/// Bumped when a `topup_approved` / `topup_rejected` push arrives so the
/// wallet balance, COD status and the slip list refresh.
class TopupUpdates extends ChangeNotifier {
  TopupUpdates._();
  static final TopupUpdates instance = TopupUpdates._();

  void notifyChanged() => notifyListeners();
}
