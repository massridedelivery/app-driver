import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/review/data/customer_review_api.dart';

/// Driver → customer review, shown after a completed job's payment step.
/// UI + flow mirror the customer app's "rate the driver" screen: 1–5 stars,
/// quick-tag chips, an optional comment, submit / skip → home.
class ReviewCustomerScreen extends ConsumerStatefulWidget {
  final String jobId;
  final ReviewService service;
  final String customerName;
  final String? avatarUrl;

  /// Secondary line under the name (e.g. phone or a vertical label).
  final String? subtitle;

  /// UI-preview bypass (dev entry): skip the API call — which 404s until the
  /// backend ships (SCRUM-70) — and just confirm the flow. Lets the screen be
  /// checked on-device without a real completed job.
  final bool previewMode;

  const ReviewCustomerScreen({
    super.key,
    required this.jobId,
    required this.service,
    this.customerName = 'ลูกค้า',
    this.avatarUrl,
    this.subtitle,
    this.previewMode = false,
  });

  @override
  ConsumerState<ReviewCustomerScreen> createState() =>
      _ReviewCustomerScreenState();
}

class _ReviewCustomerScreenState extends ConsumerState<ReviewCustomerScreen> {
  // Customer-appropriate quick tags (driver's view of the customer).
  static const _tags = <String>[
    'สุภาพ',
    'ตรงเวลา',
    'รอไม่นาน',
    'จุดนัดหมายหาง่าย',
    'สื่อสารดี',
  ];

  final _api = CustomerReviewApi();
  final TextEditingController _comment = TextEditingController();
  final Set<String> _selectedTags = {};
  int _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _goHome() {
    if (mounted) context.go(AppRoutes.homeNamedPage);
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: context.palette.textPrimary,
            content: Text(
              'กรุณาให้คะแนนลูกค้าก่อนนะครับ',
              style: AppTypography.caption4.copyWith(color: context.palette.bg),
            ),
          ),
        );
      return;
    }

    // UI-preview bypass: skip the (not-yet-built) API and just go home.
    if (widget.previewMode) {
      _goHome();
      return;
    }

    setState(() => _submitting = true);
    try {
      await _api.submit(
        service: widget.service,
        jobId: widget.jobId,
        rating: _rating,
        tags: _selectedTags.toList(),
        comment: _comment.text,
      );
    } catch (e) {
      // Best-effort while the backend (SCRUM-70) is pending: never trap the
      // driver on this screen if the submit fails.
      if (kDebugMode) debugPrint('ReviewCustomerScreen: submit failed → $e');
    }
    _goHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: AppBar(
        backgroundColor: context.palette.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.palette.textPrimary),
          onPressed: _goHome,
        ),
        centerTitle: true,
        title: Text(
          'ให้คะแนนลูกค้า',
          style: AppTypography.heading4.copyWith(color: context.palette.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _goHome,
            child: Text(
              'ข้าม',
              style: AppTypography.label2.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _section(child: _customerAndStars()),
                  const SizedBox(height: 12),
                  _section(child: _commentField()),
                ],
              ),
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _customerAndStars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _avatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customerName.isEmpty ? 'ลูกค้า' : widget.customerName,
                    style: AppTypography.label2.copyWith(
                      color: context.palette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle?.isNotEmpty == true
                        ? widget.subtitle!
                        : 'ลูกค้าของคุณ',
                    style: AppTypography.caption5.copyWith(
                      color: context.palette.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'ให้คะแนนลูกค้า',
          style: AppTypography.label2.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _starRow(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map(_chip).toList(),
        ),
      ],
    );
  }

  Widget _avatar() {
    final url = widget.avatarUrl;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.foundationRed100,
        image: (url != null && url.isNotEmpty)
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: (url == null || url.isEmpty)
          ? const Icon(Icons.person, size: 30, color: AppColors.foundationRed700)
          : null,
    );
  }

  Widget _starRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < _rating;
        return GestureDetector(
          onTap: () => setState(() => _rating = i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              filled ? Icons.star_rate_sharp : Icons.star_outline,
              size: 42,
              color: filled ? Colors.amber : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }

  Widget _chip(String label) {
    final selected = _selectedTags.contains(label);
    return GestureDetector(
      onTap: () => setState(() {
        selected ? _selectedTags.remove(label) : _selectedTags.add(label);
      }),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.foundationRed100 : context.palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.foundationRed700
                : context.palette.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.label2.copyWith(
            color: selected
                ? AppColors.foundationRed700
                : context.palette.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _commentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ความคิดเห็นเพิ่มเติม',
          style: AppTypography.label2.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.palette.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _comment,
            maxLines: 4,
            style: AppTypography.caption4.copyWith(
              color: context.palette.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
              hintText: 'บอกเราว่าลูกค้าเป็นอย่างไรบ้าง...',
              hintStyle: AppTypography.caption4.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.foundationGreen500,
                  disabledBackgroundColor: AppColors.foundationGreen500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'ส่งรีวิว',
                        style: AppTypography.label1.copyWith(color: Colors.white),
                      ),
              ),
            ),
            TextButton(
              onPressed: _submitting ? null : _goHome,
              child: Text(
                'ข้ามไปก่อน',
                style: AppTypography.label2.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: child,
      );
}
