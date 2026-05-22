import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
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
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _spin,
          builder: (_, child) => Transform.rotate(
            // Counterclockwise — negate the 0→1 progress
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
