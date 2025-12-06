part of 'vendor_order_bloc.dart';

// Ensure OrderModel is available via the part-of relationship or parent imports,
// but typically part files depend on parent.
// Since 'vendor_order_bloc.dart' imports 'models.dart', and this is partial, it should see OrderModel.
// However, if IDE complains, verify parent imports.

abstract class VendorOrderEvent {}

class IncomingOrderEvent extends VendorOrderEvent {
  final OrderModel order;
  IncomingOrderEvent({required this.order});
}

class VoiceResultEvent extends VendorOrderEvent {
  final OrderModel order;
  final String recognizedText;
  final int attempt;
  VoiceResultEvent({
    required this.order,
    required this.recognizedText,
    this.attempt = 1,
  });
}

class AcceptOrderEvent extends VendorOrderEvent {
  final OrderModel order;
  AcceptOrderEvent({required this.order});
}

class RejectOrderEvent extends VendorOrderEvent {
  final OrderModel order;
  RejectOrderEvent({required this.order});
}

class ReadyOrderEvent extends VendorOrderEvent {
  final OrderModel order;
  ReadyOrderEvent({required this.order});
}

class RetryListeningEvent extends VendorOrderEvent {
  final OrderModel order;
  RetryListeningEvent({required this.order});
}

// Native Voice Events
class NativeVoiceAcceptEvent extends VendorOrderEvent {
  final Map<String, dynamic> payload;
  NativeVoiceAcceptEvent(this.payload);
}

class NativeVoiceRejectEvent extends VendorOrderEvent {
  final Map<String, dynamic> payload;
  NativeVoiceRejectEvent(this.payload);
}

class NativeVoiceReadyEvent extends VendorOrderEvent {
  final Map<String, dynamic> payload;
  NativeVoiceReadyEvent(this.payload);
}

class NativeVoiceRepeatEvent extends VendorOrderEvent {
  final Map<String, dynamic> payload;
  NativeVoiceRepeatEvent(this.payload);
}

class NativeVoiceAwaitManualEvent extends VendorOrderEvent {
  final Map<String, dynamic> payload;
  NativeVoiceAwaitManualEvent(this.payload);
}

class NativeVoiceUnknownEvent extends VendorOrderEvent {
  final Map<String, dynamic> payload;
  NativeVoiceUnknownEvent(this.payload);
}
