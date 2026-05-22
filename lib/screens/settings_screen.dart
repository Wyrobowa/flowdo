import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../extensions.dart';
import '../providers/defaults_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final defaultFocus = ref.watch(defaultFocusProvider);
    final defaultBreak = ref.watch(defaultBreakProvider);

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
                _ChipRow(
                  options: const [5, 10, 15, 20, 25, 30, 45, 60, 90],
                  selected: defaultFocus,
                  label: (v) => '${v}m',
                  activeColor: Theme.of(context).colorScheme.primary,
                  onSelected: (v) =>
                      ref.read(defaultFocusProvider.notifier).set(v),
                ),
                const SizedBox(height: 20),
                _RowLabel('Break after'),
                const SizedBox(height: 12),
                _ChipRow(
                  options: const [0, 5, 10, 15, 20],
                  selected: defaultBreak,
                  label: (v) => v == 0 ? 'None' : '${v}m',
                  activeColor: Theme.of(context).colorScheme.secondary,
                  onSelected: (v) =>
                      ref.read(defaultBreakProvider.notifier).set(v),
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

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.options,
    required this.selected,
    required this.label,
    required this.activeColor,
    required this.onSelected,
  });

  final List<int> options;
  final int selected;
  final String Function(int) label;
  final Color activeColor;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((v) {
        final sel = v == selected;
        return GestureDetector(
          onTap: () => onSelected(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? activeColor : context.chipSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label(v),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : cs.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
