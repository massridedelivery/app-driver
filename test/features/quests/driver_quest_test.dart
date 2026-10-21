import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/quests/domain/entities/driver_quest.dart';
import 'package:massdrive/features/quests/presentation/screens/quest_detail_screen.dart';
import 'package:massdrive/features/quests/presentation/screens/quests_screen.dart';

/// GET /api/driver/quests item as the backend sends it (incentive models).
Map<String, dynamic> _item({
  int current = 14,
  Map<String, dynamic>? timeWindow,
  int endsInDays = 4,
  bool detail = false,
  String? terms = 'ต้องรับงานในพื้นที่\nไม่นับงานที่ยกเลิก',
}) => {
  'quest': {
    'id': 'q1',
    'name': 'Weekly ladder',
    'description': 'ทำรอบขับให้ครบตามขั้น รับโบนัสเพิ่มทุกขั้น',
    'valid_from': '2026-10-18T17:00:00Z', // 19 Oct 00:00 Bangkok
    'valid_until': '2026-10-25T16:59:59Z', // 25 Oct 23:59 Bangkok
    'terms': ?terms,
  },
  'title': 'ขับครบรับโบนัสรายสัปดาห์',
  'area_name': 'ทุกพื้นที่ให้บริการ',
  'time_window': timeWindow,
  'ends_in_days': endsInDays,
  'current_count': current,
  'target_count': 40,
  'status': 'IN_PROGRESS',
  'milestones': [
    {
      'trips': 10,
      'bonus': 100,
      'cumulative': 100,
      'reached': true,
      'trips_to_go': 0,
      if (detail) 'payout_status': 'PENDING',
    },
    {
      'trips': 25,
      'bonus': 150,
      'cumulative': 250,
      'reached': false,
      'trips_to_go': 11,
    },
    {
      'trips': 40,
      'bonus': 250,
      'cumulative': 500,
      'reached': false,
      'trips_to_go': 26,
    },
  ],
  'next_milestone': {
    'trips': 25,
    'bonus': 150,
    'cumulative': 250,
    'reached': false,
    'trips_to_go': 11,
  },
  'earned_amount': 100,
  'max_reward': 500,
  'claimable': false,
};

void main() {
  group('DriverQuest from the backend', () {
    final q = DriverQuest.fromJson(_item());

    test('fields the screens print', () {
      expect(q.id, 'q1');
      expect(q.title, 'ขับครบรับโบนัสรายสัปดาห์');
      expect(q.description, startsWith('ทำรอบขับ'));
      expect(q.areaName, 'ทุกพื้นที่ให้บริการ');
      expect(q.currentCount, 14);
      expect(q.targetCount, 40);
      expect(q.milestones.map((m) => m.cumulative), [100, 250, 500]);
      expect(q.earnedAmount, 100);
      expect(q.maxReward, 500);
      expect(q.terms, contains('ไม่นับงานที่ยกเลิก'));
    });

    test('dates in Bangkok time, whatever the phone zone', () {
      expect(q.dateRange, '19 ต.ค. - 25 ต.ค.');
      final oneDay = DriverQuest.fromJson({
        ..._item(),
        'quest': {
          'id': 'q2',
          'valid_from': '2026-10-20T17:00:00Z',
          'valid_until': '2026-10-21T16:00:00Z',
        },
      });
      expect(oneDay.dateRange, '21 ต.ค.');
    });

    test('time window, ends badge, next step', () {
      expect(q.timeLabel, 'ทั้งวัน');
      expect(
        DriverQuest.fromJson(
          _item(timeWindow: {'start': '06:00', 'end': '10:00'}),
        ).timeLabel,
        '06:00-10:00',
      );
      expect(q.endsLabel, 'สิ้นสุดใน 4 วัน');
      expect(
        DriverQuest.fromJson(_item(endsInDays: 0)).endsLabel,
        'สิ้นสุดวันนี้',
      );
      expect(q.nextLabel, 'อีก 11 รอบ รับ ฿150');
      final done = DriverQuest.fromJson({..._item(), 'next_milestone': null});
      expect(done.nextLabel, isNull);
    });

    test('bar positions: fill = 14/40, marks at trips/target', () {
      expect(q.progress, closeTo(0.35, 1e-9));
      expect(q.milestones.map(q.stepAt), [0.25, 0.625, 1.0]);
      expect(DriverQuest.fromJson(_item(current: 60)).progress, 1.0);
    });

    test('payout status on reached steps (detail)', () {
      final d = DriverQuest.fromJson(_item(detail: true));
      expect(d.reachedSteps.single.payoutStatus, QuestPayoutStatus.pending);
      expect(QuestPayoutStatus.fromApi('PAID')!.label, 'จ่ายแล้ว');
      expect(QuestPayoutStatus.fromApi('REJECTED')!.label, 'ไม่อนุมัติ');
      expect(QuestPayoutStatus.fromApi(null), isNull);
    });

    test('count wording follows quest_type', () {
      DriverQuest typed(String t) => DriverQuest.fromJson({
        ..._item(),
        'quest': {..._item()['quest'] as Map, 'quest_type': t},
      });
      final ride = typed('COMPLETE_N_RIDES');
      expect(ride.countPrefix, 'ทำรอบขับสำเร็จ');
      expect(ride.stepLabel(ride.milestones.first), 'รอบขับ 10 รอบ');
      final food = typed('COMPLETE_N_FOOD');
      expect(food.countPrefix, 'ทำรอบส่งอาหารสำเร็จ');
      expect(food.stepLabel(food.milestones.first), 'รอบส่งอาหาร 10 รอบ');
      final jobs = typed('COMPLETE_N_JOBS');
      expect(jobs.countPrefix, 'ทำงานสำเร็จ');
      expect(jobs.countSuffix, 'งาน');
      expect(jobs.stepLabel(jobs.milestones.first), '10 งาน');
      expect(jobs.nextLabel, 'อีก 11 งาน รับ ฿150');
    });

    test('weekly round vs whole quest end (BE #245)', () {
      // Week ends in 4 days, quest runs to 30 Nov.
      final mid = DriverQuest.fromJson({
        ..._item(),
        'quest_ends_in_days': 40,
        'quest_ends_at': '2026-11-30T16:59:59Z',
      });
      expect(mid.endsLabel, 'รอบนี้สิ้นสุดใน 4 วัน');
      expect(mid.questEndsLabel, 'ภารกิจถึง 30 พ.ย.');
      final midToday = DriverQuest.fromJson({
        ..._item(endsInDays: 0),
        'quest_ends_in_days': 9,
        'quest_ends_at': '2026-10-30T16:59:59Z',
      });
      expect(midToday.endsLabel, 'รอบนี้สิ้นสุดวันนี้');
      // Last round: the round and the quest end together.
      final last = DriverQuest.fromJson({
        ..._item(),
        'quest_ends_in_days': 4,
        'quest_ends_at': '2026-10-25T16:59:59Z',
      });
      expect(last.endsLabel, 'สิ้นสุดใน 4 วัน');
      expect(last.questEndsLabel, isNull);
      // Backend without the new fields: unchanged.
      expect(q.endsLabel, 'สิ้นสุดใน 4 วัน');
      expect(q.questEndsLabel, isNull);
    });

    test('detail lines: next step and earned this period', () {
      expect(q.nextExtraLabel, 'อีก 11 รอบ รับเพิ่ม ฿150');
      expect(q.earnedLabel, 'ได้รับแล้วในรอบนี้ ฿100 จากสูงสุด ฿500');
    });

    test('tabs map to the API values', () {
      expect(QuestTab.values.map((t) => t.api), ['today', 'upcoming', 'past']);
      expect(QuestTab.values.map((t) => t.label), [
        'วันนี้',
        'กำลังจะมาถึง',
        'ที่ผ่านมา',
      ]);
    });
  });

  testWidgets('list card: dates · ทั้งวัน, badge, count, steps, next', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuestCard(quest: DriverQuest.fromJson(_item()))),
      ),
    );
    expect(find.text('19 ต.ค. - 25 ต.ค. · ทั้งวัน'), findsOneWidget);
    expect(find.text('สิ้นสุดใน 4 วัน'), findsOneWidget);
    expect(find.text('ขับครบรับโบนัสรายสัปดาห์'), findsOneWidget);
    expect(
      find.text('ทำรอบขับให้ครบตามขั้น รับโบนัสเพิ่มทุกขั้น'),
      findsOneWidget,
    );
    expect(
      find.textContaining('ทำรอบขับสำเร็จ', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('10'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('อีก 11 รอบ รับ ฿150'), findsOneWidget);
  });

  testWidgets('detail: cumulative ladder, payout chip, terms toggle', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestDetailBody(
            quest: DriverQuest.fromJson(_item(detail: true)),
          ),
        ),
      ),
    );
    expect(find.text('รอบขับ 25 รอบ'), findsOneWidget);
    expect(find.text('฿250'), findsOneWidget);
    expect(find.text('ขั้น 10 รอบ · ฿100'), findsOneWidget);
    expect(find.text('รอตรวจสอบ'), findsOneWidget);
    expect(find.text('14 รอบ'), findsOneWidget);
    expect(find.text('อีก 11 รอบ รับเพิ่ม ฿150'), findsOneWidget);
    expect(find.text('ได้รับแล้วในรอบนี้ ฿100 จากสูงสุด ฿500'), findsOneWidget);
    // The payout breakdown folds away.
    await t.tap(find.text('แจกแจงรายละเอียดการชำระเงิน'));
    await t.pump();
    expect(find.text('รอตรวจสอบ'), findsNothing);
    expect(find.textContaining('ไม่นับงานที่ยกเลิก'), findsNothing);
    await t.tap(find.text('ข้อกำหนดและเงื่อนไข'));
    await t.pump();
    expect(find.textContaining('ไม่นับงานที่ยกเลิก'), findsOneWidget);
    expect(find.text('รับรางวัล'), findsNothing);
  });

  testWidgets('detail: nothing reached, no terms', (t) async {
    final json = _item(current: 3, terms: null);
    (json['milestones'] as List).first['reached'] = false;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestDetailBody(quest: DriverQuest.fromJson(json)),
        ),
      ),
    );
    expect(find.text('ยังไม่มีรายการ'), findsOneWidget);
    expect(find.text('ข้อกำหนดและเงื่อนไข'), findsNothing);
  });
}
