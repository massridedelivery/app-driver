import 'package:flutter/material.dart';

/// A Thai bank entry for the payout bank-account selector.
///
/// [code] is the common symbol (BBL, KBANK, …), [name] the short Thai name,
/// [nameLong] the full Thai name actually sent to the backend as `bank_name`,
/// and [nameEn] the English name (shown as a subtitle / searchable).
///
/// [brandColor] is the bank's brand colour, used for the badge avatar. We render
/// an original coloured badge with the bank code — not the bank's trademarked
/// logo artwork. If the team later adds official logo PNGs under
/// `assets/images/banks/<code>.png` and declares that folder in pubspec, flip
/// [BankLogoAvatar.useBundledLogos] to true and they'll be used automatically.
@immutable
class ThaiBank {
  final String code;
  final String name;
  final String nameLong;
  final String nameEn;
  final Color brandColor;

  /// Bank of Thailand 3-digit bank code — what payout requests must carry so
  /// the transfer goes to the right bank.
  final String botCode;

  const ThaiBank({
    required this.code,
    required this.botCode,
    required this.name,
    required this.nameLong,
    required this.nameEn,
    required this.brandColor,
  });

  /// Asset path the team can drop an official logo into (not bundled yet).
  String get logoAsset => 'assets/images/banks/$code.png';

  /// Pick readable badge text colour (dark on light brand colours like yellow).
  Color get onBrandColor => brandColor.computeLuminance() > 0.6
      ? const Color(0xFF1A1A1A)
      : Colors.white;
}

/// All current Thai banks offered in the payout selector. Names/codes follow the
/// common BOT symbols; excludes e-wallets (PromptPay/TrueMoney) since this screen
/// collects a bank passbook account.
const List<ThaiBank> kThaiBanks = [
  ThaiBank(
    code: 'KBANK',
    botCode: '004',
    name: 'กสิกรไทย',
    nameLong: 'ธนาคารกสิกรไทย',
    nameEn: 'Kasikorn Bank',
    brandColor: Color(0xFF138F2D),
  ),
  ThaiBank(
    code: 'SCB',
    botCode: '014',
    name: 'ไทยพาณิชย์',
    nameLong: 'ธนาคารไทยพาณิชย์',
    nameEn: 'Siam Commercial Bank',
    brandColor: Color(0xFF4E2E7F),
  ),
  ThaiBank(
    code: 'BBL',
    botCode: '002',
    name: 'กรุงเทพ',
    nameLong: 'ธนาคารกรุงเทพ',
    nameEn: 'Bangkok Bank',
    brandColor: Color(0xFF1E4598),
  ),
  ThaiBank(
    code: 'KTB',
    botCode: '006',
    name: 'กรุงไทย',
    nameLong: 'ธนาคารกรุงไทย',
    nameEn: 'Krungthai Bank',
    brandColor: Color(0xFF00A0E9),
  ),
  ThaiBank(
    code: 'BAY',
    botCode: '025',
    name: 'กรุงศรีอยุธยา',
    nameLong: 'ธนาคารกรุงศรีอยุธยา',
    nameEn: 'Krungsri (Bank of Ayudhya)',
    brandColor: Color(0xFFFEC43B),
  ),
  ThaiBank(
    code: 'TTB',
    botCode: '011',
    name: 'ทีเอ็มบีธนชาต',
    nameLong: 'ธนาคารทีเอ็มบีธนชาต',
    nameEn: 'TMBThanachart Bank (ttb)',
    brandColor: Color(0xFF1279BE),
  ),
  ThaiBank(
    code: 'GSB',
    botCode: '030',
    name: 'ออมสิน',
    nameLong: 'ธนาคารออมสิน',
    nameEn: 'Government Savings Bank',
    brandColor: Color(0xFFEB198D),
  ),
  ThaiBank(
    code: 'BAAC',
    botCode: '034',
    name: 'ธ.ก.ส.',
    nameLong: 'ธนาคารเพื่อการเกษตรและสหกรณ์การเกษตร',
    nameEn: 'Bank for Agriculture and Agricultural Cooperatives',
    brandColor: Color(0xFF2E8B57),
  ),
  ThaiBank(
    code: 'GHB',
    botCode: '033',
    name: 'ธ.อ.ส.',
    nameLong: 'ธนาคารอาคารสงเคราะห์',
    nameEn: 'Government Housing Bank',
    brandColor: Color(0xFFF7941E),
  ),
  ThaiBank(
    code: 'KKP',
    botCode: '069',
    name: 'เกียรตินาคินภัทร',
    nameLong: 'ธนาคารเกียรตินาคินภัทร',
    nameEn: 'Kiatnakin Phatra Bank',
    brandColor: Color(0xFF006FB9),
  ),
  ThaiBank(
    code: 'TISCO',
    botCode: '067',
    name: 'ทิสโก้',
    nameLong: 'ธนาคารทิสโก้',
    nameEn: 'Tisco Bank',
    brandColor: Color(0xFF003B8E),
  ),
  ThaiBank(
    code: 'CIMB',
    botCode: '022',
    name: 'ซีไอเอ็มบี ไทย',
    nameLong: 'ธนาคารซีไอเอ็มบี ไทย',
    nameEn: 'CIMB Thai Bank',
    brandColor: Color(0xFFAB1F24),
  ),
  ThaiBank(
    code: 'UOB',
    botCode: '024',
    name: 'ยูโอบี',
    nameLong: 'ธนาคารยูโอบี',
    nameEn: 'United Overseas Bank (Thai)',
    brandColor: Color(0xFF005CB9),
  ),
  ThaiBank(
    code: 'TCRB',
    botCode: '071',
    name: 'ไทยเครดิต',
    nameLong: 'ธนาคารไทยเครดิต',
    nameEn: 'Thai Credit Bank',
    brandColor: Color(0xFFF15A22),
  ),
  ThaiBank(
    code: 'LHB',
    botCode: '073',
    name: 'แลนด์ แอนด์ เฮ้าส์',
    nameLong: 'ธนาคารแลนด์ แอนด์ เฮ้าส์',
    nameEn: 'Land and Houses Bank',
    brandColor: Color(0xFFF58220),
  ),
  ThaiBank(
    code: 'IBANK',
    botCode: '066',
    name: 'อิสลามแห่งประเทศไทย',
    nameLong: 'ธนาคารอิสลามแห่งประเทศไทย',
    nameEn: 'Islamic Bank of Thailand',
    brandColor: Color(0xFF0B7A3D),
  ),
  ThaiBank(
    code: 'ICBC',
    botCode: '070',
    name: 'ไอซีบีซี (ไทย)',
    nameLong: 'ธนาคารไอซีบีซี (ไทย)',
    nameEn: 'ICBC (Thai)',
    brandColor: Color(0xFFE60012),
  ),
  ThaiBank(
    code: 'CITI',
    botCode: '017',
    name: 'ซิตี้แบงก์',
    nameLong: 'ธนาคารซิตี้แบงก์',
    nameEn: 'Citibank',
    brandColor: Color(0xFF056DAE),
  ),
  ThaiBank(
    code: 'HSBC',
    botCode: '031',
    name: 'เอชเอสบีซี',
    nameLong: 'ธนาคารเอชเอสบีซี',
    nameEn: 'HSBC Thailand',
    brandColor: Color(0xFFDB0011),
  ),
];

/// Resolve a stored `bank_name` string back to a [ThaiBank] so an existing
/// account pre-selects correctly. Matches the full Thai name, short name,
/// English name, or code, case/space-insensitively.
ThaiBank? findThaiBank(String? stored) {
  if (stored == null) return null;
  final q = stored.trim().toLowerCase();
  if (q.isEmpty) return null;
  for (final b in kThaiBanks) {
    if (b.botCode == q ||
        b.nameLong.toLowerCase() == q ||
        b.name.toLowerCase() == q ||
        b.nameEn.toLowerCase() == q ||
        b.code.toLowerCase() == q) {
      return b;
    }
  }
  // Looser contains match as a fallback (e.g. "กสิกรไทย" inside a longer string).
  for (final b in kThaiBanks) {
    if (q.contains(b.name.toLowerCase()) || q.contains(b.code.toLowerCase())) {
      return b;
    }
  }
  return null;
}

/// Bank of Thailand code for a stored payout `bank_name` (Thai or English name,
/// or a short code like "kbank"), or null when the bank isn't recognised —
/// callers must not guess a default, or the money goes to the wrong bank.
String? thaiBankCode(String? bankName) => findThaiBank(bankName)?.botCode;
