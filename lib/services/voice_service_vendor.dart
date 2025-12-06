import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:just_audio/just_audio.dart';
import 'package:hive/hive.dart';
import '../core/constants.dart';
import 'native_comm.dart';

/// VoiceServiceVendor handles TTS, STT, and audio for the vendor app.
///
/// When app is in foreground: uses in-app TTS/STT via Flutter plugins.
/// When app is backgrounded: delegates to native Android service via NativeComm.
class VoiceServiceVendor {
  VoiceServiceVendor._private();
  static final VoiceServiceVendor instance = VoiceServiceVendor._private();

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();
  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  bool _isListening = false;

  /// Stream subscription for native results
  StreamSubscription<Map<String, dynamic>>? _nativeResultSubscription;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    _initialized = true;
    // NativeComm is static and doesn't need init
  }

  /// Subscribe to native voice results.
  /// Call this from VendorOrderBloc to receive results from background processing.
  void subscribeToNativeResults(void Function(Map<String, dynamic>) onResult) {
    _nativeResultSubscription?.cancel();
    _nativeResultSubscription = NativeComm.voiceStream().listen(onResult);
  }

  void unsubscribeFromNativeResults() {
    _nativeResultSubscription?.cancel();
    _nativeResultSubscription = null;
  }

  Future<void> playPing() async {
    try {
      await _player.setAsset('assets/sounds/tasty_ping.mp3');
      await _player.play();
    } catch (e) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> speak(
    String text, {
    String? locale,
    bool customerVoice = false,
  }) async {
    if (locale != null) {
      try {
        await _tts.setLanguage(locale);
      } catch (_) {}
    }
    await _tts.speak(text);
  }

  Future<void> stopSpeak() => _tts.stop();

  Future<void> listen({
    required Duration timeout,
    required void Function(String recognizedText) onResult,
    required void Function() onError,
  }) async {
    final available = await _stt.initialize(onStatus: (s) {}, onError: (e) {});
    if (!available) {
      onError();
      return;
    }
    _isListening = true;
    final buffer = StringBuffer();
    _stt.listen(
      onResult: (result) {
        buffer.write(result.recognizedWords);
        if (result.finalResult) {
          _isListening = false;
          onResult(buffer.toString());
        }
      },
      listenFor: timeout,
      pauseFor: timeout,
      localeId: await _preferredLocale(),
    );
    // Safety timeout to ensure stop is called
    Future.delayed(timeout + const Duration(seconds: 1), () {
      if (_isListening) {
        _stt.stop();
        _isListening = false;
        if (buffer.isNotEmpty) {
          onResult(buffer.toString());
        }
      }
    });
  }

  Future<String> _preferredLocale() async {
    final box = Hive.box('vendor_app_box');
    return box.get('vendor_locale', defaultValue: 'en_US') as String;
  }

  Future<void> playGuide(String languageCode) async {
    await playPing();
    await speak(
      'Welcome to Eatzy. This guide will help you set up your shop.',
      locale: languageCode,
    );
  }

  // ============ Native Delegation for Background Processing ============

  /// Handle incoming order using native service.
  ///
  /// Called when app is backgrounded and FCM triggers order notification.
  /// Native service will:
  /// 1. Play tasty ping
  /// 2. Speak order via TTS
  /// 3. Listen for vendor response
  /// 4. Broadcast result back via NativeComm
  Future<bool> handleIncomingOrderNative(Map<String, dynamic> order) async {
    final json = jsonEncode(order);
    return await NativeComm.startNativeVoiceService(json);
  }

  /// Format order data for TTS readout
  String formatOrderForTTS(Map<String, dynamic> order) {
    final id = order['id'] ?? 'unknown';
    final isParcel = order['isParcel'] ?? true;
    final items = order['items'] as List<dynamic>? ?? [];
    final itemsText = items.map((item) {
      final qty = item['quantity'] ?? 1;
      final name = item['name'] ?? 'item';
      return '$qty $name';
    }).join(', ');

    return 'Order Number $id. ${isParcel ? "Parcel" : "Dine in"}. Items: $itemsText. Accept? Reject? Ready?';
  }

  /// Full in-app voice flow for foreground order handling
  Future<void> handleIncomingOrderInApp(
    Map<String, dynamic> order, {
    required void Function(String command) onCommand,
    required void Function() onFallback,
  }) async {
    await playPing();
    final locale = await _preferredLocale();
    final spoken = formatOrderForTTS(order);
    await speak(spoken, locale: locale);

    // Wait for TTS to finish
    await Future.delayed(const Duration(milliseconds: 500));

    // Listen for response
    await listen(
      timeout: const Duration(seconds: 12),
      onResult: (text) {
        final normalized = text.toLowerCase();
        if (normalized.contains('accept') ||
            normalized.contains('ok') ||
            normalized.contains('theek')) {
          onCommand('ACCEPT');
        } else if (normalized.contains('reject') ||
            normalized.contains('cancel') ||
            normalized.contains('nahi')) {
          onCommand('REJECT');
        } else if (normalized.contains('ready') ||
            normalized.contains('tayyar')) {
          onCommand('READY');
        } else if (normalized.contains('repeat') ||
            normalized.contains('dobara')) {
          onCommand('REPEAT');
        } else {
          onCommand('UNKNOWN:$text');
        }
      },
      onError: onFallback,
    );
  }

  void dispose() {
    _player.dispose();
    _tts.stop();
    _stt.stop();
    unsubscribeFromNativeResults();
    // NativeComm has no dispose
  }
}
