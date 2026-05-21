import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/mode_select_screen.dart';
import 'screens/session_screen.dart';
import 'screens/timer_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const ModeSelectScreen()),
    GoRoute(path: '/timer', builder: (_, _) => const TimerScreen()),
    GoRoute(
      path: '/tasks',
      builder: (_, _) => const HomeScreen(mode: HomeMode.tasks),
    ),
    GoRoute(
      path: '/groups',
      builder: (_, _) => const HomeScreen(mode: HomeMode.groups),
    ),
    GoRoute(path: '/session', builder: (_, _) => const SessionScreen()),
  ],
);
