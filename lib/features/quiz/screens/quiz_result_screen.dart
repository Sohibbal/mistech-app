import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quiz_model.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizResult result;
  const QuizResultScreen({super.key, required this.result});

  Color get _gradeColor {
    final s = result.scorePercent;
    if (s >= 90) return AppColors.success;
    if (s >= 70) return AppColors.primary;
    return AppColors.error;
  }

  IconData get _gradeIcon {
    final s = result.scorePercent;
    if (s >= 90) return Icons.emoji_events_rounded;
    if (s >= 70) return Icons.thumb_up_rounded;
    return Icons.sentiment_dissatisfied_rounded;
  }

  String get _gradeMessage {
    final s = result.scorePercent;
    if (s >= 90) return 'Luar Biasa! Kamu sangat siap menghadapi bencana!';
    if (s >= 70) return 'Bagus! Kamu sudah memahami dasar keselamatan bencana.';
    return 'Jangan menyerah! Pelajari kembali materinya dan coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildScoreHero()),
            SliverToBoxAdapter(child: _buildReviewSection()),
            SliverToBoxAdapter(child: _buildActions(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHero() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradeColor, _gradeColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _gradeColor.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(_gradeIcon, color: Colors.white, size: 56).animate().scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.elasticOut),

          const SizedBox(height: 16),

          // Score circle
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${result.scorePercent}%',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Grade ${result.grade}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          Text(
            result.isPassed ? 'QUIZ LULUS!' : 'BELUM LULUS',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 8),

          Text(
            _gradeMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xCCFFFFFF),
              height: 1.5,
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBubble(
                  label: 'Benar',
                  value: '${result.correctAnswers}',
                  icon: Icons.check_rounded),
              _StatBubble(
                  label: 'Salah',
                  value: '${result.totalQuestions - result.correctAnswers}',
                  icon: Icons.close_rounded),
              _StatBubble(
                  label: 'Total',
                  value: '${result.totalQuestions}',
                  icon: Icons.quiz_rounded),
            ],
          ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tinjauan Jawaban',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...result.answers.asMap().entries.map((e) {
            final idx = e.key;
            final ans = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ans.isCorrect
                      ? AppColors.success.withOpacity(0.4)
                      : AppColors.error.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ans.isCorrect
                          ? AppColors.successLight
                          : AppColors.errorLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ans.isCorrect
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ans.isCorrect
                          ? 'Jawaban benar ✓'
                          : 'Salah — Jawaban benar: ${String.fromCharCode(65 + ans.correctIndex)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color:
                            ans.isCorrect ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 60 * idx))
                .fadeIn(duration: 250.ms);
          }),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.go('/home'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Kembali ke Home',
                  style: TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Ulangi Quiz',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatBubble(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 11, color: Color(0xB3FFFFFF))),
        // Color(0xB3FFFFFF) = Colors.white70 equivalent as const
      ],
    );
  }
}
