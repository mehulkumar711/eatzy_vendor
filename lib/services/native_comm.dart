import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class NativeComm {
  static const MethodChannel _channel =
      MethodChannel('com.eatzy.eatzy_vendor/native');
  static const EventChannel _voiceEvents =
      EventChannel('com.eatzy/vendor_voice_events');
  static const EventChannel _pendingEvents =
      EventChannel('com.eatzy/pending_action_events');

  /// Starts the native foreground service with the provided [orderJson].
  static Future<bool> startNativeVoiceService(String orderJson) async {
    try {
      final res = await _channel
          .invokeMethod('startNativeVoiceService', {'orderJson': orderJson});
      return res == true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Checks if the Enterprise module is enabled (native side).
  static Future<bool> isEnterpriseEnabled() async {
    try {
      final res = await _channel.invokeMethod('isEnterpriseEnabled');
      return res == true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Request current native queued actions (synchronous RPC)
  static Future<List<Map<String, dynamic>>> getNativePendingActions() async {
    try {
      final res = await _channel.invokeMethod('getPendingActions');
      if (res is String) {
        final List parsed = jsonDecode(res) as List;
        return parsed.map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (res is List) {
        return res.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        return [];
      }
    } on PlatformException catch (_) {
      return [];
    }
  }

  /// Send a pending action to native queue (e.g. for background execution)
  static Future<bool> sendPendingAction(Map<String, dynamic> action) async {
    try {
      final res =
          await _channel.invokeMethod('sendPendingAction', {'action': action});
      return res == true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Listen to native pending action events (CREATED, RETRY, SUCCEEDED, ERROR)
  static Stream<Map<String, dynamic>> pendingActionStream() {
    return _pendingEvents.receiveBroadcastStream().map((event) {
      if (event is String) {
        return Map<String, dynamic>.from(jsonDecode(event));
      } else if (event is Map) {
        return Map<String, dynamic>.from(event);
      } else {
        return {};
      }
    });
  }

  /// Voice command stream (ACCEPT, REJECT, READY, etc.)
  static Stream<Map<String, dynamic>> voiceStream() {
    // Note: Use NativeVoiceChannel for this typically, but exposing here for completeness if needed
    // or rely on NativeVoiceChannel.
    // Let's keep using NativeVoiceChannel class for voice events to avoid duplication
    // but NativeComm is the central place now?
    return _voiceEvents.receiveBroadcastStream().map((event) {
      if (event is String) {
        return Map<String, dynamic>.from(jsonDecode(event));
      } else if (event is Map) {
        return Map<String, dynamic>.from(event);
      } else {
        return {};
      }
    });
  }
}
