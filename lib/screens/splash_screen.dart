import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/notifications_provider.dart';
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
    final firstLaunch = prefs.getBool('notification_prompted') != true;

    if (firstLaunch && mounted) {
      await prefs.setBool('notification_prompted', true);
      _spin.stop();

      if (!mounted) return;
      final allow = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Stay on track'),
          content: const Text(
            'Get notified when your focus or break time ends.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Allow'),
            ),
          ],
        ),
      );

      if (allow == true && mounted) {
        final granted = await NotificationService.requestPermission();
        ref.read(notificationsEnabledProvider.notifier).set(granted);
      }
    }

    if (mounted) context.go('/');
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
