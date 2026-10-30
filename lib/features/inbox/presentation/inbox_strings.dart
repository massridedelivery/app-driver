import 'package:flutter/widgets.dart';
import 'package:massdrive/core/utils/thai_date.dart';

/// Copy for the inbox. Like the update screen, the device language picks:
/// English when it is English, Thai otherwise (the app sets no locales).
class InboxStrings {
  const InboxStrings._({
    required this.thai,
    required this.title,
    required this.detailTitle,
    required this.readAll,
    required this.deleteAllTooltip,
    required this.deleteAllTitle,
    required this.deleteAllBody,
    required this.deleteAllConfirm,
    required this.cancel,
    required this.delete,
    required this.deleteThis,
    required this.emptyTitle,
    required this.emptyBody,
    required this.loadFailed,
    required this.retry,
    required this.deleteFailed,
    required this.actionFailed,
    required this.openQuests,
    required this.openLink,
    required this.today,
    required this.yesterday,
    required this.notificationsSection,
    required this.marketingTitle,
    required this.marketingBody,
    required this.marketingFailed,
  });

  static const th = InboxStrings._(
    thai: true,
    title: 'กล่องข้อความ',
    detailTitle: 'ข้อความ',
    readAll: 'อ่านทั้งหมด',
    deleteAllTooltip: 'ลบทั้งหมด',
    deleteAllTitle: 'ลบข้อความทั้งหมด?',
    deleteAllBody: 'ย้อนกลับไม่ได้',
    deleteAllConfirm: 'ลบทั้งหมด',
    cancel: 'ยกเลิก',
    delete: 'ลบ',
    deleteThis: 'ลบข้อความนี้',
    emptyTitle: 'ยังไม่มีข้อความ',
    emptyBody: 'ข่าวสาร โปรโมชัน และภารกิจใหม่จากบริษัทจะมาอยู่ที่นี่',
    loadFailed: 'โหลดข้อความไม่สำเร็จ',
    retry: 'ลองอีกครั้ง',
    deleteFailed: 'ลบข้อความไม่สำเร็จ ลองอีกครั้ง',
    actionFailed: 'ทำรายการไม่สำเร็จ ลองอีกครั้ง',
    openQuests: 'ไปที่ภารกิจ',
    openLink: 'เปิดลิงก์',
    today: 'วันนี้',
    yesterday: 'เมื่อวาน',
    notificationsSection: 'การแจ้งเตือน',
    marketingTitle: 'ข่าวสารและโปรโมชั่น',
    marketingBody:
        'ข้อเสนอ ภารกิจโบนัส และข่าวจากบริษัท ปิดแล้วยังได้รับแจ้งเตือนงาน แชท และบัญชีตามปกติ',
    marketingFailed: 'บันทึกการตั้งค่าไม่สำเร็จ ลองอีกครั้ง',
  );

  static const en = InboxStrings._(
    thai: false,
    title: 'Inbox',
    detailTitle: 'Message',
    readAll: 'Mark all read',
    deleteAllTooltip: 'Delete all',
    deleteAllTitle: 'Delete all messages?',
    deleteAllBody: "This can't be undone.",
    deleteAllConfirm: 'Delete all',
    cancel: 'Cancel',
    delete: 'Delete',
    deleteThis: 'Delete this message',
    emptyTitle: 'No messages yet',
    emptyBody: 'News, promotions and new quests from the company show up here.',
    loadFailed: "Couldn't load your messages",
    retry: 'Try again',
    deleteFailed: "Couldn't delete the message. Try again.",
    actionFailed: "That didn't go through. Try again.",
    openQuests: 'Go to quests',
    openLink: 'Open link',
    today: 'Today',
    yesterday: 'Yesterday',
    notificationsSection: 'Notifications',
    marketingTitle: 'News and promotions',
    marketingBody:
        'Offers, bonus quests and company news. Turned off, you still get job, chat and account notifications.',
    marketingFailed: "Couldn't save the setting. Try again.",
  );

  static InboxStrings of(BuildContext context) {
    final lang = View.maybeOf(context)?.platformDispatcher.locale.languageCode;
    return lang == 'en' ? en : th;
  }

  final bool thai;
  final String title;
  final String detailTitle;
  final String readAll;
  final String deleteAllTooltip;
  final String deleteAllTitle;
  final String deleteAllBody;
  final String deleteAllConfirm;
  final String cancel;
  final String delete;
  final String deleteThis;
  final String emptyTitle;
  final String emptyBody;
  final String loadFailed;
  final String retry;
  final String deleteFailed;
  final String actionFailed;
  final String openQuests;
  final String openLink;
  final String today;
  final String yesterday;
  final String notificationsSection;
  final String marketingTitle;
  final String marketingBody;
  final String marketingFailed;

  /// Group header: "วันนี้", "เมื่อวาน", else the date ("28 ต.ค. 2569").
  String day(DateTime at, DateTime now) {
    final d = DateTime(at.year, at.month, at.day);
    final today0 = DateTime(now.year, now.month, now.day);
    final diff = today0.difference(d).inDays;
    if (diff == 0) return today;
    if (diff == 1) return yesterday;
    return thai
        ? formatThaiDate(at)
        : '${at.day} ${_enMonths[at.month - 1]} ${at.year}';
  }

  // Hand-formatted: main() only loads th_TH date symbols for intl.
  static const _enMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String time(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  /// A card's time: relative within the hour/day ("5 นาทีที่แล้ว"), else the
  /// clock time under its day header.
  String ago(DateTime at, DateTime now) {
    final d = now.difference(at);
    if (d.isNegative || d.inMinutes < 1) {
      return thai ? 'เมื่อสักครู่' : 'Just now';
    }
    if (d.inMinutes < 60) {
      return thai ? '${d.inMinutes} นาทีที่แล้ว' : '${d.inMinutes} min ago';
    }
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    if (sameDay) {
      return thai ? '${d.inHours} ชั่วโมงที่แล้ว' : '${d.inHours} h ago';
    }
    return time(at);
  }

  /// "วันนี้ 10:24" on the detail screen.
  String stamp(DateTime at, DateTime now) => '${day(at, now)} ${time(at)}';
}
