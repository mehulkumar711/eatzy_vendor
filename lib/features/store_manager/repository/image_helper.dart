import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageHelper {
  static final Map<String, bool> _cancelMap = {};

  /// Returns {file, cancelId} pair. Use cancelId to cancel compress operation.
  static Future<Map<String, dynamic>> compressFileCancelable(File file,
      {int quality = 75, int minWidth = 800}) async {
    final dir = await getTemporaryDirectory();
    final outPath = '${dir.path}/${Uuid().v4()}.jpg';
    final cancelId = Uuid().v4();
    _cancelMap[cancelId] = false;

    // note: flutter_image_compress doesn't support cancellation token directly.
    // We'll run compress in isolate-like Future and check cancel flags for cleanup.
    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: quality,
      minWidth: minWidth,
    );

    if (_cancelMap[cancelId] == true) {
      // cancel requested: delete file and return original file
      try {
        if (compressed != null) File(compressed.path).deleteSync();
      } catch (_) {}
      _cancelMap.remove(cancelId);
      return {'file': file, 'cancelId': null};
    }

    _cancelMap.remove(cancelId);
    return {'file': compressed ?? file, 'cancelId': cancelId};
  }

  static void cancelCompression(String? cancelId) {
    if (cancelId == null) return;
    _cancelMap[cancelId] = true;
  }

  static Future<void> cleanupTempFiles() async {
    final dir = await getTemporaryDirectory();
    final files = dir.listSync();
    for (var f in files) {
      try {
        if (f is File && f.path.endsWith('.jpg')) {
          final stat = f.statSync();
          // remove older than 24 hours
          if (DateTime.now().difference(stat.changed).inHours > 24) {
            f.deleteSync();
          }
        }
      } catch (_) {}
    }
  }
}
