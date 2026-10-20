import 'dart:async';

import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One highlighted spot in the home tour.
class CoachStep {
  final GlobalKey target;
  final String title;
  final String body;

  /// Corner radius of the spotlight; a pill or a circle for round targets.
  final double radius;

  const CoachStep({
    required this.target,
    required this.title,
    required this.body,
    this.radius = 16,
  });
}

/// The home tour (design 1): the screen dims, a spotlight opens on one control
/// at a time, and a white card with an arrow explains it — "ข้าม", "1/4",
/// "ถัดไป". Shown once per install; Settings can replay it.
class HomeCoachMarks {
  HomeCoachMarks._();

  static const seenKey = 'home_coach_seen_v1';

  static final onlineButton = GlobalKey(debugLabel: 'coach-online');
  static final statusCard = GlobalKey(debugLabel: 'coach-status');
  static final incomeMenu = GlobalKey(debugLabel: 'coach-income');
  static final serviceMenu = GlobalKey(debugLabel: 'coach-service');

  static List<CoachStep> get steps => [
    CoachStep(
      target: onlineButton,
      title: 'กดเพื่อเริ่มรับงาน',
      body:
          'เปิด “พร้อมรับงาน” เมื่อพร้อมขับ ระบบจะส่งงานใกล้คุณมาให้ทันที '
          'กดอีกครั้งเพื่อปิดรับงาน',
      radius: 40,
    ),
    CoachStep(
      target: statusCard,
      title: 'สถานะการรับงาน',
      body: 'ดูได้ตรงนี้ว่าระบบกำลังค้นหางานให้คุณ หรือคุณปิดรับงานอยู่',
      radius: 12,
    ),
    CoachStep(
      target: incomeMenu,
      title: 'รายได้ของคุณ',
      body: 'ดูรายได้วันนี้ ประวัติงาน เติมเครดิต และถอนเงินเข้าบัญชี',
      radius: 40,
    ),
    CoachStep(
      target: serviceMenu,
      title: 'ประเภทบริการ',
      body: 'เลือกประเภทงานที่ต้องการรับ เช่น เรียกรถ ส่งอาหาร ส่งของ',
      radius: 40,
    ),
  ];

  static bool _showing = false;

  /// Shows the tour unless this install has seen it. Waits a moment so the
  /// bottom sheet has settled; skips quietly when a target isn't on screen.
  static Future<void> maybeShow(BuildContext context) async {
    if (_showing) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(seenKey) ?? false) return;
    } catch (_) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!context.mounted || _showing) return;
    final visible = steps.where((s) => s.target.currentContext != null);
    if (visible.length != steps.length) return;
    await show(context);
  }

  /// Plays the tour now and records it as seen, however it ends.
  static Future<void> show(BuildContext context) async {
    if (_showing) return;
    _showing = true;
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => CoachMarksOverlay(steps: steps),
        transitionBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      );
    } finally {
      _showing = false;
      unawaited(markSeen());
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(seenKey, true);
    } catch (_) {}
  }

  /// "ดูคำแนะนำอีกครั้ง": the next home visit plays the tour again.
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(seenKey);
    } catch (_) {}
  }
}

/// Dim layer with a spotlight on the current step's target and the white
/// explanation card. Pops itself after the last step or "ข้าม".
class CoachMarksOverlay extends StatefulWidget {
  final List<CoachStep> steps;

  const CoachMarksOverlay({super.key, required this.steps});

  @override
  State<CoachMarksOverlay> createState() => _CoachMarksOverlayState();
}

class _CoachMarksOverlayState extends State<CoachMarksOverlay> {
  int _index = 0;

  CoachStep get _step => widget.steps[_index];
  bool get _last => _index == widget.steps.length - 1;

  Rect? _targetRect() {
    final box = _step.target.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    // The dialog route fills the screen, so global == overlay coordinates.
    return (box.localToGlobal(Offset.zero) & box.size).inflate(6);
  }

  void _next() {
    if (_last) {
      Navigator.of(context).pop();
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rect = _targetRect();
    if (rect == null) {
      // Target left the screen (sheet dragged, route changed): end the tour.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    // Card above a target in the lower half, below one in the upper half.
    final above = rect.center.dy > size.height / 2;
    const side = 20.0;
    const arrow = 10.0;
    final arrowX = rect.center.dx.clamp(side + 24, size.width - side - 24);

    final card = _CoachCard(
      title: _step.title,
      body: _step.body,
      progress: '${_index + 1}/${widget.steps.length}',
      last: _last,
      onSkip: () => Navigator.of(context).pop(),
      onNext: _next,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              // Swallow taps on the dimmed map; only the card moves the tour.
              onTap: () {},
              child: CustomPaint(
                painter: _SpotlightPainter(
                  hole: RRect.fromRectAndRadius(
                    rect,
                    Radius.circular(_step.radius + 6),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: side,
            right: side,
            top: above ? null : rect.bottom + arrow + 4,
            bottom: above ? size.height - rect.top + arrow + 4 : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: above
                    ? rect.top - padding.top - 24
                    : size.height - rect.bottom - padding.bottom - 24,
              ),
              child: card,
            ),
          ),
          Positioned(
            left: arrowX - arrow,
            top: above ? rect.top - arrow - 5 : rect.bottom + 5,
            child: CustomPaint(
              size: const Size(arrow * 2, arrow),
              painter: _ArrowPainter(pointsDown: above),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final String title;
  final String body;
  final String progress;
  final bool last;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _CoachCard({
    required this.title,
    required this.body,
    required this.progress,
    required this.last,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFF8A8F98);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.label1.copyWith(
                color: const Color(0xFF111111),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: AppTypography.caption4.copyWith(
                color: const Color(0xFF555555),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (!last)
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text(
                      'ข้าม',
                      style: AppTypography.caption3.copyWith(color: muted),
                    ),
                  ),
                const Spacer(),
                Text(
                  progress,
                  style: AppTypography.caption3.copyWith(color: muted),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    last ? 'เริ่มใช้งาน' : 'ถัดไป',
                    style: AppTypography.caption3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final RRect hole;

  const _SpotlightPainter({required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Path()..addRect(Offset.zero & size);
    final cut = Path()..addRRect(hole);
    canvas.drawPath(
      Path.combine(PathOperation.difference, dim, cut),
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole;
}

class _ArrowPainter extends CustomPainter {
  final bool pointsDown;

  const _ArrowPainter({required this.pointsDown});

  @override
  void paint(Canvas canvas, Size size) {
    final path = pointsDown
        ? (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width, 0)
            ..lineTo(size.width / 2, size.height)
            ..close())
        : (Path()
            ..moveTo(0, size.height)
            ..lineTo(size.width, size.height)
            ..lineTo(size.width / 2, 0)
            ..close());
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.pointsDown != pointsDown;
}
