import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> ensureMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final r = await Permission.microphone.request();
    return r.isGranted;
  }
}
