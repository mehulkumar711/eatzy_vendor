import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class NativeVoiceChannel {
  static const EventChannel _voiceEvents =
      EventChannel('com.eatzy/vendor_voice_events');

  static Stream<Map<String, dynamic>> voiceStream() {
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
