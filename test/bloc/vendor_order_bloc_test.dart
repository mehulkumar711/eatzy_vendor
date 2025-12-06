// import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// import 'package:bloc_test/bloc_test.dart';
// import 'package:eatzy_vendor/features/vendor_dashboard/presentation/bloc/vendor_order_bloc.dart';
import 'package:eatzy_vendor/services/voice_service_vendor.dart';
// import 'package:eatzy_vendor/services/native_comm.dart';
import 'package:eatzy_vendor/utils/models.dart';

// Mock classes
class MockVoiceServiceVendor extends Mock implements VoiceServiceVendor {}

void main() {
  // late MockVoiceServiceVendor mockVoice;

  setUpAll(() {
    registerFallbackValue(OrderModel(
      id: '001',
      items: [],
      isParcel: true,
      total: 0,
      createdAt: DateTime.now(),
    ));
  });

  setUp(() {
    // mockVoice = MockVoiceServiceVendor();
  });

  group('VendorOrderBloc', () {
    test('initial state is VendorOrderInitial', () {
      // TODO: Initialize bloc with mocked dependencies
      // final bloc = VendorOrderBloc();
      // expect(bloc.state, isA<VendorOrderInitial>());
    });

    test('IncomingOrderEvent plays ping and speaks order', () async {
      // TODO: Setup mocks for playPing and speak
      // when(() => mockVoice.playPing()).thenAnswer((_) async {});
      // when(() => mockVoice.speak(any(), locale: any(named: 'locale')))
      //     .thenAnswer((_) async {});
      //
      // final bloc = VendorOrderBloc();
      // bloc.add(IncomingOrderEvent(order));
      //
      // await expectLater(
      //   bloc.stream,
      //   emitsInOrder([
      //     isA<VendorOrderSpeaking>(),
      //     isA<VendorOrderListening>(),
      //   ]),
      // );
    });

    test('AcceptOrderEvent transitions to accepted state', () async {
      // TODO: Add test for accept flow
      // final order = OrderModel(...);
      // bloc.add(AcceptOrderEvent(order));
      // await expectLater(bloc.stream, emits(isA<VendorOrderAccepted>()));
    });

    test('RejectOrderEvent transitions to rejected state', () async {
      // TODO: Add test for reject flow
    });

    test('MarkReadyEvent transitions to ready state', () async {
      // TODO: Add test for ready flow
    });
  });

  group('NativeVoiceResult handling', () {
    test('ACCEPT result from native service dispatches AcceptOrderEvent',
        () async {
      // TODO: Mock NativeComm.resultStream
      // final controller = StreamController<NativeVoiceResult>();
      // when(() => NativeComm.resultStream).thenAnswer((_) => controller.stream);
      //
      // controller.add(NativeVoiceResult(
      //   type: NativeVoiceResultType.accept,
      //   orderId: '001',
      // ));
    });

    test('AWAIT_MANUAL result shows semi-voice UI', () async {
      // TODO: Test semi-voice fallback
    });

    test('ERROR result shows error notification', () async {
      // TODO: Test error handling
    });
  });

  group('Voice command parsing', () {
    test('matchesAccept returns true for accept keywords', () {
      // TODO: Test keyword matching
      // expect(matchesAccept('ok'), isTrue);
      // expect(matchesAccept('accept'), isTrue);
      // expect(matchesAccept('theek hai'), isTrue);
    });

    test('matchesReject returns true for reject keywords', () {
      // TODO: Test reject keywords
    });

    test('matchesReady returns true for ready keywords', () {
      // TODO: Test ready keywords
    });
  });
}
