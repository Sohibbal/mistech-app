import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/disaster_provider.dart';
import '../../../providers/quiz_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class DailyMissionCard extends StatefulWidget {
  const DailyMissionCard({super.key});

  @override
  State<DailyMissionCard> createState() => _DailyMissionCardState();
}

class _DailyMissionCardState extends State<DailyMissionCard> {
  Future<void>? _calcFuture;
  
  double _progress = 0.0;
  String _currentMissionText = 'Misi Harian\nMemuat...';
  String _targetRoute = '/disasters';
  Object? _targetExtra;
  String? _targetUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dProv = context.watch<DisasterProvider>();
    final qProv = context.watch<QuizProvider>();
    _calcFuture = _calculateProgress(dProv, qProv);
  }

  Future<void> _calculateProgress(DisasterProvider dProv, QuizProvider qProv) async {
    if (dProv.disasters.isEmpty) {
      _progress = 0.0;
      _currentMissionText = 'Belum ada data bencana';
      return;
    }

    int totalSteps = 4 + (dProv.disasters.length * 3); // News + LKPD + Emodul + Quiz + (disasters * 3 phases)
    int completedSteps = 0;
    if (qProv.isNewsOpened) completedSteps++;
    if (qProv.isLkpdOpened) completedSteps++;
    if (qProv.isEmodulOpened) completedSteps++;
    if (qProv.hasCompleted) completedSteps++; // Quiz

    for (final d in dProv.disasters) {
      final phases = qProv.missionPhases[d.id] ?? {};
      if (phases['pra'] == true) completedSteps++;
      if (phases['saat'] == true) completedSteps++;
      if (phases['pasca'] == true) completedSteps++;
    }

    String? nextMission;
    String nextRoute = '/disasters';
    Object? nextExtra;
    String? nextUrl;

    if (!qProv.isLkpdOpened) {
      nextMission = 'Buka LKPD\nHari Ini!';
      nextUrl = qProv.lkpdUrl;
    } else {
      bool allDisastersCompleted = true;
      for (final d in dProv.disasters) {
        final phases = qProv.missionPhases[d.id] ?? {};
        bool praDone = phases['pra'] == true;
        bool saatDone = phases['saat'] == true;
        bool pascaDone = phases['pasca'] == true;

        if (allDisastersCompleted && (!praDone || !saatDone || !pascaDone)) {
          allDisastersCompleted = false;
          nextMission = 'Lanjutkan Belajar\n${d.name}!';
          nextRoute = '/disasters/${d.id}';
          nextExtra = d.toJson();
        }
      }

      if (allDisastersCompleted && !qProv.hasCompleted) {
        nextMission = 'Kerjakan Quiz\nEvaluasi!';
        nextRoute = '/quiz';
        nextExtra = {'quizId': qProv.currentQuiz?.id};
      }
    }

    if (nextMission != null) {
      _currentMissionText = nextMission;
      _targetRoute = nextRoute;
      _targetExtra = nextExtra;
      _targetUrl = nextUrl;
    } else {
      _currentMissionText = 'Semua Misi\nTelah Selesai! 🎉';
      _targetRoute = '/disasters';
      _targetExtra = null;
      _targetUrl = null;
    }

    _progress = totalSteps == 0 ? 0.0 : (completedSteps / totalSteps);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _calcFuture,
      builder: (context, snapshot) {
        final pctStr = (_progress * 100).round().toString();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color.fromARGB(255, 3, 87, 60)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label + Icon
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'MISI HARIAN',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Mission title
              Text(
                _currentMissionText,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),

              // Progress
              Row(
                children: [
                  const Text(
                    'Progres Keseluruhan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$pctStr%',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF69F0AE),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_targetUrl != null) {
                      if (_currentMissionText.contains('LKPD')) {
                        context.read<QuizProvider>().markLkpdOpened();
                      } else if (_currentMissionText.contains('E-Modul')) {
                        context.read<QuizProvider>().markEmodulOpened();
                      }
                      
                      final uri = Uri.parse(_targetUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    } else {
                      context.push(_targetRoute, extra: _targetExtra);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lanjut Belajar',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 2500.ms,
          color: Colors.white.withOpacity(0.15),
        );
      }
    );
  }
}
