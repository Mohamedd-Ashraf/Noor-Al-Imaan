import 'package:flutter/material.dart';

import '../di/injection_container.dart' as di;
import '../services/settings_service.dart';
import '../../features/islamic/presentation/screens/onboarding_screen.dart';
import '../../features/islamic/presentation/screens/splash_page.dart';
import '../../features/quran/presentation/screens/main_navigator.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late final SettingsService _settings;
  bool? _isComplete;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _settings = di.sl<SettingsService>();
    _isComplete = _settings.getOnboardingComplete();
  }

  void _markComplete() async {
    await _settings.setOnboardingComplete(true);
    if (!mounted) return;
    setState(() {
      _isComplete = true;
    });
  }

  void _finishSplash() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashPage(onFinish: _finishSplash);
    }

    final isComplete = _isComplete;
    if (isComplete == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isComplete) {
      return OnboardingScreen(
        onContinue: _markComplete,
      );
    }

    return const MainNavigator();
  }
}
