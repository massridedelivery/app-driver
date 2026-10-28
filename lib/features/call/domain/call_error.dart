/// A refused or failed calls request: the HTTP status (null when the request
/// never got an answer) and the backend's `code`
/// (`{"error": "...", "code": "CALL_BUSY"}`).
class CallError implements Exception {
  const CallError({this.status, this.code});

  final int? status;
  final String? code;

  @override
  String toString() => 'CallError(status: $status, code: $code)';
}

/// What the app does about a [CallError]: the Thai line to show, and whether
/// to hide this order's call button / re-read the calling settings. Never a
/// retry loop.
class CallErrorOutcome {
  const CallErrorOutcome(
    this.message, {
    this.hideButton = false,
    this.refreshSettings = false,
  });

  final String message;
  final bool hideButton;
  final bool refreshSettings;
}

CallErrorOutcome callErrorOutcome(CallError e) {
  switch (e.code) {
    case 'CALL_BUSY':
      return const CallErrorOutcome('ลูกค้าไม่ว่าง ลองใหม่อีกครั้ง');
    case 'CALL_NOT_ALLOWED':
      // No driver yet, cancelled, or finished more than 24h ago.
      return const CallErrorOutcome(
        'ไม่สามารถโทรหาลูกค้าในงานนี้ได้แล้ว',
        hideButton: true,
      );
    case 'CALL_BLOCKED':
      return const CallErrorOutcome('ไม่สามารถโทรได้');
    case 'CALL_DISABLED':
      return const CallErrorOutcome(
        'ระบบโทรในแอปปิดให้บริการชั่วคราว',
        hideButton: true,
        refreshSettings: true,
      );
    case 'CALL_ENDED':
      return const CallErrorOutcome('สายนี้สิ้นสุดแล้ว');
  }
  if (e.status == 404) {
    return const CallErrorOutcome('ไม่พบงานนี้ในบัญชีของคุณ', hideButton: true);
  }
  if (e.status == null) {
    return const CallErrorOutcome(
      'เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาตรวจสอบสัญญาณแล้วลองใหม่',
    );
  }
  return const CallErrorOutcome('โทรไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
}
