import 'package:flutter/widgets.dart';

/// Copy for the update screen and dialog. The rest of the app is Thai-only and
/// MaterialApp sets no locales, so the device language picks: English when it
/// is English, Thai otherwise.
class UpdateStrings {
  const UpdateStrings._({
    required this.thai,
    required this.forceTitle,
    required this.forceBody,
    required this.updateButton,
    required this.suggestTitle,
    required this.suggestBody,
    required this.later,
    required this.openStoreFailed,
    required this.newVersionLabel,
  });

  static const th = UpdateStrings._(
    thai: true,
    forceTitle: 'กรุณาอัปเดตแอป',
    forceBody:
        'เวอร์ชันที่ใช้อยู่ไม่รองรับแล้ว\nอัปเดตเป็นเวอร์ชันล่าสุดเพื่อรับงานต่อได้',
    updateButton: 'อัปเดต',
    suggestTitle: 'มีเวอร์ชันใหม่',
    suggestBody: 'อัปเดตแอปเพื่อใช้ฟีเจอร์ล่าสุดและการแก้ไขปัญหา',
    later: 'ไว้ทีหลัง',
    openStoreFailed: 'เปิดสโตร์ไม่ได้ ลองอีกครั้ง',
    newVersionLabel: 'เวอร์ชันใหม่',
  );

  static const en = UpdateStrings._(
    thai: false,
    forceTitle: 'Please update the app',
    forceBody:
        'This version is no longer supported.\nUpdate to the latest version to keep taking jobs.',
    updateButton: 'Update',
    suggestTitle: 'New version available',
    suggestBody: 'Update the app for the latest features and fixes.',
    later: 'Later',
    openStoreFailed: "Couldn't open the store. Please try again.",
    newVersionLabel: 'New version',
  );

  static UpdateStrings of(BuildContext context) {
    final lang = View.maybeOf(context)?.platformDispatcher.locale.languageCode;
    return lang == 'en' ? en : th;
  }

  /// Picks the backend's `message_th` over `message` when true.
  final bool thai;
  final String forceTitle;
  final String forceBody;
  final String updateButton;
  final String suggestTitle;
  final String suggestBody;
  final String later;
  final String openStoreFailed;
  final String newVersionLabel;
}
