import 'package:flutter/foundation.dart';

/// A marketing campaign push. Told apart from job offers and other pushes by
/// `data.campaign_id` (there is no `data.type`); it never routes to the job
/// screens.
class CampaignPush {
  const CampaignPush({required this.campaignId, this.notificationId});

  /// Null when [data] isn't a campaign.
  static CampaignPush? fromData(Map<String, dynamic> data) {
    final campaign = data['campaign_id']?.toString();
    if (campaign == null || campaign.isEmpty) return null;
    final row = data['notification_id']?.toString();
    return CampaignPush(
      campaignId: campaign,
      notificationId: row == null || row.isEmpty ? null : row,
    );
  }

  /// Back from a local-notification payload (the Android foreground copy).
  static CampaignPush? fromPayload(String? payload) {
    final parts = payload?.split('|');
    if (parts == null || parts.length != 3 || parts[0] != 'campaign') {
      return null;
    }
    return CampaignPush(
      campaignId: parts[1],
      notificationId: parts[2].isEmpty ? null : parts[2],
    );
  }

  final String campaignId;

  /// The inbox row this push created; missing on an admin's test push to
  /// their own phone.
  final String? notificationId;

  String get payload => 'campaign|$campaignId|${notificationId ?? ''}';
}

/// "Something new landed in the inbox" (a campaign push arrived): the badge
/// re-reads its count.
class InboxUpdates extends ChangeNotifier {
  InboxUpdates._();
  static final InboxUpdates instance = InboxUpdates._();

  void notifyChanged() => notifyListeners();
}
