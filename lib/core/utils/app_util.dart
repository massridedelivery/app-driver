import 'package:package_info_plus/package_info_plus.dart';

class AppUtil {
  static String? _appName;
  static String? _packageName;
  static String? _version;
  static String? _buildNumber;

  static Future<void> initialPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setPackageInfo(
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }

  static void setPackageInfo({
    String? appName,
    String? packageName,
    String? version,
    String? buildNumber,
  }) {
    _appName = appName;
    _packageName = packageName;
    _version = version;
    _buildNumber = buildNumber;
  }

  static PackageInfo getPackageInfo() {
    return PackageInfo(
      appName: _appName ?? 'MassDrive',
      packageName: _packageName ?? 'com.massdrive.app',
      version: _version ?? '1.0.0',
      buildNumber: _buildNumber ?? '1',
    );
  }
}
