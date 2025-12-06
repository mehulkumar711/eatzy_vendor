import 'dart:io';
import 'package:hive/hive.dart';

class HiveTestHelper {
  /// Initializes Hive in a temp directory and opens the vendor box.
  /// Returns a cleanup callback to delete the temp directory after tests.
  static Future<Function> initHiveForTest() async {
    final tmp = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tmp.path);
    await Hive.openBox('vendor_app_box');
    return () {
      try {
        Hive.close();
        tmp.deleteSync(recursive: true);
      } catch (_) {}
    };
  }
}
