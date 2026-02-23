class AppConfig {
  final String flavorName;
  final String region;

  const AppConfig({required this.flavorName, required this.region});

  static AppConfig? _instance;

  static AppConfig getInstance({
    required String flavorName,
    required String region,
  }) {
    if (_instance == null) {
      _instance = AppConfig(flavorName: flavorName, region: region);
      return _instance!;
    }
    return _instance!;
  }
}
