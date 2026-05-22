import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../extensions.dart';
import '../providers/defaults_provider.dart';
import '../providers/features_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/sounds_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/duration_picker.dart';
import '../services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(featuresProvider);
    final themeMode = ref.watch(themeModeProvider);
    final defaultFocus = ref.watch(defaultFocusProvider);
    final defaultBreak = ref.watch(defaultBreakProvider);
    final countdownSeconds = ref.watch(countdownSecondsProvider);
    final notifEnabled = ref.watch(notificationsEnabledProvider);
    final soundsEnabled = ref.watch(soundsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _SectionLabel('Modes'),
          _Card(
            child: Column(
              children: [
                _ToggleRow(
                  label: 'Quick timer',
                  description: 'Simple countdown with no task list.',
                  value: features.timer,
                  enabled: !(features.timer && features.enabledCount == 1),
                  onChanged: (v) =>
                      ref.read(featuresProvider.notifier).setTimer(v),
                ),
                _Divider(),
                _ToggleRow(
                  label: 'Tasks & breaks',
                  description: 'Focus blocks linked to a task list.',
                  value: features.tasks,
                  enabled: !(features.tasks && features.enabledCount == 1),
                  onChanged: (v) =>
                      ref.read(featuresProvider.notifier).setTasks(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel('Appearance'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RowLabel('Theme'),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('System'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) =>
                      ref.read(themeModeProvider.notifier).set(s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel('Session defaults'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RowLabel('Focus time'),
                const SizedBox(height: 12),
                DurationPicker(
                  initial: Duration(seconds: defaultFocus),
                  onChanged: (d) => ref
                      .read(defaultFocusProvider.notifier)
                      .set(d.inSeconds.clamp(1, 86399)),
                ),
                const SizedBox(height: 20),
                _RowLabel('Break after'),
                const SizedBox(height: 12),
                DurationPicker(
                  initial: Duration(seconds: defaultBreak),
                  onChanged: (d) => ref
                      .read(defaultBreakProvider.notifier)
                      .set(d.inSeconds.clamp(0, 86399)),
                ),
                const SizedBox(height: 20),
                _RowLabel('Countdown warning'),
                const SizedBox(height: 12),
                Row(
                  children: [3, 5, 7, 10].map((secs) {
                    final selected = countdownSeconds == secs;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${secs}s'),
                        selected: selected,
                        onSelected: (_) => ref
                            .read(countdownSecondsProvider.notifier)
                            .set(secs.clamp(3, 10)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel('Sound & notifications'),
          _Card(
            child: Column(
              children: [
                _ToggleRow(
                  label: 'Sounds',
                  description: 'Play a chime when focus or break ends.',
                  value: soundsEnabled,
                  onChanged: (val) =>
                      ref.read(soundsEnabledProvider.notifier).set(val),
                ),
                _Divider(),
                _ToggleRow(
              label: 'Enable notifications',
              description: 'Get alerted when focus or break time ends.',
              value: notifEnabled,
              onChanged: (val) async {
                if (val) {
                  final granted = await NotificationService.requestPermission();
                  if (!granted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notifications are blocked — enable them in System Settings.',
                        ),
                      ),
                    );
                  }
                }
                ref.read(notificationsEnabledProvider.notifier).set(val);
              },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel('About'),
          _Card(
            child: Column(
              children: [
                _InfoRow(label: 'App', value: 'Flowdo'),
                _Divider(),
                _InfoRow(label: 'Version', value: '1.0.0'),
                _Divider(),
                _InfoRow(label: 'Built with', value: 'Flutter'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared layout widgets ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      );
}

class _RowLabel extends StatelessWidget {
  const _RowLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
        height: 20,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.5),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: enabled
              ? (v) {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                }
              : null,
        ),
      ],
    );
  }
}

