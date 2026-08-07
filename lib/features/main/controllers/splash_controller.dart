import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:massdrive/core/data/hive/hive_manager.dart';
import 'package:massdrive/core/utils/app_util.dart';

final splashControllerProvider = FutureProvider<void>((ref) async {
  await AppUtil.initialPackageInfo();
  await GetStorage.init();
  await Hive.initFlutter();
  await HiveManager().openAllBox();
});
