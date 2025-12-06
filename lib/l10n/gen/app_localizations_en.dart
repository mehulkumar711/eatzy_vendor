// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Eatzy Vendor';

  @override
  String get onboardingChooseLanguage => 'Choose language';

  @override
  String get onboardingMicTest => 'Mic test — say Hello';

  @override
  String get storeSetupTitle => 'Store Setup';

  @override
  String get storeSetupStoreName => 'Store name';

  @override
  String get storeSetupOwnerName => 'Owner name';

  @override
  String get storeSetupUpiId => 'UPI ID (optional)';

  @override
  String get storeSetupDescription => 'Short description';

  @override
  String get storeSetupCreate => 'Create Store';

  @override
  String ordersNewOrder(Object orderId) {
    return 'New Order • #$orderId';
  }

  @override
  String get ordersParcel => 'Parcel';

  @override
  String get ordersDineIn => 'Dine-in';

  @override
  String get ordersAccept => 'Accept';

  @override
  String get ordersReject => 'Reject';

  @override
  String get ordersReady => 'Ready';

  @override
  String get ordersRepeat => 'Repeat';

  @override
  String get payoutsTitle => 'Payouts';

  @override
  String get payoutsTotalEarnings => 'Total Earnings';

  @override
  String get payoutsCommission => 'Commission';

  @override
  String get payoutsEstimatedPayout => 'Estimated Payout';

  @override
  String get payoutsRequestPayout => 'Request Payout';

  @override
  String get voicePromptAcceptRejectReady => 'Accept? Reject? Ready?';
}
