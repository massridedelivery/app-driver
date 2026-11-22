import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/loans/data/loan_api.dart';
import 'package:massdrive/features/loans/domain/loan_entry.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';

/// Bumped by a lending push (loan_approved / loan_rejected /
/// loan_daily_notice) and after the driver's own actions: every loan
/// provider re-reads. A plain notifier: the push service has no Riverpod.
class LoanUpdates extends ChangeNotifier {
  LoanUpdates._();
  static final LoanUpdates instance = LoanUpdates._();

  void notifyChanged() => notifyListeners();
}

/// Whether this server has lending switched on, as far as the app knows.
/// Null until a loan call answers; false after one 404s.
class LoanAvailability extends ValueNotifier<bool?> {
  LoanAvailability._() : super(null);
  static final LoanAvailability instance = LoanAvailability._();

  void report(Object error) {
    if (error is LoanApiException && error.lendingOff) value = false;
  }

  void reportOn() => value = true;
}

/// No automatic retry: a 404 means "lending off", and a retry storm on it
/// helps nobody. Screens offer "ลองอีกครั้ง".
Duration? _noRetry(int _, Object _) => null;

final loanApiProvider = Provider<LoanApi>(
  (ref) => LoanApi(ref.watch(dioProvider)),
);

/// Re-read on [LoanUpdates], and report availability.
Future<T> _watched<T>(Ref ref, Future<T> Function() load) async {
  void onChange() => ref.invalidateSelf();
  LoanUpdates.instance.addListener(onChange);
  ref.onDispose(() => LoanUpdates.instance.removeListener(onChange));
  try {
    final v = await load();
    LoanAvailability.instance.reportOn();
    return v;
  } catch (e) {
    LoanAvailability.instance.report(e);
    rethrow;
  }
}

final loanOfferProvider = FutureProvider.autoDispose<LoanOffer>(
  (ref) => _watched(ref, () => ref.read(loanApiProvider).offer()),
  retry: _noRetry,
);

final loanEligibilityProvider = FutureProvider.autoDispose<LoanEligibility>(
  (ref) => _watched(ref, () => ref.read(loanApiProvider).eligibility()),
  retry: _noRetry,
);

final loanApplicationsProvider =
    FutureProvider.autoDispose<List<LoanApplication>>(
      (ref) => _watched(ref, () => ref.read(loanApiProvider).applications()),
      retry: _noRetry,
    );

final myLoansProvider = FutureProvider.autoDispose<List<Loan>>(
  (ref) => _watched(ref, () => ref.read(loanApiProvider).loans()),
  retry: _noRetry,
);

final loanDetailProvider = FutureProvider.autoDispose
    .family<LoanDetail, String>(
      (ref, id) => _watched(ref, () => ref.read(loanApiProvider).loan(id)),
      retry: _noRetry,
    );

final applicationDocumentsProvider = FutureProvider.autoDispose
    .family<AcceptedLoanDocuments, String>(
      (ref, id) =>
          _watched(ref, () => ref.read(loanApiProvider).applicationTerms(id)),
      retry: _noRetry,
    );

final loanDocumentsProvider = FutureProvider.autoDispose
    .family<AcceptedLoanDocuments, String>(
      (ref, id) => _watched(ref, () => ref.read(loanApiProvider).loanTerms(id)),
      retry: _noRetry,
    );

/// The profile row's state: null = hidden (lending off on this server).
final loanEntryProvider = FutureProvider.autoDispose<LoanEntry?>((ref) async {
  void onChange() => ref.invalidateSelf();
  LoanUpdates.instance.addListener(onChange);
  ref.onDispose(() => LoanUpdates.instance.removeListener(onChange));
  final api = ref.read(loanApiProvider);
  try {
    final all = await Future.wait<Object>([
      api.offer(),
      api.loans(),
      api.applications(),
    ]);
    final offer = all[0] as LoanOffer;
    final loans = all[1] as List<Loan>;
    final apps = all[2] as List<LoanApplication>;
    LoanAvailability.instance.reportOn();
    LoanRules? rules;
    if (!offer.eligible &&
        (offer.declineReason == 'INACTIVE_MONTHS' ||
            offer.declineReason == 'LOW_RATING')) {
      try {
        rules = (await api.eligibility()).rules;
      } on LoanApiException {
        rules = null;
      }
    }
    return loanEntryFor(
      offer: offer,
      loans: loans,
      applications: apps,
      now: DateTime.now(),
      rules: rules,
    );
  } on LoanApiException catch (e) {
    LoanAvailability.instance.report(e);
    if (e.lendingOff) return null;
    rethrow;
  }
}, retry: _noRetry);
