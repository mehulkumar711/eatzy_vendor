import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'services/api_client.dart';
import 'services/voice_service_vendor.dart';
import 'services/native_comm.dart';
import 'services/native_voice_channel.dart';
import 'core/constants.dart';
import 'features/vendor_dashboard/presentation/bloc/vendor_order_bloc.dart';
import 'features/store_manager/repository/store_repository.dart';
import 'features/store_manager/repository/sync_runner.dart';

Future<void> _mergeNativeQueueIntoHive() async {
  try {
    debugPrint("Syncing native pending actions...");
    final nativeList = await NativeComm.getNativePendingActions();
    final box = Hive.box('vendor_app_box');

    // Use 'pending_actions' to match OfflineQueue
    List<dynamic> rawList = box.get('pending_actions', defaultValue: []);
    final List<Map<String, dynamic>> localPending =
        rawList.map((e) => Map<String, dynamic>.from(e)).toList();

    final Map<String, Map<String, dynamic>> byUuid = {
      for (var e in localPending) e['uuid'] as String: e
    };
    final Set<String> seenKeyPairs = {}; // action|orderId

    // build key set from local
    for (var e in localPending) {
      final key = '${e['action']}|${e['orderId']}';
      seenKeyPairs.add(key);
    }

    bool changed = false;

    for (var pa in nativeList) {
      final uuid = pa['uuid'] as String? ?? '';
      final key = '${pa['action']}|${pa['orderId']}';

      if (uuid.isNotEmpty && byUuid.containsKey(uuid)) {
        // already present -> update attempts/nextTryAt if native is further ahead
        final local = byUuid[uuid]!;
        final nativeAttempts = (pa['attempts'] as num?)?.toInt() ?? 0;
        final localAttempts = (local['attempts'] as num?)?.toInt() ?? 0;

        if (nativeAttempts > localAttempts) {
          local['attempts'] = nativeAttempts;
          local['nextTryAt'] = pa['nextTryAt'];
          changed = true;
        }
      } else if (seenKeyPairs.contains(key)) {
        // same action+order present locally but different uuid: merge by keeping earliest nextTryAt
        final local = localPending
            .firstWhere((e) => '${e['action']}|${e['orderId']}' == key);
        // Compare dates or timestamps. Assume ISO strings? Or timestamps?
        // Native passes timestamp Long often, but let's check format.
        // OfflineQueue stores ISO string for nextTryAt usually.
        // Native PendingAction has Long nextTryAt.
        // We need to normalize.
        // If local is ISO string, parse it.
        // If native is Long (from JSON it might be number).

        // Let's assume standardized on ISO string in local, but native sends number?
        // Let's check native_comm.dart decoding. It returns Map<String, dynamic>.
        // Native side MainActivity sends: obj.put("nextTryAt", pa.nextTryAt) -> Long.
        // So native is int/long.
        // OfflineQueue local stores ISO string.

        // Conversion helper
        int getTs(dynamic v) {
          if (v is int) return v;
          if (v is String) {
            return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
          }
          return 0;
        }

        final localTs = getTs(local['nextTryAt']);
        final nativeTs = getTs(pa['nextTryAt']);

        if (nativeTs < localTs && nativeTs > 0) {
          local['nextTryAt'] =
              DateTime.fromMillisecondsSinceEpoch(nativeTs).toIso8601String();
          local['attempts'] = pa[
              'attempts']; // take native attempts if we take its time? or max?
          changed = true;
        }
      } else {
        // new entry -> add
        localPending.add({
          'uuid': uuid,
          'action': pa['action'],
          'orderId': pa['orderId'],
          'payloadJson': pa['payloadJson'],
          'attempts': pa['attempts'],
          'nextTryAt': DateTime.fromMillisecondsSinceEpoch(
                  (pa['nextTryAt'] as num?)?.toInt() ?? 0)
              .toIso8601String(),
          'createdAt': DateTime.now().toIso8601String()
        });
        changed = true;
      }
    }

    if (changed) {
      await box.put('pending_actions', localPending);
      debugPrint("Synced and merged ${nativeList.length} native actions.");
    }
  } catch (e) {
    debugPrint("Error syncing native queue: $e");
  }
}

/// Top-level background handler for FCM messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.data.isNotEmpty && message.data['type'] == 'order') {
    final orderJson = jsonEncode(message.data['order'] ?? message.data);
    if (!kIsWeb) {
      try {
        await NativeComm.startNativeVoiceService(orderJson);
      } catch (e) {
        debugPrint('Background handler: Failed to start native service: $e');
      }
    }
  }
}

Future<void> bootstrapVendor() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('vendor_app_box');

  // Create or open a dedicated box for offline queue if using one, or use vendor_app_box
  // The implementations use 'vendor_app_box' generally.
  // We'll optionally open 'pending_actions' box if the implementation separated it,
  // but let's assume one box for simplicity or check OfflineQueue implementation.
  // OfflineQueue often uses 'offline_queue' box.

  await _mergeNativeQueueIntoHive();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  ApiClient.init(baseUrl: Constants.apiBaseUrl);
  await VoiceServiceVendor.instance.init();

  // Initialize Store Sync
  final storeRepo = await StoreRepository.create();
  final syncRunner = SyncRunner(storeRepo);
  syncRunner.start(interval: Duration(seconds: 30));

  // Create the BLoC and start listening to native voice events
  final bloc = VendorOrderBloc();

  NativeVoiceChannel.voiceStream().listen((event) {
    final type = event['type'];
    final payload = event['payload'];

    if (type == null) return;

    // Dispatch corresponding BLoC event
    switch (type) {
      case 'ACCEPT':
        bloc.add(NativeVoiceAcceptEvent(payload ?? {}));
        break;
      case 'REJECT':
        bloc.add(NativeVoiceRejectEvent(payload ?? {}));
        break;
      case 'READY':
        bloc.add(NativeVoiceReadyEvent(payload ?? {}));
        break;
      case 'AWAIT_MANUAL':
        bloc.add(NativeVoiceAwaitManualEvent(payload ?? {}));
        break;
      case 'REPEAT':
        bloc.add(NativeVoiceRepeatEvent(payload ?? {}));
        break;
      case 'UNKNOWN':
        bloc.add(NativeVoiceUnknownEvent(payload ?? {}));
        break;
      default:
        debugPrint('Unknown native voice event type: $type');
    }
  });

  runApp(
    BlocProvider.value(
      value: bloc,
      child: const EatzyVendorApp(),
    ),
  );
}

void _handleForegroundMessage(RemoteMessage message) {
  debugPrint('Foreground message received: ${message.data}');
  if (message.data.isNotEmpty && message.data['type'] == 'order') {
    _foregroundOrderController.add(message.data);
  }
}

void _handleMessageOpenedApp(RemoteMessage message) {
  debugPrint('Message opened app: ${message.data}');
}

final StreamController<Map<String, dynamic>> _foregroundOrderController =
    StreamController<Map<String, dynamic>>.broadcast();

Stream<Map<String, dynamic>> get foregroundOrderStream =>
    _foregroundOrderController.stream;
