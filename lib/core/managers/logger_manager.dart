import 'package:talker_flutter/talker_flutter.dart';

class LoggerManager {
  static final LoggerManager _instance = LoggerManager._internal();
  static LoggerManager get instance => _instance;

  final talker = TalkerFlutter.init();

  LoggerManager._internal();
}
