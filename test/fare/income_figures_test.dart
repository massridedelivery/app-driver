import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/wallet/data/models/wallet_overview_model.dart';

/// รายได้ screen: the figures are what the driver earned (after commission).
void main() {
  test('today_income (gross − commission) is read next to the gross', () {
    final o = WalletOverviewModel.fromJson({
      'balance': 0,
      'today_gross_earnings': 44,
      'today_income': 37,
      'this_week_income': 37,
      'this_month_income': 120,
      'this_year_income': 900,
      'total_trips': 1,
    }).toEntity();
    expect(o.todayGrossEarnings, 44);
    expect(o.todayIncome, 37);
    expect(o.thisWeekIncome, 37);
    expect(o.thisMonthIncome, 120);
    expect(o.thisYearIncome, 900);
    // What the controller binds: income first, gross only as a fallback.
    expect(o.todayIncome ?? o.todayGrossEarnings, 37);
  });

  test('older BE without *_income → null, so the gross is the fallback', () {
    final o = WalletOverviewModel.fromJson({
      'today_gross_earnings': 44,
    }).toEntity();
    expect(o.todayIncome, isNull);
    expect(o.todayIncome ?? o.todayGrossEarnings, 44);
  });
}
