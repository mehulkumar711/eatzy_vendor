part of 'vendor_order_bloc.dart';

abstract class VendorOrderState {}

class VendorOrderInitial extends VendorOrderState {}

class VendorOrderIncoming extends VendorOrderState {
  final OrderModel order;
  VendorOrderIncoming({required this.order});
}

class VendorOrderAwaitingManual extends VendorOrderState {
  final OrderModel order;
  VendorOrderAwaitingManual({required this.order});
}

class VendorOrderAccepting extends VendorOrderState {
  final OrderModel order;
  VendorOrderAccepting({required this.order});
}

class VendorOrderAccepted extends VendorOrderState {
  final OrderModel order;
  VendorOrderAccepted({required this.order});
}

class VendorOrderRejecting extends VendorOrderState {
  final OrderModel order;
  VendorOrderRejecting({required this.order});
}

class VendorOrderRejected extends VendorOrderState {
  final OrderModel order;
  VendorOrderRejected({required this.order});
}

class VendorOrderMarkingReady extends VendorOrderState {
  final OrderModel order;
  VendorOrderMarkingReady({required this.order});
}

class VendorOrderReady extends VendorOrderState {
  final OrderModel order;
  VendorOrderReady({required this.order});
}

class VendorOrderDelayed extends VendorOrderState {
  final OrderModel order;
  VendorOrderDelayed({required this.order});
}

class VendorOrderPaymentRecorded extends VendorOrderState {
  final OrderModel order;
  VendorOrderPaymentRecorded({required this.order});
}

class VendorOrderError extends VendorOrderState {
  final OrderModel order;
  final String message;
  VendorOrderError({required this.order, required this.message});
}
