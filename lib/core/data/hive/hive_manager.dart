import 'package:hive_ce/hive.dart';
import 'package:massdrive/core/constants/enum/hive_key.dart';

class HiveManager {
  Future<void> openAllBox() async {
    await Hive.openBox(HiveBoxType.cart);
  }

  /// Create/Update
  /// HiveManager().put(HiveBoxType.cart, HiveKey.cartList, value)
  Future<void> put<T>(String boxType, String hiveKey, T value) async {
    await Hive.box(boxType).put(hiveKey, value);
  }

  /// Read
  /// HiveManager().get(HiveBoxType.cart, HiveKey.cartList) as String)
  Object? get(String boxType, String hiveKey, {Object? defaultValue}) {
    return Hive.box(boxType).get(hiveKey, defaultValue: defaultValue);
  }

  /// Delete
  /// HiveManager().delete(HiveBoxType.cart, HiveKey.cartList);
  Future<void> delete(String boxType, String hiveKey) async {
    await Hive.box(boxType).delete(hiveKey);
  }

  /// Clear box
  /// await HiveManager().clearBox(BoxType.cart);
  Future<void> clearBox(String boxType) async {
    await Hive.box(boxType).clear();
  }

  /// Clear all box
  /// await HiveManager().clearAllBoxes();
  Future<void> clearAllBoxes() async {
    await Hive.box(HiveBoxType.cart).clear();
  }

  /// Check key is avaliable
  /// HiveManager().contains(HiveBoxType.cart, HiveKey.cartList)
  bool contains(String boxType, String hiveKey) {
    return Hive.box(boxType).containsKey(hiveKey);
  }

  Future<void> close() async {
    await Hive.close();
  }
}
