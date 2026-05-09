import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/pretest_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/disaster/screens/disaster_list_screen.dart';
import '../../features/disaster/screens/disaster_detail_screen.dart';
import '../../features/disaster/screens/disaster_phase_screen.dart';
import '../../features/disaster/screens/video_player_screen.dart';
import '../../features/quiz/screens/quiz_screen.dart';
import '../../features/quiz/screens/quiz_result_screen.dart';
import '../../data/models/quiz_model.dart';
import '../../features/profile/screens/name_input_screen.dart';
import '../../features/news/screens/news_list_screen.dart';
import '../../features/news/screens/news_detail_screen.dart';
import '../../data/models/news_model.dart';
import '../../features/scanner/screens/scanner_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder: (c, s) => _slide(const SplashScreen(), s),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (c, s) => _slide(const OnboardingScreen(), s),
      ),
      GoRoute(
        path: '/name-input',
        name: 'nameInput',
        pageBuilder: (c, s) => _slide(const NameInputScreen(), s),
      ),
      GoRoute(
        path: '/diagnostik',
        name: 'diagnostik',
        pageBuilder: (c, s) => _slide(const PretestScreen(), s),
      ),
      GoRoute(
        path: '/news',
        name: 'newsList',
        pageBuilder: (c, s) => _slide(const NewsListScreen(), s),
      ),
      GoRoute(
        path: '/news/:id',
        name: 'newsDetail',
        pageBuilder: (c, s) {
          final news = s.extra as NewsModel;
          return _slide(NewsDetailScreen(news: news), s);
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (c, s) => _slide(const HomeScreen(), s),
      ),
      GoRoute(
        path: '/scanner',
        name: 'scanner',
        pageBuilder: (c, s) => _slide(const ScannerScreen(), s),
      ),
      GoRoute(
        path: '/disasters',
        name: 'disasterList',
        pageBuilder: (c, s) => _slide(const DisasterListScreen(), s),
      ),
      GoRoute(
        path: '/disasters/:id',
        name: 'disasterDetail',
        pageBuilder: (c, s) {
          final id = s.pathParameters['id']!;
          final extra = s.extra as Map<String, dynamic>?;
          return _slide(
              DisasterDetailScreen(disasterId: id, disasterData: extra), s);
        },
      ),
      GoRoute(
        path: '/disasters/:id/phase/:phase',
        name: 'disasterPhase',
        pageBuilder: (c, s) {
          final id = s.pathParameters['id']!;
          final phase = s.pathParameters['phase']!;
          final extra = s.extra as Map<String, dynamic>?;
          return _slide(
              DisasterPhaseScreen(
                  disasterId: id, phase: phase, extraData: extra),
              s);
        },
      ),
      GoRoute(
        path: '/video',
        name: 'videoPlayer',
        pageBuilder: (c, s) {
          final data = s.extra as Map<String, dynamic>;
          return _slide(VideoPlayerScreen(videoData: data), s);
        },
      ),
      GoRoute(
        path: '/quiz-result',
        name: 'quizResult',
        pageBuilder: (c, s) {
          final result = s.extra as QuizResult;
          return _slide(QuizResultScreen(result: result), s);
        },
      ),
      GoRoute(
        path: '/quiz',
        name: 'quiz',
        pageBuilder: (c, s) {
          final extra = s.extra as Map<String, dynamic>?;
          return _slide(
              QuizScreen(extraData: extra), s);
        },
      ),
    ],
  );

  static CustomTransitionPage _slide(Widget child, GoRouterState state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondary, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 320),
    );
  }
}
