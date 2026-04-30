import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: AppConstants.splashDuration,
    )..addListener(() {
        setState(() {
          _progress = _progressController.value;
        });
      });

    _startSplash();
  }

  Future<void> _startSplash() async {
    _progressController.forward();
    await Future.delayed(AppConstants.splashDuration);
    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone =
          prefs.getBool(AppConstants.keyOnboardingDone) ?? false;
      if (mounted) {
        context.go(onboardingDone ? '/home' : '/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.splashGradient,
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo Card
              _buildLogoCard()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.0, 1.0),
                    duration: 600.ms,
                    delay: 200.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 48),

              // App Name
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 500.ms).slideY(
                    begin: 0.3,
                    end: 0,
                    duration: 600.ms,
                    delay: 500.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: 12),

              // Tagline
              Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 700.ms),

              const Spacer(flex: 2),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4CAF50),
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 1000.ms),

              const SizedBox(height: 48),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'by ',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'MiSTech',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 1200.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoCard() {
    return Container(
      width: 160,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Shield Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          // Disaster icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _disasterIcon(Icons.water_rounded),
              const SizedBox(width: 12),
              _disasterIcon(Icons.volcano_rounded),
              const SizedBox(width: 12),
              _disasterIcon(Icons.vibration_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _disasterIcon(IconData icon) {
    return Icon(
      icon,
      color: Colors.white.withOpacity(0.7),
      size: 22,
    );
  }
}
