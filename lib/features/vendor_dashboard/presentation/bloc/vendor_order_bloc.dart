import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import 'package:eatzy_vendor/services/voice_service_vendor.dart';
import 'package:eatzy_vendor/utils/regex_utils.dart';
import 'package:eatzy_vendor/services/api_client.dart';
import 'package:eatzy_vendor/utils/offline_queue.dart';
import 'package:eatzy_vendor/utils/models.dart';

part 'vendor_order_event.dart';
part 'vendor_order_state.dart';

class VendorOrderBloc extends Bloc<VendorOrderEvent, VendorOrderState> {
  final OfflineQueue _offlineQueue = OfflineQueue();

  VendorOrderBloc() : super(VendorOrderInitial()) {
    _offlineQueue.startPolling();
    on<IncomingOrderEvent>(_onIncomingOrder);
    on<VoiceResultEvent>(_onVoiceResult);
    on<AcceptOrderEvent>(_onAcceptOrder);
    on<RejectOrderEvent>(_onRejectOrder);
    on<ReadyOrderEvent>(_onReadyOrder);
    on<RetryListeningEvent>(_onRetryListening);
    on<NativeVoiceAcceptEvent>(_onNativeAccept);
    on<NativeVoiceRejectEvent>(_onNativeReject);
    on<NativeVoiceReadyEvent>(_onNativeReady);
    on<NativeVoiceRepeatEvent>(_onNativeRepeat);
    on<NativeVoiceAwaitManualEvent>(_onNativeAwaitManual);
    on<NativeVoiceUnknownEvent>(_onNativeUnknown);
  }

  Future<void> _onIncomingOrder(IncomingOrderEvent event, Emitter emit) async {
    emit(VendorOrderIncoming(order: event.order));

    await VoiceServiceVendor.instance.playPing();
    final ttsText = _formatOrderForTTS(event.order);
    await VoiceServiceVendor.instance.speak(
      ttsText,
      customerVoice: true,
      locale: await _localeForVendor(),
    );
    await _startListeningForOrder(event.order, emit);
  }

  Future<String> _localeForVendor() async {
    final box = Hive.box('vendor_app_box');
    final locale = box.get('vendor_locale', defaultValue: 'en_US') as String;
    return locale;
  }

  Future<void> _startListeningForOrder(
    OrderModel order,
    Emitter emit, {
    int attempt = 1,
  }) async {
    try {
      await VoiceServiceVendor.instance.listen(
        timeout: Duration(seconds: 12),
        onResult: (recognizedText) {
          add(
            VoiceResultEvent(
              order: order,
              recognizedText: recognizedText,
              attempt: attempt,
            ),
          );
        },
        onError: () {
          emit(VendorOrderAwaitingManual(order: order));
        },
      );
    } catch (e) {
      emit(VendorOrderAwaitingManual(order: order));
    }
  }

  Future<void> _onVoiceResult(VoiceResultEvent event, Emitter emit) async {
    final r = event.recognizedText;
    final order = event.order;
    final normalized = r.toLowerCase();

    if (matchesAccept(
      normalized,
      orderNumber: order.id,
      items: order.items.map((e) => e.name).toList(),
    )) {
      add(AcceptOrderEvent(order: order));
      return;
    }

    if (rejectKeywords.any((k) => normalized.contains(k))) {
      add(RejectOrderEvent(order: order));
      return;
    }

    if (readyKeywords.any((k) => normalized.contains(k))) {
      add(ReadyOrderEvent(order: order));
      return;
    }

    if (repeatKeywords.any((k) => normalized.contains(k))) {
      await VoiceServiceVendor.instance.speak(
        _formatOrderForTTS(order),
        locale: await _localeForVendor(),
        customerVoice: true,
      );
      if (event.attempt < 2) {
        await _startListeningForOrder(order, emit, attempt: event.attempt + 1);
      } else {
        emit(VendorOrderAwaitingManual(order: order));
      }
      return;
    }

    if (moreTimeKeywords.any((k) => normalized.contains(k))) {
      try {
        await ApiClient.instance.post(
          '/orders/${order.id}/delay',
          data: {"minutes": 5},
        );
        await VoiceServiceVendor.instance.speak(
          'Added 5 minutes',
          locale: await _localeForVendor(),
        );
        emit(VendorOrderDelayed(order: order));
      } catch (e) {
        emit(VendorOrderError(order: order, message: 'Network error'));
      }
      return;
    }

    if (paidKeywords.any((k) => normalized.contains(k))) {
      try {
        await ApiClient.instance.post(
          '/orders/${order.id}/payment',
          data: {"method": "cash"},
        );
        await VoiceServiceVendor.instance.speak(
          'Payment recorded',
          locale: await _localeForVendor(),
        );
        emit(VendorOrderPaymentRecorded(order: order));
      } catch (e) {
        await _offlineQueue.enqueue({'action': 'payment', 'orderId': order.id});
        emit(VendorOrderPaymentRecorded(order: order));
      }
      return;
    }

    if (event.attempt < 2) {
      await VoiceServiceVendor.instance.speak(
        'Can you please repeat?',
        locale: await _localeForVendor(),
      );
      await _startListeningForOrder(order, emit, attempt: event.attempt + 1);
    } else {
      emit(VendorOrderAwaitingManual(order: order));
    }
  }

  Future<void> _onAcceptOrder(AcceptOrderEvent event, Emitter emit) async {
    emit(VendorOrderAccepting(order: event.order));
    try {
      await ApiClient.instance.post('/orders/${event.order.id}/accept');
      emit(VendorOrderAccepted(order: event.order));
      await VoiceServiceVendor.instance.speak(
        'Order accepted',
        locale: await _localeForVendor(),
      );
    } catch (e) {
      await _offlineQueue.enqueue({
        'action': 'accept',
        'orderId': event.order.id,
      });
      emit(
        VendorOrderError(
          order: event.order,
          message: 'Network error. Will retry',
        ),
      );
    }
  }

  Future<void> _onRejectOrder(RejectOrderEvent event, Emitter emit) async {
    emit(VendorOrderRejecting(order: event.order));
    try {
      await ApiClient.instance.post('/orders/${event.order.id}/reject');
      emit(VendorOrderRejected(order: event.order));
      await VoiceServiceVendor.instance.speak(
        'Order rejected',
        locale: await _localeForVendor(),
      );
    } catch (e) {
      await _offlineQueue.enqueue({
        'action': 'reject',
        'orderId': event.order.id,
      });
      emit(
        VendorOrderError(
          order: event.order,
          message: 'Network error. Will retry',
        ),
      );
    }
  }

  Future<void> _onReadyOrder(ReadyOrderEvent event, Emitter emit) async {
    emit(VendorOrderMarkingReady(order: event.order));
    try {
      await ApiClient.instance.post('/orders/${event.order.id}/ready');
      emit(VendorOrderReady(order: event.order));
      await VoiceServiceVendor.instance.speak(
        'Marked ready',
        locale: await _localeForVendor(),
      );
    } catch (e) {
      await _offlineQueue.enqueue({
        'action': 'ready',
        'orderId': event.order.id,
      });
      emit(
        VendorOrderError(
          order: event.order,
          message: 'Network error. Will retry',
        ),
      );
    }
  }

  Future<void> _onRetryListening(
    RetryListeningEvent event,
    Emitter emit,
  ) async {
    await _startListeningForOrder(event.order, emit, attempt: 1);
  }

  String _formatOrderForTTS(OrderModel order) {
    final items = order.items.map((i) => '${i.quantity} ${i.name}').join(', ');
    return 'Order Number ${order.id}. ${order.isParcel ? "Parcel" : "Dine in"}. Items: $items. ${'Accept? Reject? Ready?'}';
  }

  // --- Handlers for Native Events ---

  Future<void> _onNativeAccept(NativeVoiceAcceptEvent e, Emitter emit) async {
    final orderId = e.payload['orderId'] as String?;
    if (orderId != null) {
      // Create a dummy model or fetch. Ideally fetch.
      final order = OrderModel(
          id: orderId,
          isParcel: true,
          items: [],
          total: 0,
          createdAt: DateTime.now());
      add(AcceptOrderEvent(order: order));
    }
  }

  Future<void> _onNativeReject(NativeVoiceRejectEvent e, Emitter emit) async {
    final orderId = e.payload['orderId'] as String?;
    if (orderId != null) {
      final order = OrderModel(
          id: orderId,
          isParcel: true,
          items: [],
          total: 0,
          createdAt: DateTime.now());
      add(RejectOrderEvent(order: order));
    }
  }

  Future<void> _onNativeReady(NativeVoiceReadyEvent e, Emitter emit) async {
    final orderId = e.payload['orderId'] as String?;
    if (orderId != null) {
      final order = OrderModel(
          id: orderId,
          isParcel: true,
          items: [],
          total: 0,
          createdAt: DateTime.now());
      add(ReadyOrderEvent(order: order));
    }
  }

  Future<void> _onNativeRepeat(NativeVoiceRepeatEvent e, Emitter emit) async {
    final orderId = e.payload['orderId'] as String?;
    if (orderId != null) {
      // Could fetch order details and replay TTS if needed
    }
  }

  Future<void> _onNativeAwaitManual(
      NativeVoiceAwaitManualEvent e, Emitter emit) async {
    final orderId = e.payload['orderId'] as String?;
    if (orderId != null) {
      final order = OrderModel(
          id: orderId,
          isParcel: true,
          items: [],
          total: 0,
          createdAt: DateTime.now());
      emit(VendorOrderAwaitingManual(order: order));
    }
  }

  Future<void> _onNativeUnknown(NativeVoiceUnknownEvent e, Emitter emit) async {
    // Log or notify user
  }
}
