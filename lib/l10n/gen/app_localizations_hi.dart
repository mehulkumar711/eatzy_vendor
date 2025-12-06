// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'इट्ज़ी विक्रेता';

  @override
  String get onboardingChooseLanguage => 'भाषा चुनें';

  @override
  String get onboardingMicTest => 'माइक परीक्षण — Hello बोलें';

  @override
  String get storeSetupTitle => 'दुकान सेटअप';

  @override
  String get storeSetupStoreName => 'दुकान का नाम';

  @override
  String get storeSetupOwnerName => 'मालिक का नाम';

  @override
  String get storeSetupUpiId => 'UPI ID (वैकल्पिक)';

  @override
  String get storeSetupDescription => 'संक्षिप्त विवरण';

  @override
  String get storeSetupCreate => 'दुकान बनाएं';

  @override
  String ordersNewOrder(Object orderId) {
    return 'नया ऑर्डर • #$orderId';
  }

  @override
  String get ordersParcel => 'पार्सल';

  @override
  String get ordersDineIn => 'डाइन-इन';

  @override
  String get ordersAccept => 'स्वीकार करें';

  @override
  String get ordersReject => 'रद्द करें';

  @override
  String get ordersReady => 'तैयार';

  @override
  String get ordersRepeat => 'दोहराएं';

  @override
  String get payoutsTitle => 'भुगतान';

  @override
  String get payoutsTotalEarnings => 'कुल कमाई';

  @override
  String get payoutsCommission => 'कमीशन';

  @override
  String get payoutsEstimatedPayout => 'अनुमानित भुगतान';

  @override
  String get payoutsRequestPayout => 'भुगतान का अनुरोध';

  @override
  String get voicePromptAcceptRejectReady => 'स्वीकार? रद्द? तैयार?';
}
