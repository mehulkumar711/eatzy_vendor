// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appTitle => 'ઇટઝી વેન્ડર';

  @override
  String get onboardingChooseLanguage => 'ભાષા પસંદ કરો';

  @override
  String get onboardingMicTest => 'માઇક ટેસ્ટ — Hello કહો';

  @override
  String get storeSetupTitle => 'ડોકાન સેટઅપ';

  @override
  String get storeSetupStoreName => 'સ્ટોરનું નામ';

  @override
  String get storeSetupOwnerName => 'માલિકનું નામ';

  @override
  String get storeSetupUpiId => 'UPI ID (ઐચ્છિક)';

  @override
  String get storeSetupDescription => 'સારી ટૂંકી વર્ણના';

  @override
  String get storeSetupCreate => 'સ્ટોર બનાવો';

  @override
  String ordersNewOrder(Object orderId) {
    return 'નવો ઓર્ડર • #$orderId';
  }

  @override
  String get ordersParcel => 'પાર્સલ';

  @override
  String get ordersDineIn => 'ડાઇન-ઇન';

  @override
  String get ordersAccept => 'સ્વીકૃત કરો';

  @override
  String get ordersReject => 'રદ કરો';

  @override
  String get ordersReady => 'તૈયાર';

  @override
  String get ordersRepeat => 'ફરી';

  @override
  String get payoutsTitle => 'પેઆઉટ્સ';

  @override
  String get payoutsTotalEarnings => 'કુલ કમાણી';

  @override
  String get payoutsCommission => 'કમિશન';

  @override
  String get payoutsEstimatedPayout => 'અંદાજિત પેઆઉટ';

  @override
  String get payoutsRequestPayout => 'પેઆઉટ વિનંતી કરો';

  @override
  String get voicePromptAcceptRejectReady => 'સ્વીકારીશું? રદ? તૈયાર?';
}
