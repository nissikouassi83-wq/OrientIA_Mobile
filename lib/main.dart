import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';
import 'features/welcome/pages/welcome_page.dart';
import 'features/dashboard/pages/dashboard_page.dart';
import 'features/coach/pages/coach_page.dart';
import 'features/careers/pages/careers_page.dart';
import 'features/onboarding/pages/onboarding_page.dart';
import 'features/gap_analysis/pages/gap_analysis_page.dart';
import 'features/roadmap/pages/roadmap_page.dart';
import 'features/reconversion/pages/reconversion_page.dart';
import 'features/psychometric/pages/psychometric_page.dart';
import 'features/cv_analysis/pages/cv_analysis_page.dart';
import 'features/profile/pages/profile_page.dart';

final authNotifier = ValueNotifier<bool>(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  themeNotifier.value = true; // toujours dark
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  authNotifier.value = token != null && token.isNotEmpty;
  runApp(const OrientIAApp());
}

// ── Transitions ───────────────────────────────────────────────────────────────

Page<dynamic> _slidePage(Widget child, GoRouterState state) =>
    CustomTransitionPage(
      key: state.pageKey, child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );

Page<dynamic> _fadePage(Widget child, GoRouterState state) =>
    CustomTransitionPage(
      key: state.pageKey, child: child,
      transitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
        child: child,
      ),
    );

// ── Router ────────────────────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: authNotifier.value ? '/dashboard' : '/welcome',
  refreshListenable: authNotifier,
  redirect: (context, state) {
    final loggedIn = authNotifier.value;
    final loc = state.matchedLocation;
    final onPublic = loc == '/welcome' || loc == '/login' || loc == '/register';
    if (loggedIn && onPublic) return '/dashboard';
    if (!loggedIn && !onPublic) return '/welcome';
    return null;
  },
  routes: [
    GoRoute(path: '/welcome',  pageBuilder: (_, s) => _fadePage(const WelcomePage(),  s)),
    GoRoute(path: '/login',    pageBuilder: (_, s) => _fadePage(const LoginPage(),    s)),
    GoRoute(path: '/register', pageBuilder: (_, s) => _fadePage(const RegisterPage(), s)),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
        GoRoute(path: '/explorer',  builder: (_, __) => const CareersPage()),
        GoRoute(path: '/coach',     builder: (_, __) => const CoachPage()),
        GoRoute(path: '/cv',        builder: (_, __) => const ProfilePage()),
      ],
    ),
    GoRoute(path: '/onboarding',   pageBuilder: (_, s) => _slidePage(const OnboardingPage(),  s)),
    GoRoute(path: '/gap-analysis', pageBuilder: (_, s) => _slidePage(const GapAnalysisPage(), s)),
    GoRoute(path: '/roadmap',      pageBuilder: (_, s) => _slidePage(const RoadmapPage(),     s)),
    GoRoute(path: '/reconversion', pageBuilder: (_, s) => _slidePage(const ReconversionPage(),s)),
    GoRoute(path: '/psychometric', pageBuilder: (_, s) => _slidePage(const PsychometricPage(),s)),
    GoRoute(path: '/cv-analysis',  pageBuilder: (_, s) => _slidePage(const CvAnalysisPage(),  s)),
  ],
);

// ── App ───────────────────────────────────────────────────────────────────────

class OrientIAApp extends StatelessWidget {
  const OrientIAApp({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(ApiClient())..add(AuthCheckRequested()),
      child: MaterialApp.router(
        title: 'OrientIA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: _router,
      ),
    );
  }
}

// ── App Shell — 5 tabs ────────────────────────────────────────────────────────

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  static const _routes = ['/dashboard', '/explorer', '/gap-analysis', '/coach', '/cv'];
  static const _icons  = [
    Icons.home_outlined,
    Icons.search,
    Icons.analytics_outlined,
    Icons.support_agent,
    Icons.badge_outlined,
  ];
  static const _activeIcons = [
    Icons.home_rounded,
    Icons.search,
    Icons.analytics,
    Icons.support_agent,
    Icons.badge,
  ];
  static const _labels = ['Accueil', 'Explorer', 'Dashboard', 'Coach IA', 'Profil'];

  int _idx(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _routes.length; i++) {
      if (loc.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _idx(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: const Border(top: BorderSide(color: AppColors.line)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_routes.length, (i) {
                final active = i == idx;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (i == 2) {
                        // Dashboard tab → gap-analysis (push, not shell)
                        context.push('/gap-analysis');
                      } else {
                        context.go(_routes[i]);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: active ? 12 : 0,
                            vertical:   active ?  4  : 0,
                          ),
                          decoration: BoxDecoration(
                            color: active ? AppColors.accent.withValues(alpha: 0.15) : null,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            active ? _activeIcons[i] : _icons[i],
                            color: active ? AppColors.accent : AppColors.muted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_labels[i], style: TextStyle(
                          color: active ? AppColors.accent : AppColors.muted,
                          fontSize: 9,
                          fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                        )),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
