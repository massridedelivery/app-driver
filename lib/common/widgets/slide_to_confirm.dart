import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_typography.dart';

/// A pill the driver drags left → right to confirm a step (รับงาน, ถึงจุดรับ,
/// ส่งถึงแล้ว, รับเงินแล้ว). Harder to hit by accident than a tap while
/// driving. Past [threshold] of the track it fires [onConfirmed] once and
/// snaps back; released earlier, it springs back without firing.
///
/// Give it a new [key] when the step changes so the knob starts at the left.
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    required this.color,
    this.enabled = true,
    this.loading = false,
    this.threshold = 0.82,
    this.height = 56,
  });

  final String label;
  final VoidCallback onConfirmed;
  final Color color;
  final bool enabled;

  /// Shows a spinner on the knob and ignores drags (a request is in flight).
  final bool loading;
  final double threshold;
  final double height;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _back;

  @override
  void initState() {
    super.initState();
    // Created here, not lazily: a widget disposed before its first drag
    // would otherwise build the controller inside dispose().
    _back = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() => setState(() => _dx = _from * (1 - _back.value)));
  }

  double _dx = 0;
  double _from = 0;

  bool get _active => widget.enabled && !widget.loading;

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _springBack() {
    _from = _dx;
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final pad = 6.0;
    final knob = widget.height - pad * 2;
    final color = _active ? widget.color : widget.color.withValues(alpha: 0.5);
    return LayoutBuilder(
      builder: (context, box) {
        final maxDx = (box.maxWidth - knob - pad * 2).clamp(
          0.0,
          double.infinity,
        );
        final t = maxDx == 0 ? 0.0 : _dx / maxDx;
        return Semantics(
          button: true,
          enabled: _active,
          label: widget.label,
          // Screen readers can't drag: a double-tap confirms.
          onTap: _active ? widget.onConfirmed : null,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(widget.height / 2),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Label fades as the knob covers it.
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(left: knob + pad * 2, right: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Opacity(
                        opacity: (1 - t * 1.4).clamp(0.0, 1.0),
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label2.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: pad + _dx,
                  child: GestureDetector(
                    onHorizontalDragStart: _active ? (_) => _back.stop() : null,
                    onHorizontalDragUpdate: _active
                        ? (d) => setState(
                            () => _dx = (_dx + d.delta.dx).clamp(0.0, maxDx),
                          )
                        : null,
                    onHorizontalDragEnd: _active
                        ? (_) {
                            if (maxDx > 0 && _dx / maxDx >= widget.threshold) {
                              setState(() => _dx = maxDx);
                              widget.onConfirmed();
                            }
                            _springBack();
                          }
                        : null,
                    child: Container(
                      width: knob,
                      height: knob,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: widget.loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: widget.color,
                              ),
                            )
                          : Icon(
                              Icons.keyboard_double_arrow_right_rounded,
                              color: widget.color,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
