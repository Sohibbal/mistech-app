import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/quiz_provider.dart';
import '../../../data/models/quiz_model.dart';

class QuizScreen extends StatefulWidget {
  final String disasterId;
  final Map<String, dynamic>? extraData;
  const QuizScreen({super.key, required this.disasterId, this.extraData});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final PageController _pageController = PageController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadQuizDetail(widget.disasterId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disasterName = widget.extraData?['disasterName'] ?? 'Quiz';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(disasterName),
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
          if (prov.isDetailLoading) {
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

              // Next / Submit
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: hasAnswer
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
                ),
              ),
            ],
          ),
        ],
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
  final ValueChanged<int> onSelect;

  const _QuestionCard({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.selectedIndex,
    required this.isSubmitted,
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
            final isSelected = selectedIndex == i;
            final isCorrect = i == question.correctIndex;
            return _OptionTile(
              label: String.fromCharCode(65 + i), // A, B, C, D
              text: opt,
              isSelected: isSelected,
              isCorrect: isSubmitted ? isCorrect : null,
              isWrongSelected: isSubmitted && isSelected && !isCorrect,
              onTap: isSubmitted ? null : () => onSelect(i),
              index: i,
            );
          }),

          // Explanation (after submit)
          if (isSubmitted && question.explanation != null) ...[
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
    return SizedBox(
      height: 28,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: total,
        itemBuilder: (context, i) {
          final isCurrent = i == current;
          final isAnswered = answers.containsKey(i);
          Color color;
          if (isCurrent) {
            color = AppColors.primary;
          } else if (isAnswered) {
            color = AppColors.success;
          } else {
            color = AppColors.border;
          }
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isCurrent ? 22 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          );
        },
      ),
    );
  }
}
