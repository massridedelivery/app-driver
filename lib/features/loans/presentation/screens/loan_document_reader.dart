import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';
import 'package:massdrive/features/loans/presentation/widgets/loan_markdown.dart';
import 'package:massdrive/features/loans/presentation/widgets/loan_ui.dart';
import 'package:share_plus/share_plus.dart';

/// DocumentViewer (design 5C reader): one document full screen, Markdown
/// as sent, a read-position bar, share / save, and "อ่านจบ: ถัดไป".
///
/// A document counts as read once the reader reaches its end, or the
/// driver taps "ไปท้ายเอกสาร". [onOpened] fires the first time each
/// document is shown, [onRead] once it is read.
class LoanDocumentReader extends StatefulWidget {
  const LoanDocumentReader({
    super.key,
    required this.documents,
    required this.initialIndex,
    this.version,
    this.read = const {},
    this.onOpened,
    this.onRead,
    this.forAcceptance = true,
  });

  final List<LoanDocument> documents;

  /// Reading before ticking (screen 5). False: a plain viewer of documents
  /// already accepted (screens 7, 18).
  final bool forAcceptance;
  final int initialIndex;
  final String? version;

  /// Kinds already read (kept across openings).
  final Set<String> read;
  final ValueChanged<String>? onOpened;
  final ValueChanged<String>? onRead;

  static Future<void> open(
    BuildContext context, {
    required List<LoanDocument> documents,
    required int index,
    String? version,
    Set<String> read = const {},
    ValueChanged<String>? onOpened,
    ValueChanged<String>? onRead,
    bool forAcceptance = true,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => LoanDocumentReader(
        documents: documents,
        initialIndex: index,
        version: version,
        read: read,
        onOpened: onOpened,
        onRead: onRead,
        forAcceptance: forAcceptance,
      ),
    ),
  );

  @override
  State<LoanDocumentReader> createState() => _LoanDocumentReaderState();
}

class _LoanDocumentReaderState extends State<LoanDocumentReader> {
  late int _index = widget.initialIndex;
  late final Set<String> _read = {...widget.read};
  final _scroll = ScrollController();
  double _progress = 0;

  LoanDocument get _doc => widget.documents[_index];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _shown();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _shown() {
    widget.onOpened?.call(_doc.kind);
    // A short document fits on screen: reaching its end is immediate.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!mounted || !_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final p = max <= 0 ? 1.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    setState(() => _progress = p);
    if (p >= 0.98) _markRead();
  }

  void _markRead() {
    if (_read.add(_doc.kind)) {
      widget.onRead?.call(_doc.kind);
      setState(() {});
    }
  }

  void _toEnd() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    _markRead();
  }

  int? get _nextUnread {
    if (!widget.forAcceptance) {
      final n = _index + 1;
      return n < widget.documents.length ? n : null;
    }
    for (var i = 0; i < widget.documents.length; i++) {
      final j = (_index + 1 + i) % widget.documents.length;
      if (!_read.contains(widget.documents[j].kind)) return j;
    }
    return null;
  }

  void _next() {
    final n = _nextUnread;
    if (n == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index = n;
      _progress = 0;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _shown();
  }

  Future<void> _share() async {
    final box = context.findRenderObject() as RenderBox?;
    final v = widget.version;
    await SharePlus.instance.share(
      ShareParams(
        subject: _doc.title,
        text: '${_doc.title}\n${v == null ? '' : 'ฉบับ $v\n'}\n${_doc.body}',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final read = _read.contains(_doc.kind);
    final last = _nextUnread == null;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'ปิด',
          icon: Icon(Icons.close, color: p.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _doc.title,
          maxLines: 2,
          style: AppTypography.caption2.copyWith(
            color: p.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_index + 1} / ${widget.documents.length}',
                style: AppTypography.caption4.copyWith(color: p.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: _scroll,
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  child: LoanMarkdown(_doc.body, color: p.textPrimary),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        read
                            ? '✓ อ่านแล้ว'
                            : 'อ่านแล้ว ${(_progress * 100).round()}%',
                        style: AppTypography.caption5.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: read ? 1 : _progress,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                          color: loanGreen,
                          backgroundColor: p.border,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: LoanSecondaryButton(
                          'แชร์/บันทึก',
                          onPressed: _share,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: widget.forAcceptance
                            ? LoanPrimaryButton(
                                !read
                                    ? 'ไปท้ายเอกสาร'
                                    : (last
                                          ? 'กลับไปยอมรับ'
                                          : 'อ่านจบ: ถัดไป ›'),
                                onPressed: !read ? _toEnd : _next,
                              )
                            : LoanPrimaryButton(
                                last ? 'ปิด' : 'ถัดไป ›',
                                onPressed: _next,
                              ),
                      ),
                    ],
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
