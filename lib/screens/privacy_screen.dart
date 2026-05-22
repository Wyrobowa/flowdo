import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        title: const Text('Privacy policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          _Section(
            title: 'Data storage',
            body:
                'All data stays on your device. Nothing is sent to any server or third party.',
          ),
          _Section(
            title: 'Notifications',
            body:
                'Notifications are used only to alert you when timers end. No notification data is collected or shared.',
          ),
          _Section(
            title: 'Analytics',
            body: 'None — no tracking, no analytics, no crash reporting.',
          ),
          _Section(
            title: 'Contact',
            body: 'Questions or concerns? Reach out at support@flowdo.app',
            bodyColor: cs.primary,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.body,
    this.bodyColor,
  });

  final String title;
  final String body;
  final Color? bodyColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 15,
              color: bodyColor ?? cs.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
