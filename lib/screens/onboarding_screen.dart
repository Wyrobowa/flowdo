import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/notifications_provider.dart';
import '../services/notification_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(
      icon: Icons.timer_outlined,
      title: 'Focus without distraction',
      subtitle: 'Set your timer and get into flow. No interruptions, just work.',
    ),
    _PageData(
      icon: Icons.checklist_rounded,
      title: 'Tasks & timed breaks',
      subtitle:
          'Build a task list with custom focus blocks and automatic breaks.',
    ),
    _PageData(
      icon: Icons.play_circle_outline_rounded,
      title: 'Ready to flow?',
      subtitle:
          'Your sessions stay on your device. Nothing is tracked or shared.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    final firstLaunch = prefs.getBool('notification_prompted') != true;
    if (firstLaunch && mounted) {
      await prefs.setBool('notification_prompted', true);
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
    if (!mounted) return;
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/');
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          data.icon,
                          size: 80,
                          color: cs.primary,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: cs.onSurface.withValues(alpha: 0.55),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 16, 40, 48),
              child: isLast
                  ? FilledButton(
                      onPressed: _finish,
                      child: const Text('Get started'),
                    )
                  : GestureDetector(
                      onTap: _next,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _page ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? cs.primary
                                  : cs.onSurface.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  const _PageData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
