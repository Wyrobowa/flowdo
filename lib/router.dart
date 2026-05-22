import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/mode_select_screen.dart';
import 'screens/session_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/timer_screen.dart';

Page<void> _slide(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, _, child) {
        final slide = Tween(begin: const Offset(0.04, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final fade = CurveTween(curve: Curves.easeOut);
        return SlideTransition(
          position: animation.drive(slide),
          child: FadeTransition(opacity: animation.drive(fade), child: child),
        );
      },
    );

final router = GoRouter(
  routes: [
    GoRoute(path: '/', pageBuilder: (_, s) => _slide(s, const ModeSelectScreen())),
    GoRoute(path: '/settings', pageBuilder: (_, s) => _slide(s, const SettingsScreen())),
    GoRoute(path: '/timer', pageBuilder: (_, s) => _slide(s, const TimerScreen())),
    GoRoute(path: '/tasks', pageBuilder: (_, s) => _slide(s, const HomeScreen())),
    GoRoute(path: '/session', pageBuilder: (_, s) => _slide(s, const SessionScreen())),
  ],
);
