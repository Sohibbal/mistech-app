import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/quiz_provider.dart';
import '../../../data/models/quiz_model.dart';

class QuizScreen extends StatefulWidget {
  final Map<String, dynamic>? extraData;
  const QuizScreen({super.key, this.extraData});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadQuiz();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(bool isCorrect) async {
    try {
      final path = isCorrect ? 'audio/correct.mp3' : 'audio/incorrect.mp3';
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizTitle = widget.extraData?['quizTitle'] ?? 'Evaluasi Bencana';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(quizTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _confirmExit(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Consumer<QuizProvider>(
            builder: (_, prov, __) {
              final quiz = prov.currentQuiz;
              if (quiz == null || quiz.questions.isEmpty) {
                return const SizedBox.shrink();
              }
              final progress =
                  (prov.currentQuestionIndex + 1) / quiz.questions.length;
              return LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.primarySurface,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              );
            },
          ),
        ),
      ),
      body: Consumer<QuizProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final quiz = prov.currentQuiz;
          if (quiz == null) {
            return _buildError();
          }
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: quiz.questions.length,
                  onPageChanged: (i) => prov.goToQuestion(i),
                  itemBuilder: (context, index) {
                    return _QuestionCard(
                      question: quiz.questions[index],
                      questionNumber: index + 1,
                      totalQuestions: quiz.questions.length,
                      selectedIndex: prov.getSelectedAnswer(index),
                      isSubmitted: prov.isSubmitted,
                      isChecked: prov.isQuestionChecked(index),
                      onSelect: (optIndex) =>
                          prov.selectAnswer(index, optIndex),
                    );
                  },
                ),
              ),
              _buildBottomBar(prov, quiz),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(QuizProvider prov, QuizModel quiz) {
    final isLast = prov.currentQuestionIndex == quiz.questions.length - 1;
    final hasAnswer = prov.getSelectedAnswer(prov.currentQuestionIndex) != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Question dots
            _QuestionDots(
              total: quiz.questions.length,
              current: prov.currentQuestionIndex,
              answers: prov.selectedAnswers,
              onTap: (i) {
                prov.goToQuestion(i);
                _pageController.animateToPage(i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Back button
                if (prov.currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        prov.previousQuestion();
                        _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Sebelumnya',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (prov.currentQuestionIndex > 0) const SizedBox(width: 12),

                // Next / Submit / Check
                Expanded(
                  flex: 2,
                  child: () {
                    final isChecked = prov.isQuestionChecked(prov.currentQuestionIndex);
                    
                    if (hasAnswer && !isChecked && !prov.isSubmitted) {
                      // Show Check Answer Button
                      return ElevatedButton(
                        onPressed: () {
                          final isCorrect = prov.checkAnswer(prov.currentQuestionIndex);
                          _playSound(isCorrect);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.secondary, // Different color for Check
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Cek Jawaban',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }

                    return ElevatedButton(
                      onPressed: (hasAnswer || prov.isSubmitted)
                          ? () async {
                              if (isLast) {
                                if (prov.isAllAnswered) {
                                  await _submitQuiz(prov);
                                } else {
                                  _showUnansweredDialog(prov);
                                }
                              } else {
                                prov.nextQuestion();
                                _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut);
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primarySurface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isLast ? 'Selesai & Kirim' : 'Berikutnya',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    );
                  }(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitQuiz(QuizProvider prov) async {
    setState(() => _isSubmitting = true);
    final result = await prov.submitQuiz();
    setState(() => _isSubmitting = false);
    if (mounted) {
      context.pushReplacement('/quiz-result', extra: result);
    }
  }

  void _showUnansweredDialog(QuizProvider prov) {
    final unanswered =
        (prov.currentQuiz?.questions.length ?? 0) - prov.selectedAnswers.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Soal Belum Dijawab',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(
          'Masih ada $unanswered soal yang belum dijawab. Apakah yakin ingin mengirim?',
          style: const TextStyle(
              fontFamily: 'Poppins', color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Lanjut Isi')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _submitQuiz(prov);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child:
                const Text('Kirim Saja', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Quiz?',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text(
          'Progres jawaban akan hilang jika keluar sekarang.',
          style:
              TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tetap Di Sini')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return const Center(
      child: Text('Gagal memuat soal quiz.',
          style:
              TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
    );
  }
}

// ────────────────────────────────────────────
// Question Card
// ────────────────────────────────────────────
class _QuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final int? selectedIndex;
  final bool isSubmitted;
  final bool isChecked;
  final ValueChanged<int> onSelect;

  const _QuestionCard({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.selectedIndex,
    required this.isSubmitted,
    required this.isChecked,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question counter
          Text(
            'Pertanyaan $questionNumber dari $totalQuestions',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Question text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              question.question,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.55,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          // Options
          ...question.options.asMap().entries.map((entry) {
            final i = entry.key;
            final opt = entry.value;
            final isCorrect = i == question.correctIndex;
            final showFeedback = isSubmitted || isChecked;
            return _OptionTile(
              label: String.fromCharCode(65 + i), // A, B, C, D
              text: opt,
              isSelected: selectedIndex == i,
              isCorrect: showFeedback ? isCorrect : null,
              isWrongSelected: showFeedback && (selectedIndex == i) && !isCorrect,
              onTap: showFeedback ? null : () => onSelect(i),
              index: i,
            );
          }),

          // Visual Feedback for Check Answer
          if (isChecked && !isSubmitted) ...[
            const SizedBox(height: 20),
            _CheckFeedback(
              isCorrect: selectedIndex == question.correctIndex,
            ),
          ],

          // Explanation (after submit or check)
          if ((isSubmitted || isChecked) && question.explanation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────
// Option Tile
// ────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool? isCorrect;
  final bool isWrongSelected;
  final VoidCallback? onTap;
  final int index;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrongSelected,
    required this.onTap,
    required this.index,
  });

  Color get _borderColor {
    if (isCorrect == true) return AppColors.success;
    if (isWrongSelected) return AppColors.error;
    if (isSelected) return AppColors.primary;
    return AppColors.border;
  }

  Color get _bgColor {
    if (isCorrect == true) return AppColors.successLight;
    if (isWrongSelected) return AppColors.errorLight;
    if (isSelected) return AppColors.primarySurface;
    return Colors.white;
  }

  Color get _labelColor {
    if (isCorrect == true) return AppColors.success;
    if (isWrongSelected) return AppColors.error;
    if (isSelected) return AppColors.primary;
    return AppColors.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _labelColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _labelColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            if (isCorrect == true)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 20),
            if (isWrongSelected)
              const Icon(Icons.cancel_rounded,
                  color: AppColors.error, size: 20),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 60 * index))
          .fadeIn(duration: 250.ms)
          .slideX(begin: 0.06, end: 0, duration: 250.ms),
    );
  }
}

// ────────────────────────────────────────────
// Question Dots Navigator
// ────────────────────────────────────────────
class _QuestionDots extends StatelessWidget {
  final int total;
  final int current;
  final Map<int, int> answers;
  final ValueChanged<int> onTap;

  const _QuestionDots({
    required this.total,
    required this.current,
    required this.answers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isCurrent = i == current;
        final isAnswered = answers.containsKey(i);
        Color bgColor;
        Color textColor;
        Color borderColor;

        if (isCurrent) {
          bgColor = AppColors.primary;
          textColor = Colors.white;
          borderColor = AppColors.primary;
        } else if (isAnswered) {
          bgColor = AppColors.success;
          textColor = Colors.white;
          borderColor = AppColors.success;
        } else {
          bgColor = Colors.white;
          textColor = AppColors.textSecondary;
          borderColor = AppColors.border;
        }

        return Expanded(
          child: GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CheckFeedback extends StatelessWidget {
  final bool isCorrect;

  const _CheckFeedback({required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect ? AppColors.success : AppColors.error,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCorrect ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCorrect ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 24,
            ),
          ).animate().scale(curve: Curves.elasticOut),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Jawaban Benar!' : 'Jawaban Kurang Tepat',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isCorrect ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  isCorrect
                      ? 'Hebat! Kamu memahami materi ini dengan baik.'
                      : 'Jangan menyerah! Coba pelajari lagi penjelasannya di bawah.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: (isCorrect ? AppColors.success : AppColors.error)
                        .withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Custom Assets Icon
          Image.asset(
            isCorrect ? 'assets/icons/correct.png' : 'assets/icons/incorrect.png',
            width: 40,
            height: 40,
            errorBuilder: (c, e, s) => const SizedBox.shrink(),
          ).animate().shake(duration: 500.ms),
        ],
      ),
    ).animate().slideY(begin: 0.2, end: 0).fadeIn();
  }
}
