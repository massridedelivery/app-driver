import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/referral/domain/driver_referral.dart';
import 'package:massdrive/features/referral/presentation/referral_providers.dart';

/// "กรอกโค้ดผู้แนะนำ": shown while the backend offers it (`can_apply_code`,
/// before `apply_before`) — in registration and on the invite screen. Once
/// a code is applied it reads "สมัครด้วยโค้ด …" instead. Hidden otherwise.
class ReferralCodeCard extends ConsumerWidget {
  const ReferralCodeCard({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(driverReferralProvider).asData?.value;
    if (info == null) return const SizedBox.shrink();
    final by = info.referredBy;
    if (by != null) {
      return Padding(
        padding: padding,
        child: _AppliedNote(referral: by),
      );
    }
    if (!info.enabled || !info.canApplyAt(DateTime.now())) {
      return const SizedBox.shrink();
    }
    return Padding(padding: padding, child: const _CodeForm());
  }
}

class _AppliedNote extends StatelessWidget {
  const _AppliedNote({required this.referral});

  final ReferralProgress referral;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final code = referral.code;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.semanticSupportMintBgHigh,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              code == null
                  ? 'คุณสมัครด้วยโค้ดผู้แนะนำแล้ว'
                  : 'คุณสมัครด้วยโค้ดผู้แนะนำ $code แล้ว',
              style: AppTypography.caption4.copyWith(color: p.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeForm extends ConsumerStatefulWidget {
  const _CodeForm();

  @override
  ConsumerState<_CodeForm> createState() => _CodeFormState();
}

class _CodeFormState extends ConsumerState<_CodeForm> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _sending) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(referralApiProvider).apply(code);
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('ใช้โค้ดผู้แนะนำเรียบร้อยแล้ว')),
      );
      ref.invalidate(driverReferralProvider);
    } on ReferralApplyException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      if (e.closesField) ref.invalidate(driverReferralProvider);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'ใส่โค้ดไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่',
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'มีโค้ดผู้แนะนำไหม?',
            style: AppTypography.caption3.copyWith(
              color: p.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'กรอกโค้ดของเพื่อนที่ชวนคุณมาขับ (ไม่บังคับ)',
            style: AppTypography.caption5.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_sending,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [LengthLimitingTextInputFormatter(20)],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _apply(),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'กรอกโค้ดผู้แนะนำ',
                    errorText: _error,
                    errorMaxLines: 3,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.semanticSupportMintBgHigh,
                  ),
                  onPressed: _sending ? null : _apply,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('ใช้โค้ด'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
