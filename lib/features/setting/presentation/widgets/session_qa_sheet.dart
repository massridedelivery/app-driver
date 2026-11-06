import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/managers/api/refresh/app_dio_refreshtoken_interceptor.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/dependency_injection.dart';

/// "ทดสอบ session" for QA: opened by tapping the version label 7 times in
/// Settings. Starts refreshes on demand so the grace window can be tried
/// against an app kill, airplane mode or two refreshes at once. No token is
/// ever shown — only statuses and the access token's expiry.
Future<void> showSessionQaSheet(BuildContext context) {
  final interceptor = getIt<Dio>().interceptors
      .whereType<AppDioRefreshTokenInterceptor>()
      .firstOrNull;
  if (interceptor == null) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.palette.sheet,
    builder: (_) => SessionQaSheet(interceptor: interceptor),
  );
}

class SessionQaSheet extends StatefulWidget {
  const SessionQaSheet({super.key, required this.interceptor});

  final AppDioRefreshTokenInterceptor interceptor;

  @override
  State<SessionQaSheet> createState() => _SessionQaSheetState();
}

class _SessionQaSheetState extends State<SessionQaSheet> {
  final _log = <String>[];
  DateTime? _expiry;
  DateTime? _lostAt;
  Timer? _tick;
  bool _busy = false;

  static final _time = DateFormat('HH:mm:ss');

  AppDioRefreshTokenInterceptor get _i => widget.interceptor;

  @override
  void initState() {
    super.initState();
    _loadExpiry();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_lostAt != null && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _loadExpiry() async {
    final e = await _i.qaAccessExpiry();
    if (mounted) setState(() => _expiry = e);
  }

  void _add(String line) {
    if (!mounted) return;
    setState(() => _log.insert(0, '${_time.format(DateTime.now())}  $line'));
  }

  String _renewal(TokenRenewal r) => r.token != null
      ? 'สำเร็จ — ได้ token ใหม่ ยังล็อกอินอยู่'
      : r.sessionEnded
      ? 'Session หมด (401) — แอปจะพาไปหน้า login'
      : 'ยังไม่ได้คำตอบ (เน็ต/เซิร์ฟเวอร์) — เก็บ session ไว้';

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _add('ผิดพลาด: ${e.runtimeType}');
    } finally {
      await _loadExpiry();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshNow() => _run(() async {
    _add('Refresh ตอนนี้ …');
    final r = await _i.qaRefreshNow();
    if (r.token != null) _lostAt = null;
    _add(_renewal(r));
  });

  Future<void> _loseReply() => _run(() async {
    _add('ส่ง refresh แล้วทิ้งคำตอบ …');
    final status = await _i.qaRefreshDiscardingReply();
    _lostAt = status == 200 || status == 201 ? DateTime.now() : null;
    _add(
      status == null
          ? 'ไม่มีคำตอบ — ไม่ได้จำลองอะไร'
          : status == 200 || status == 201
          ? 'เซิร์ฟเวอร์ rotate แล้ว (200) คำตอบถูกทิ้ง — กด "Refresh ตอนนี้" ภายใน 60 วิ'
          : 'เซิร์ฟเวอร์ตอบ $status',
    );
  });

  Future<void> _race() => _run(() async {
    _add('ส่ง refresh พร้อมกัน 2 ครั้ง (token เดียวกัน) …');
    final r = await _i.qaRaceRefresh();
    _add(
      'ผล: ${r.first ?? 'ไม่มีคำตอบ'} / ${r.second ?? 'ไม่มีคำตอบ'}'
      '${r.samePair ? ' · ได้คู่เดียวกัน ✓' : ''}',
    );
  });

  Future<void> _doubleInApp() => _run(() async {
    _add('Refresh 2 ครั้งพร้อมกันผ่านแอป (ต้องส่งจริงแค่ครั้งเดียว) …');
    final rs = await Future.wait([_i.qaRefreshNow(), _i.qaRefreshNow()]);
    _add('1: ${_renewal(rs[0])}');
    _add('2: ${_renewal(rs[1])}');
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lostFor = _lostAt == null
        ? null
        : DateTime.now().difference(_lostAt!).inSeconds;
    Widget button(String label, String hint, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        onPressed: _busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption3.copyWith(
                color: p.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              hint,
              style: AppTypography.caption5.copyWith(color: p.textSecondary),
            ),
          ],
        ),
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ทดสอบ session (สำหรับทีมทดสอบ)',
              style: AppTypography.heading6.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              _expiry == null
                  ? 'Access token: อ่านวันหมดอายุไม่ได้'
                  : 'Access token หมดอายุ ${DateFormat('d MMM HH:mm', 'th_TH').format(_expiry!)}',
              style: AppTypography.caption4.copyWith(color: p.textSecondary),
            ),
            if (lostFor != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'คำตอบหายไปแล้ว $lostFor วิ'
                  '${lostFor > 60 ? ' — เกิน grace 60 วิ, refresh จะได้ 401' : ''}',
                  style: AppTypography.caption4.copyWith(
                    color: lostFor > 60
                        ? AppColors.foundationRed800
                        : AppColors.semanticSupportMintBgHigh,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            button(
              'Refresh ตอนนี้',
              'กดแล้วปัดปิดแอปทันที หรือเปิด airplane mode ระหว่างรอ แล้วเปิดใหม่',
              _refreshNow,
            ),
            button(
              'จำลองคำตอบหาย',
              'เซิร์ฟเวอร์ rotate แต่แอปไม่เก็บผล แล้วกด Refresh ตอนนี้ภายใน 60 วิ',
              _loseReply,
            ),
            button(
              'Refresh พร้อมกัน 2 ครั้ง (ตรงถึงเซิร์ฟเวอร์)',
              'token เดียวกัน 2 request — ต้องได้ 200 ทั้งคู่ คู่เดียวกัน',
              _race,
            ),
            button(
              'Refresh พร้อมกัน 2 ครั้ง (ผ่านแอป)',
              'แอปต้องรวมเป็น request เดียว ยังล็อกอินอยู่',
              _doubleInApp,
            ),
            if (_busy) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final line in _log)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        line,
                        style: AppTypography.caption5.copyWith(
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
