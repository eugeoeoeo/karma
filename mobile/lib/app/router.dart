import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/voice_log/presentation/voice_log_screen.dart';
import '../features/virtues/presentation/virtues_screen.dart';
import '../features/intentions/presentation/intentions_screen.dart';
import '../features/blessings/presentation/blessings_screen.dart';
import '../features/reflections/presentation/reflections_screen.dart';
import '../features/story/presentation/story_screen.dart';
import '../features/mentor/presentation/mentor_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/wishes/presentation/wishes_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final status = auth.state.status;
      if (status == AuthStatus.initial) {
        return '/';
      }
      final isAuth = status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && (isAuthRoute || state.matchedLocation == '/')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/voice-log',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const VoiceLogScreen(),
      ),
      GoRoute(
        path: '/mentor',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const MentorScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/virtues', builder: (_, __) => const VirtuesScreen()),
          GoRoute(path: '/intentions', builder: (_, __) => const IntentionsScreen()),
          GoRoute(path: '/blessings', builder: (_, __) => const BlessingsScreen()),
          GoRoute(path: '/reflections', builder: (_, __) => const ReflectionsScreen()),
          GoRoute(path: '/story', builder: (_, __) => const StoryScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/wishes', builder: (_, __) => const WishesScreen()),
        ],
      ),
    ],
  );
});
