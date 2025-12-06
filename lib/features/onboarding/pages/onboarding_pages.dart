import 'package:flutter/material.dart';
import 'package:eatzy_vendor/core/localization.dart';

class OnboardingRoot extends StatelessWidget {
  const OnboardingRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.l10n.onboardingChooseLanguage),
            // Language selection and other onboarding flows would go here
            ElevatedButton(
              onPressed: () {
                // Navigate to next step or dashboard
              },
              child: Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
