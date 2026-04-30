import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/quiz_provider.dart';
import '../../../providers/disaster_provider.dart';
import '../../../data/models/quiz_model.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadQuizList();
      // Also make sure disasters are loaded for icons
      final dp = context.read<DisasterProvider>();
      if (dp.disasters.isEmpty) dp.loadDisasters();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<QuizProvider>().loadQuizList();
    final dp = context.read<DisasterProvider>();
    await dp.loadDisasters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader()),

            // Body
            Consumer<QuizProvider>(
              builder: (context, quizProv, _) {
                if (quizProv.isListLoading) {
                  return _buildShimmer();
                }

                if (quizProv.quizzes.isEmpty) {
                  return _buildEmpty();
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final quiz = quizProv.quizzes[index];
                        final progress = quizProv.progressMap[quiz.disasterId];
                        final isUpdated = quizProv.isQuizUpdated(quiz);
                        return _QuizCard(
                          quiz: quiz,
                          progress: progress,
                          isUpdated: isUpdated,
                          index: index,
                          onTap: () {
                            final locked = !(progress?.isUnlocked ?? false);
                            if (locked) {
                              _showLockedDialog(context, quiz.disasterName);
                            } else {
                              context.push(
                                '/quiz/${quiz.disasterId}',
                                extra: {
                                  'quizId': quiz.id,
                                  'disasterName': quiz.disasterName
                                },
                              );
                            }
                          },
                        );
                      },
                      childCount: quizProv.quizzes.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.quiz_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quiz Bencana',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Selesaikan semua fase pembelajaran (Pra, Saat & Pasca) untuk membuka quiz setiap bencana.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          Row(
            children: [
              _legendItem(
                  Icons.lock_rounded, AppColors.textTertiary, 'Terkunci'),
              const SizedBox(width: 16),
              _legendItem(Icons.play_circle_rounded, AppColors.primary,
                  'Bisa dikerjakan'),
              const SizedBox(width: 16),
              _legendItem(
                  Icons.check_circle_rounded, AppColors.success, 'Selesai'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _legendItem(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildShimmer() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: List.generate(
            5,
            (i) => Container(
              height: 90,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: 1200.ms, color: Colors.white.withOpacity(0.6)),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildEmpty() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.quiz_outlined,
                  size: 64, color: AppColors.textTertiary),
              SizedBox(height: 16),
              Text(
                'Belum ada quiz tersedia',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLockedDialog(BuildContext context, String disasterName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: AppColors.warning),
            SizedBox(width: 10),
            Text(
              'Quiz Terkunci',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Selesaikan terlebih dahulu semua fase pembelajaran $disasterName:\n\n'
          '✅ Pra Bencana\n'
          '✅ Saat Bencana\n'
          '✅ Pasca Bencana\n\n'
          'Setelah selesai, quiz akan terbuka otomatis.',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Mengerti',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Quiz Card Widget
// ─────────────────────────────────────────────────

class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final QuizProgressRecord? progress;
  final bool isUpdated;
  final int index;
  final VoidCallback onTap;

  const _QuizCard({
    required this.quiz,
    required this.progress,
    required this.isUpdated,
    required this.index,
    required this.onTap,
  });

  static IconData _getIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('gempa')) return Icons.terrain_rounded;
    if (n.contains('banjir')) return Icons.water_rounded;
    if (n.contains('gunung')) return Icons.volcano_rounded;
    if (n.contains('tsunami')) return Icons.waves_rounded;
    if (n.contains('longsor')) return Icons.landslide_rounded;
    if (n.contains('kebakaran')) return Icons.local_fire_department_rounded;
    if (n.contains('puting') || n.contains('angin')) return Icons.air_rounded;
    return Icons.warning_amber_rounded;
  }

  bool get _isLocked => !(progress?.isUnlocked ?? false);
  bool get _hasCompleted => progress?.hasCompleted ?? false;

  Color get _statusColor {
    if (_isLocked) return AppColors.textTertiary;
    if (_hasCompleted) return AppColors.success;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isLocked
                ? AppColors.border
                : _hasCompleted
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.primarySurface2,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (_isLocked ? Colors.grey : AppColors.primary)
                  .withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isLocked
                      ? const Color(0xFFF5F5F5)
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _isLocked ? Icons.lock_rounded : _getIcon(quiz.disasterName),
                  color: _isLocked ? AppColors.textTertiary : AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            quiz.disasterName,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _isLocked
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        // Updated badge
                        if (isUpdated) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.warning.withOpacity(0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.update_rounded,
                                    size: 11, color: AppColors.warning),
                                SizedBox(width: 3),
                                Text(
                                  'Updated',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .fadeIn(duration: 600.ms),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      _isLocked
                          ? 'Selesaikan semua fase pembelajaran'
                          : _hasCompleted
                              ? 'Skor terakhir: ${progress?.lastScore ?? 0}%'
                              : '${quiz.totalQuestions} soal pilihan ganda',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: _isLocked
                            ? AppColors.textTertiary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Status row
                    Row(
                      children: [
                        // Progress phases if locked
                        if (_isLocked)
                          _PhasePipsWidget(disasterId: quiz.disasterId)
                        else
                          _StatusChip(
                            icon: _hasCompleted
                                ? Icons.check_circle_rounded
                                : Icons.play_circle_fill_rounded,
                            label: _hasCompleted
                                ? 'Selesai — Ulangi?'
                                : 'Mulai Quiz',
                            color: _statusColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(
                _isLocked
                    ? Icons.lock_outline_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 16,
                color: _statusColor,
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 70 * index))
          .fadeIn(duration: 350.ms)
          .slideX(begin: 0.08, end: 0, duration: 350.ms),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhasePipsWidget extends StatefulWidget {
  final String disasterId;
  const _PhasePipsWidget({required this.disasterId});

  @override
  State<_PhasePipsWidget> createState() => _PhasePipsWidgetState();
}

class _PhasePipsWidgetState extends State<_PhasePipsWidget> {
  Map<String, bool> _status = {'pra': false, 'saat': false, 'pasca': false};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final quizProv = context.read<QuizProvider>();
    final s = await quizProv.getPhasesStatus(widget.disasterId);
    if (mounted) setState(() => _status = s);
  }

  @override
  Widget build(BuildContext context) {
    final phases = [
      ('Pra', _status['pra'] ?? false),
      ('Saat', _status['saat'] ?? false),
      ('Pasca', _status['pasca'] ?? false),
    ];
    return Row(
      children: phases.map((p) {
        return Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: p.$2
                ? AppColors.success.withOpacity(0.1)
                : AppColors.border.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                p.$2 ? Icons.check_rounded : Icons.circle_outlined,
                size: 10,
                color: p.$2 ? AppColors.success : AppColors.textTertiary,
              ),
              const SizedBox(width: 3),
              Text(
                p.$1,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: p.$2 ? AppColors.success : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
