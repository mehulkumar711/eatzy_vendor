import 'dart:async';
import 'store_repository.dart';

class SyncRunner {
  final StoreRepository _repo;
  Timer? _timer;

  SyncRunner(this._repo);

  void start({Duration interval = const Duration(seconds: 20)}) {
    _timer ??= Timer.periodic(interval, (_) => _repo.syncPendingItemActions());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> runOnce() async {
    await _repo.syncPendingItemActions();
  }
}
