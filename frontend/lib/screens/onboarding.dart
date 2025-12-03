// screens/onboarding.dart
import 'package:flutter/material.dart';
import 'package:docuverse/widgets/app_logo.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(
              size: 120,
              showText: true,
              textSize: 32,
            ),
            const SizedBox(height: 24),
            const Text(
              'Your AI Document Assistant',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 100),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Continue'),
            ),
            const SizedBox(height: 100),
            const Text('Made with 💤'),
          ],
        ),
      ),
    );
  }
}