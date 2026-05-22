import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      NotificationService.init(),
      SoundService.init(),
    ]);
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') == true;

    if (mounted) {
      context.go(onboardingDone ? '/' : '/onboarding');
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _spin,
          builder: (_, child) => Transform.rotate(
            angle: -_spin.value * 2 * pi,
            child: child,
          ),
          child: Image.asset(
            'assets/app_icon.png',
            width: 120,
            height: 120,
          ),
        ),
      ),
    );
  }
}
