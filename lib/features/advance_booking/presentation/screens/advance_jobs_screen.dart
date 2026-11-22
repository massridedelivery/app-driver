import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/advance_booking/domain/advance_eligibility.dart';
import 'package:massdrive/features/advance_booking/domain/advance_errors.dart';
import 'package:massdrive/features/advance_booking/domain/advance_pushes.dart';
import 'package:massdrive/features/advance_booking/domain/advance_ride.dart';
import 'package:massdrive/features/advance_booking/domain/advance_time.dart';
import 'package:massdrive/features/advance_booking/presentation/advance_booking_providers.dart';
import 'package:massdrive/features/advance_booking/presentation/advance_start.dart';
import 'package:massdrive/features/advance_booking/presentation/widgets/advance_ride_card.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';

enum AdvanceJobsTab { board, mine }

/// "งานจองล่วงหน้า": the board of rides booked ahead nobody has claimed
/// (งานว่าง) and the ones this driver holds (งานของฉัน). Pushes about the
/// driver's rides open the second tab (`/advance-jobs`).
class AdvanceJobsScreen extends ConsumerStatefulWidget {
  const AdvanceJobsScreen({
    super.key,
    this.initialTab = AdvanceJobsTab.mine,
    this.highlightJobId,
  });

  final AdvanceJobsTab initialTab;

  /// The ride a tapped push is about (`?job=`): "งานของฉัน" scrolls to it
  /// and marks it — when it is still in the list.
  final String? highlightJobId;

  @override
  ConsumerState<AdvanceJobsScreen> createState() => _AdvanceJobsScreenState();
}

class _AdvanceJobsScreenState extends ConsumerState<AdvanceJobsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.highlightJobId != null
        ? AdvanceJobsTab.mine.index
        : widget.initialTab.index,
  );

  late String? _highlight = widget.highlightJobId;

  /// Rules times compare against this; ticks so "กำลังไป" opens on time.
  DateTime _now = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    AdvanceBookingUpdates.instance.addListener(_onPush);
  }

  @override
  void dispose() {
    AdvanceBookingUpdates.instance.removeListener(_onPush);
    _ticker?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  /// A push tapped while this is open (the providers re-read by
  /// themselves): show "งานของฉัน" with its ride marked.
  void _onPush() {
    final id = AdvanceBookingUpdates.instance.highlightJobId;
    if (!mounted || id == null) return;
    setState(() => _highlight = id);
    _tabs.animateTo(AdvanceJobsTab.mine.index);
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// A refusal that means the lists or the eligibility are out of date.
  void _afterError(Object e) {
    if (e is AdvanceBookingException &&
        (e.staleRide || e.boardClosed || e.code == 'SCHEDULE_CONFLICT')) {
      invalidateAdvanceLists(ref);
    }
  }

  Future<void> _claim(AdvanceRide ride) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => _ClaimDialog(ride: ride),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(advanceBookingApiProvider).claim(ride.id);
      invalidateAdvanceLists(ref);
      _toast('รับงานแล้ว · ดูได้ที่ "งานของฉัน"');
      _tabs.animateTo(AdvanceJobsTab.mine.index);
    } catch (e) {
      _toast(advanceErrorMessage(e, ride: ride));
      _afterError(e);
    }
  }

  Future<void> _release(AdvanceRide ride) async {
    final eligibility = ref.read(advanceEligibilityProvider).asData?.value;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.palette.sheet,
      builder: (s) => _ReleaseSheet(
        terms: releaseTermsAt(ride.rules, DateTime.now()),
        eligibility: eligibility,
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final out = await ref.read(advanceBookingApiProvider).release(ride.id);
      invalidateAdvanceLists(ref);
      // The late fee left the wallet at once.
      if (out.penalty > 0) {
        unawaited(
          ref.read(walletControllerProvider.notifier).fetchAll(silent: true),
        );
      }
      _toast(out.message);
    } catch (e) {
      _toast(advanceErrorMessage(e, ride: ride));
      _afterError(e);
    }
  }

  bool _starting = false;

  Future<void> _start(AdvanceRide ride) async {
    if (_starting) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('เริ่มเดินทางไปรับลูกค้า?'),
        content: Text(
          'รับ ${formatBangkokDayTime(ride.scheduledAt, DateTime.now())}\n'
          '${ride.pickupAddress}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('ยังก่อน'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('กำลังไป'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _starting = true);
    try {
      await ref.read(advanceBookingApiProvider).start(ride.id);
      // The ride is live now and has left "งานของฉัน".
      invalidateAdvanceLists(ref);
      final opened = await openStartedAdvanceRide(ref, ride.id);
      if (!opened) _toast('เริ่มงานแล้ว ดูงานได้ที่หน้าหลัก');
    } catch (e) {
      _toast(advanceErrorMessage(e, ride: ride));
      _afterError(e);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      // CommonAppBar's height leaves no room for a bottom: the tabs sit in
      // the body.
      appBar: CommonAppBar(titleText: 'งานจองล่วงหน้า', showLeftIcon: true),
      body: Stack(
        children: [
          Column(
            children: [
              TabBar(
                controller: _tabs,
                labelColor: AppColors.foundationOrange700,
                indicatorColor: AppColors.foundationOrange700,
                unselectedLabelColor: p.textSecondary,
                tabs: const [
                  Tab(text: 'งานว่าง'),
                  Tab(text: 'งานของฉัน'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _BoardTab(now: _now, onClaim: _claim),
                    _MineTab(
                      now: _now,
                      highlightJobId: _highlight,
                      onRelease: _release,
                      onStart: _start,
                      onBrowse: () =>
                          _tabs.animateTo(AdvanceJobsTab.board.index),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_starting)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: MassLoadingM(size: 72)),
            ),
        ],
      ),
    );
  }
}

// ── งานว่าง ──────────────────────────────────────────────────────────────

class _BoardTab extends ConsumerStatefulWidget {
  const _BoardTab({required this.now, required this.onClaim});

  final DateTime now;
  final Future<void> Function(AdvanceRide ride) onClaim;

  @override
  ConsumerState<_BoardTab> createState() => _BoardTabState();
}

class _BoardTabState extends ConsumerState<_BoardTab>
    with AutomaticKeepAliveClientMixin {
  /// A Bangkok day, or null for everything ahead.
  DateTime? _day;

  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh() async {
    ref.invalidate(advanceEligibilityProvider);
    ref.invalidate(advanceBoardProvider(_day));
    try {
      await ref.read(advanceBoardProvider(_day).future);
    } catch (_) {
      // Shown by the list itself.
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final eligibility = ref.watch(advanceEligibilityProvider);
    return eligibility.when(
      loading: () => const Center(child: MassLoadingM(size: 64)),
      error: (e, _) => _Message(
        icon: Icons.wifi_off_rounded,
        title: 'โหลดข้อมูลไม่สำเร็จ',
        body: advanceErrorMessage(e),
        onRetry: () => ref.invalidate(advanceEligibilityProvider),
      ),
      data: (e) => e.eligible ? _board(e) : _NotEligible(eligibility: e),
    );
  }

  Widget _board(AdvanceEligibility e) {
    final board = ref.watch(advanceBoardProvider(_day));
    final warning = e.lateReleaseLine;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _DayFilter(
              now: widget.now,
              selected: _day,
              onSelect: (d) => setState(() => _day = d),
            ),
          ),
          if (warning != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _Notice(text: warning),
              ),
            ),
          ...board.when(
            loading: () => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: MassLoadingM(size: 64)),
              ),
            ],
            error: (err, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Message(
                  icon: Icons.wifi_off_rounded,
                  title: 'โหลดงานไม่สำเร็จ',
                  body: advanceErrorMessage(err),
                  onRetry: _refresh,
                ),
              ),
            ],
            data: (rides) => rides.isEmpty
                ? [
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _Message(
                        icon: Icons.event_note_outlined,
                        title: 'ยังไม่มีงานจองในช่วงนี้',
                        body: 'ดึงหน้าจอลงเพื่อดูงานใหม่',
                      ),
                    ),
                  ]
                : [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        24 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      sliver: SliverList.separated(
                        itemCount: rides.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _boardCard(rides[i]),
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _boardCard(AdvanceRide ride) {
    final rules = ride.rules;
    return AdvanceRideCard(
      ride: ride,
      now: widget.now,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rules != null) _RulesLines(rules: rules, now: widget.now),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: ride.conflict ? null : () => widget.onClaim(ride),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.foundationOrange700,
            ),
            child: Text(ride.conflict ? 'เวลาชนกับงานที่รับไว้' : 'รับงานนี้'),
          ),
        ],
      ),
    );
  }
}

class _DayFilter extends StatelessWidget {
  const _DayFilter({
    required this.now,
    required this.selected,
    required this.onSelect,
  });

  final DateTime now;
  final DateTime? selected;
  final ValueChanged<DateTime?> onSelect;

  @override
  Widget build(BuildContext context) {
    final today = bangkokDay(now);
    final days = [for (var i = 0; i < 7; i++) today.add(Duration(days: i))];
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _chip(context, 'ทั้งหมด', selected == null, () => onSelect(null)),
          for (final d in days)
            _chip(
              context,
              // A Bangkok day at 00:00 UTC+7 is 17:00 UTC the day before.
              formatBangkokDayLabel(d.subtract(const Duration(hours: 7)), now),
              selected == d,
              () => onSelect(d),
            ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    bool on,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.foundationOrange700.withValues(alpha: 0.15),
      labelStyle: AppTypography.caption4.copyWith(
        color: on ? AppColors.foundationOrange700 : context.palette.textPrimary,
        fontWeight: on ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
  );
}

class _NotEligible extends ConsumerWidget {
  const _NotEligible({required this.eligibility});

  final AdvanceEligibility eligibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final warning = eligibility.lateReleaseLine;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(advanceEligibilityProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          Icon(Icons.event_busy_outlined, size: 56, color: p.textSecondary),
          const SizedBox(height: 12),
          Text(
            'ยังรับงานจองล่วงหน้าไม่ได้',
            textAlign: TextAlign.center,
            style: AppTypography.heading6.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: 16),
          for (final line in eligibility.reasonLines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.foundationOrange700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: AppTypography.caption3.copyWith(
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (warning != null) ...[
            const SizedBox(height: 4),
            _Notice(text: warning),
          ],
          if (eligibility.needsVehicleType) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.serviceTypeNamedPage),
              child: const Text('เลือกประเภทบริการ'),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'งานที่คุณรับไว้แล้วยังอยู่ในแท็บ "งานของฉัน"',
            textAlign: TextAlign.center,
            style: AppTypography.caption5.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── งานของฉัน ───────────────────────────────────────────────────────────

class _MineTab extends ConsumerStatefulWidget {
  const _MineTab({
    required this.now,
    required this.onRelease,
    required this.onStart,
    required this.onBrowse,
    this.highlightJobId,
  });

  final DateTime now;
  final Future<void> Function(AdvanceRide ride) onRelease;
  final Future<void> Function(AdvanceRide ride) onStart;
  final VoidCallback onBrowse;
  final String? highlightJobId;

  @override
  ConsumerState<_MineTab> createState() => _MineTabState();
}

class _MineTabState extends ConsumerState<_MineTab> {
  final _highlightKey = GlobalKey();

  /// The highlight already scrolled to, so a refresh doesn't jump again.
  String? _scrolledTo;

  DateTime get now => widget.now;

  /// Bring the marked ride into view once it is laid out. A ride no longer
  /// in the list (released, cancelled, unassigned) is simply not there.
  void _scrollToHighlight(List<AdvanceRide> rides) {
    final id = widget.highlightJobId;
    if (id == null || id == _scrolledTo || !rides.any((r) => r.id == id)) {
      return;
    }
    _scrolledTo = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _highlightKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.1,
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final onBrowse = widget.onBrowse;
    final mine = ref.watch(advanceMineProvider);
    Future<void> refresh() async {
      ref.invalidate(advanceMineProvider);
      try {
        await ref.read(advanceMineProvider.future);
      } catch (_) {
        // Shown below.
      }
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: mine.when(
        loading: () => const Center(child: MassLoadingM(size: 64)),
        error: (e, _) => _Message(
          icon: Icons.wifi_off_rounded,
          title: 'โหลดงานไม่สำเร็จ',
          body: advanceErrorMessage(e),
          onRetry: refresh,
          scrollable: true,
        ),
        data: (rides) => rides.isEmpty
            ? _Message(
                icon: Icons.event_available_outlined,
                title: 'ยังไม่มีงานที่รับไว้',
                body: 'รับงานจองล่วงหน้าได้จากแท็บ "งานว่าง"',
                actionLabel: 'ดูงานว่าง',
                onRetry: onBrowse,
                scrollable: true,
              )
            : _mineList(context, rides),
      ),
    );
  }

  /// Every card built at once (a driver holds a few rides at most), so the
  /// marked one can be scrolled to.
  Widget _mineList(BuildContext context, List<AdvanceRide> rides) {
    _scrollToHighlight(rides);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rides.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _mineCard(context, rides[i]),
          ],
        ],
      ),
    );
  }

  Widget _mineCard(BuildContext context, AdvanceRide ride) {
    final rules = ride.rules;
    final window = startWindowAt(rules, now);
    final p = context.palette;
    final marked = ride.id == widget.highlightJobId;
    return AdvanceRideCard(
      key: marked ? _highlightKey : null,
      ride: ride,
      now: now,
      highlighted: marked,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rules != null) _RulesLines(rules: rules, now: now),
          const SizedBox(height: 4),
          Text(
            startHint(rules, now),
            style: AppTypography.caption5.copyWith(
              color: window == StartWindow.late
                  ? AppColors.foundationRed700
                  : p.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onRelease(ride),
                  child: const Text('คืนงาน'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: window == StartWindow.notYet
                      ? null
                      : () => widget.onStart(ride),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.foundationMint600,
                  ),
                  child: const Text('กำลังไป'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared pieces ───────────────────────────────────────────────────────

/// "คืนฟรีถึง 23 พ.ย. 01:30 น." or the late fee, and the wait at pickup.
class _RulesLines extends StatelessWidget {
  const _RulesLines({required this.rules, required this.now});

  final AdvanceRules rules;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final terms = releaseTermsAt(rules, now);
    final release = terms.free
        ? (terms.freeUntil == null
              ? 'คืนงานได้ฟรี'
              : 'คืนฟรีถึง ${formatBangkokDateTime(terms.freeUntil!)}'
                    '${terms.fee > 0 ? ' · หลังจากนั้นค่าปรับ ${formatBaht(terms.fee)}' : ''}')
        : (terms.fee > 0
              ? 'เลยเวลาคืนฟรีแล้ว · คืนตอนนี้ค่าปรับ ${formatBaht(terms.fee)}'
              : 'เลยเวลาคืนฟรีแล้ว · ไม่มีค่าปรับ');
    final style = AppTypography.caption5.copyWith(color: p.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(release, style: style),
        if (rules.waitMinutes > 0)
          Text('รอผู้โดยสารที่จุดรับ ${rules.waitMinutes} นาที', style: style),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.foundationOrange700.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 18,
          color: AppColors.foundationOrange700,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption5.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
    this.actionLabel = 'ลองใหม่',
    this.scrollable = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;
  final String actionLabel;

  /// Inside a RefreshIndicator with nothing else to scroll.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: p.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.heading6.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTypography.caption4.copyWith(color: p.textSecondary),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(actionLabel)),
          ],
        ],
      ),
    );
    if (!scrollable) return Center(child: content);
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Center(child: content),
        ),
      ),
    );
  }
}

class _ClaimDialog extends StatelessWidget {
  const _ClaimDialog({required this.ride});

  final AdvanceRide ride;

  @override
  Widget build(BuildContext context) {
    final rules = ride.rules;
    final now = DateTime.now();
    final lines = [
      'รับ ${formatBangkokDayTime(ride.scheduledAt, now)}',
      if (ride.earnings != null)
        'รายได้สุทธิโดยประมาณ ${formatBaht(ride.earnings!.net)}',
      if (rules?.freeReleaseUntil != null)
        'คืนฟรีได้ถึง ${formatBangkokDateTime(rules!.freeReleaseUntil!)}'
            '${rules.lateReleaseFee > 0 ? ' หลังจากนั้นค่าปรับ ${formatBaht(rules.lateReleaseFee)}' : ''}',
      if (rules?.setOffFrom != null && rules?.setOffBy != null)
        'ต้องกด "กำลังไป" ระหว่าง ${formatBangkokTime(rules!.setOffFrom!)}'
            '–${formatBangkokTime(rules.setOffBy!)} ไม่อย่างนั้นงานจะถูกส่งต่อและมีค่าปรับ',
    ];
    return AlertDialog(
      title: const Text('รับงานจองนี้?'),
      content: Text(lines.join('\n\n')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('รับงาน'),
        ),
      ],
    );
  }
}

class _ReleaseSheet extends StatelessWidget {
  const _ReleaseSheet({required this.terms, this.eligibility});

  final ReleaseTerms terms;
  final AdvanceEligibility? eligibility;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final count = eligibility;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'คืนงานนี้?',
              style: AppTypography.heading5.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              terms.headline,
              style: AppTypography.caption2.copyWith(
                color: terms.chargesFee
                    ? AppColors.foundationRed700
                    : AppColors.foundationMint600,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              terms.detail,
              style: AppTypography.caption4.copyWith(color: p.textSecondary),
            ),
            if (!terms.free && count != null && count.maxLateReleases > 0) ...[
              const SizedBox(height: 4),
              Text(
                'คืนงานหลังเวลาฟรีแล้ว ${count.lateReleases30d}/'
                '${count.maxLateReleases} ครั้งใน 30 วัน',
                style: AppTypography.caption4.copyWith(color: p.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: terms.chargesFee
                    ? AppColors.foundationRed700
                    : AppColors.foundationOrange700,
              ),
              child: Text(terms.confirmLabel),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('เก็บงานไว้'),
            ),
          ],
        ),
      ),
    );
  }
}
