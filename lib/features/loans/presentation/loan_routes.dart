import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/features/loans/domain/loan_paths.dart';
import 'package:massdrive/features/loans/presentation/screens/loan_applications_screen.dart';
import 'package:massdrive/features/loans/presentation/screens/loan_apply_screen.dart';
import 'package:massdrive/features/loans/presentation/screens/loan_documents_screen.dart';
import 'package:massdrive/features/loans/presentation/screens/loan_history_screen.dart';
import 'package:massdrive/features/loans/presentation/screens/loan_notice_screen.dart';
import 'package:massdrive/features/loans/presentation/screens/loan_offer_screen.dart';
import 'package:massdrive/features/loans/presentation/screens/loan_pay_screen.dart';
import 'package:massdrive/features/loans/presentation/screens/loan_screen.dart';

/// The loan screens (paths in [LoanPaths]). Spread into the app router.
final List<RouteBase> loanRoutes = [
  _route(LoanPaths.offer, (s) => const LoanOfferScreen()),
  _route(LoanPaths.eligibility, (s) => const LoanEligibilityScreen()),
  _route(LoanPaths.apply, (s) => const LoanApplyScreen()),
  _route(LoanPaths.applications, (s) => const LoanApplicationsScreen()),
  _route(
    '/loans/applications/:id',
    (s) => LoanApplicationScreen(id: s.pathParameters['id']!),
  ),
  _route(
    '/loans/applications/:id/documents',
    (s) => LoanDocumentsScreen(applicationId: s.pathParameters['id']!),
  ),
  _route('/loans/loan/:id', (s) => LoanScreen(id: s.pathParameters['id']!)),
  _route(
    '/loans/loan/:id/catch-up',
    (s) => LoanScreen(id: s.pathParameters['id']!, catchUp: true),
  ),
  _route(
    '/loans/loan/:id/history',
    (s) => LoanHistoryScreen(id: s.pathParameters['id']!),
  ),
  _route(
    '/loans/loan/:id/pay',
    (s) => LoanPayScreen(id: s.pathParameters['id']!),
  ),
  _route(
    '/loans/loan/:id/day/:day',
    (s) => LoanNoticeScreen(
      id: s.pathParameters['id']!,
      day: s.pathParameters['day']!,
    ),
  ),
  _route(
    '/loans/loan/:id/documents',
    (s) => LoanDocumentsScreen(loanId: s.pathParameters['id']!),
  ),
];

GoRoute _route(String path, Widget Function(GoRouterState s) build) => GoRoute(
  path: path,
  pageBuilder: (context, state) =>
      NoTransitionPage(key: state.pageKey, child: build(state)),
);
