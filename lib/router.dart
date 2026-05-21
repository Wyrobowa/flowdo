import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/session_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/session', builder: (_, _) => const SessionScreen()),
  ],
);
