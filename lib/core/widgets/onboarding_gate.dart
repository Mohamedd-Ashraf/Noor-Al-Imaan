import 'package:flutter/material.dart';

import '../di/injection_container.dart' as di;
import '../services/settings_service.dart';
import '../services/whats_new_service.dart';
import '../widgets/whats_new_screen.dart';
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
  late final WhatsNewService _whatsNewService;

  bool _showSplash = true;
  bool? _onboardingComplete;
  // null = not yet checked, true = show, false = skip
  bool? _showWhatsNew;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _settings = di.sl<SettingsService>();
    _whatsNewService = di.sl<WhatsNewService>();
    _onboardingComplete = _settings.getOnboardingComplete();
  }

  // Called when the splash animation completes.
  void _finishSplash() {
    if (!mounted) return;
    setState(() {
      _showSplash = false;
    });
    // If onboarding is already done, start the What's New check right away.
    if (_onboardingComplete == true) {
      _checkWhatsNew();
    }
  }

  // Called when the user taps "Get Started" on the onboarding screen.
  Future<void> _markOnboardingComplete() async {
    await _settings.setOnboardingComplete(true);
    if (!mounted) return;
    setState(() {
      _onboardingComplete = true;
    });
    _checkWhatsNew();
  }

  // Async check – runs after onboarding is confirmed complete.
  Future<void> _checkWhatsNew() async {
    final shouldShow = await _whatsNewService.shouldShow();
    final version = await _whatsNewService.currentVersion();
    if (!mounted) return;
    setState(() {
      _showWhatsNew = shouldShow;
      _appVersion = version;
    });
  }

  // Called when the user dismisses the What's New screen.
  void _dismissWhatsNew() {
    if (!mounted) return;
    setState(() {
      _showWhatsNew = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── 1. Splash ──────────────────────────────────────────────────────────
    if (_showSplash) {
      return SplashPage(onFinish: _finishSplash);
    }

    // ── 2. Onboarding ──────────────────────────────────────────────────────
    if (_onboardingComplete != true) {
      return OnboardingScreen(onContinue: _markOnboardingComplete);
    }

    // ── 3. What's New check loading ────────────────────────────────────────
    if (_showWhatsNew == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ── 4. What's New screen ───────────────────────────────────────────────
    if (_showWhatsNew == true) {
      return WhatsNewScreen(
        whatsNewService: _whatsNewService,
        onDismiss: _dismissWhatsNew,
        version: _appVersion,
      );
    }

    // ── 5. Main app ────────────────────────────────────────────────────────
    return const MainNavigator();
  }
}
