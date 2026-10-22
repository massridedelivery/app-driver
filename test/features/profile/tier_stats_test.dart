import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';
import 'package:massdrive/features/profile/presentation/controllers/profile_controller.dart';

void main() {
  const profile = DriverProfileEntity(userId: 'u', fullName: 'สมชาย ใจดี');

  test('งานสำเร็จ comes from tier weekly_jobs (BE dev132)', () {
    final p = mergeTierStats(profile, {
      'weekly_jobs': 1,
      'acceptance_rate': 100,
      'cancellation_rate': 0,
    });
    expect(p.weeklyCompletedJobs, 1);
    expect(p.acceptanceRate, 100);
    expect(p.cancellationRate, 0);
  });

  test('fractions read as percentages; missing fields keep the profile', () {
    final p = mergeTierStats(profile.copyWith(weeklyCompletedJobs: 3), {
      'acceptance_rate': 0.95,
      'cancellation_rate': 0.02,
    });
    expect(p.acceptanceRate, closeTo(95, 1e-9));
    expect(p.cancellationRate, closeTo(2, 1e-9));
    expect(p.weeklyCompletedJobs, 3);
  });
}
