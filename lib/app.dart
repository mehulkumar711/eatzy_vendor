import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme.dart';
import 'package:eatzy_vendor/l10n/gen/app_localizations.dart';
import 'features/onboarding/pages/onboarding_pages.dart';

class EatzyVendorApp extends StatelessWidget {
  const EatzyVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eatzy Vendor',
      theme: EatzyTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('gu')],
      home: OnboardingRoot(), // implements language select & first-time flows
    );
  }
}
