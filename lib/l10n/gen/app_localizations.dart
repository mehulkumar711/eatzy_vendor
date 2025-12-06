import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
    Locale('hi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Eatzy Vendor'**
  String get appTitle;

  /// No description provided for @onboardingChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get onboardingChooseLanguage;

  /// No description provided for @onboardingMicTest.
  ///
  /// In en, this message translates to:
  /// **'Mic test — say Hello'**
  String get onboardingMicTest;

  /// No description provided for @storeSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Store Setup'**
  String get storeSetupTitle;

  /// No description provided for @storeSetupStoreName.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get storeSetupStoreName;

  /// No description provided for @storeSetupOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Owner name'**
  String get storeSetupOwnerName;

  /// No description provided for @storeSetupUpiId.
  ///
  /// In en, this message translates to:
  /// **'UPI ID (optional)'**
  String get storeSetupUpiId;

  /// No description provided for @storeSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'Short description'**
  String get storeSetupDescription;

  /// No description provided for @storeSetupCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Store'**
  String get storeSetupCreate;

  /// No description provided for @ordersNewOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order • #{orderId}'**
  String ordersNewOrder(Object orderId);

  /// No description provided for @ordersParcel.
  ///
  /// In en, this message translates to:
  /// **'Parcel'**
  String get ordersParcel;

  /// No description provided for @ordersDineIn.
  ///
  /// In en, this message translates to:
  /// **'Dine-in'**
  String get ordersDineIn;

  /// No description provided for @ordersAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get ordersAccept;

  /// No description provided for @ordersReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get ordersReject;

  /// No description provided for @ordersReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ordersReady;

  /// No description provided for @ordersRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get ordersRepeat;

  /// No description provided for @payoutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get payoutsTitle;

  /// No description provided for @payoutsTotalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get payoutsTotalEarnings;

  /// No description provided for @payoutsCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get payoutsCommission;

  /// No description provided for @payoutsEstimatedPayout.
  ///
  /// In en, this message translates to:
  /// **'Estimated Payout'**
  String get payoutsEstimatedPayout;

  /// No description provided for @payoutsRequestPayout.
  ///
  /// In en, this message translates to:
  /// **'Request Payout'**
  String get payoutsRequestPayout;

  /// No description provided for @voicePromptAcceptRejectReady.
  ///
  /// In en, this message translates to:
  /// **'Accept? Reject? Ready?'**
  String get voicePromptAcceptRejectReady;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
