import 'package:hive/hive.dart';
import 'dart:async';
import '../services/api_client.dart';

class OfflineQueue {
  final Box _box = Hive.box('vendor_app_box');
  Timer? _poller;

  void startPolling() {
    _poller ??= Timer.periodic(Duration(seconds: 15), (_) => _process());
  }

  void stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  Future<void> enqueue(Map<String, dynamic> action) async {
    final pending = _box.get('pending_actions', defaultValue: []) as List;
    pending.add(action);
    await _box.put('pending_actions', pending);
  }

  Future<void> _process() async {
    final List pending = _box.get('pending_actions', defaultValue: []) as List;
    if (pending.isEmpty) return;
    final now = DateTime.now();
    final remaining = <dynamic>[];
    for (var item in pending) {
      try {
        final action = item['action'];
        final orderId = item['orderId'];
        // attempts read in catch block if needed
        if (action == 'accept') {
          await ApiClient.instance.post('/orders/$orderId/accept');
        } else if (action == 'reject') {
          await ApiClient.instance.post('/orders/$orderId/reject');
        } else if (action == 'ready') {
          await ApiClient.instance.post('/orders/$orderId/ready');
        } else {
          // custom
        }
      } catch (e) {
        final currentAttempts = (item['attempts'] ?? 0) as int;
        final newAttempts = currentAttempts + 1;
        item['attempts'] = newAttempts;
        item['nextTryAt'] =
            now.add(Duration(seconds: 2 << newAttempts)).toIso8601String();
        remaining.add(item);
      }
    }
    await _box.put('pending_actions', remaining);
  }
}
