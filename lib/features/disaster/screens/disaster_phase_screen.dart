import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/disaster_provider.dart';
import '../../../providers/quiz_provider.dart';
import '../../../data/models/disaster_model.dart';

class DisasterPhaseScreen extends StatefulWidget {
  final String disasterId;
  final String phase; // pra, saat, pasca
  final Map<String, dynamic>? extraData;

  const DisasterPhaseScreen({
    super.key,
    required this.disasterId,
    required this.phase,
    this.extraData,
  });

  @override
  State<DisasterPhaseScreen> createState() => _DisasterPhaseScreenState();
}

class _DisasterPhaseScreenState extends State<DisasterPhaseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DisasterProvider>();
      if (provider.selectedDisaster?.id != widget.disasterId) {
        provider.loadDisasterDetail(widget.disasterId);
      }
    });
  }

  Color get _phaseColor {
    switch (widget.phase) {
      case 'pra':
        return AppColors.praBencana;
      case 'saat':
        return AppColors.saatBencana;
      case 'pasca':
        return AppColors.pascaBencana;
      default:
        return AppColors.primary;
    }
  }

  String get _phaseTitle {
    switch (widget.phase) {
      case 'pra':
        return 'Pra Bencana';
      case 'saat':
        return 'Saat Bencana';
      case 'pasca':
        return 'Pasca Bencana';
      default:
        return 'Bencana';
    }
  }

  IconData get _phaseIcon {
    switch (widget.phase) {
      case 'pra':
        return Icons.backpack_rounded;
      case 'saat':
        return Icons.campaign_rounded;
      case 'pasca':
        return Icons.eco_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  void _onLanjutPressed() async {
    final disasterName = widget.extraData?['disasterName'] ?? '';
    
    // Simpan progres ke local storage melalui QuizProvider
    await context.read<QuizProvider>().markPhaseCompleted(widget.disasterId, widget.phase);

    if (!mounted) return;

    if (widget.phase == 'pra') {
      context.pushReplacement('/disasters/${widget.disasterId}/phase/saat', extra: {
        'disasterName': disasterName,
      });
    } else if (widget.phase == 'saat') {
      context.pushReplacement('/disasters/${widget.disasterId}/phase/pasca', extra: {
        'disasterName': disasterName,
      });
    } else {
      // Pasca selesai -> Kembali ke home screen. Quiz sudah otomatis terbuka di menu Quiz Navbar.
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final disasterName = widget.extraData?['disasterName'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(disasterName.isNotEmpty ? disasterName : 'Detail Bencana'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<DisasterProvider>(
        builder: (context, provider, _) {
          if (provider.isDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final phaseContent = provider.getPhase(widget.phase);
          if (phaseContent == null) {
            return _buildEmptyState('Konten belum tersedia');
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildPhaseHeader(phaseContent),
                    const SizedBox(height: 24),

                    // Always show Guide/Articles
                    if (phaseContent.articles.isNotEmpty) ...[
                      const Text(
                        'Panduan Lengkap',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...phaseContent.articles.asMap().entries.map((entry) {
                        return _ArticleCard(
                          article: entry.value,
                          index: entry.key,
                          phaseColor: _phaseColor,
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // Phase specific media
                    if (widget.phase == 'pra' || widget.phase == 'pasca') ...[
                      if (phaseContent.imageUrls.isNotEmpty) ...[
                        const Text(
                          'Ilustrasi & Foto',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: phaseContent.imageUrls.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _showImageDialog(
                                  context, phaseContent.imageUrls[index]),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: phaseContent.imageUrls[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                      color: AppColors.primarySurface),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: AppColors.primarySurface,
                                    child: const Icon(
                                        Icons.broken_image_rounded,
                                        color: AppColors.textTertiary),
                                  ),
                                ),
                              )
                                  .animate(
                                      delay:
                                          Duration(milliseconds: 100 * index))
                                  .fadeIn()
                                  .scale(),
                            );
                          },
                        ),
                      ]
                    ] else if (widget.phase == 'saat') ...[
                      if (phaseContent.videos.isNotEmpty) ...[
                        const Text(
                          'Video Simulasi',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...phaseContent.videos.asMap().entries.map((entry) {
                          return _VideoCard(
                            video: entry.value,
                            index: entry.key,
                            onTap: () => context.push('/video', extra: {
                              'title': entry.value.title,
                              'videoUrl': entry.value.videoUrl,
                              'thumbnailUrl': entry.value.thumbnailUrl.isNotEmpty 
                                  ? entry.value.thumbnailUrl 
                                  : (provider.selectedDisaster?.imageUrl ?? ''),
                              'description': entry.value.description,
                            }),
                          );
                        }),
                      ]
                    ],
                  ],
                ),
              ),
              // Lanjut Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onLanjutPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _phaseColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        widget.phase == 'pasca' ? 'Selesai Belajar' : 'Lanjut Fase Berikutnya',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhaseHeader(PhaseContent content) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _phaseColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _phaseColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _phaseColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_phaseIcon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _phaseTitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _phaseColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content.description,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 64,
              color: _phaseColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final ArticleItem article;
  final int index;
  final Color phaseColor;

  const _ArticleCard({
    required this.article,
    required this.index,
    required this.phaseColor,
  });

  Color get _typeColor {
    switch (article.type) {
      case 'warning':
        return AppColors.warning;
      case 'tip':
        return AppColors.success;
      case 'info':
      default:
        return AppColors.primary;
    }
  }

  IconData get _typeIcon {
    switch (article.type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'tip':
        return Icons.tips_and_updates_rounded;
      case 'info':
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  article.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Text(
            article.content,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn()
        .slideY(begin: 0.1, end: 0);
  }
}

class _VideoCard extends StatelessWidget {
  final VideoModel video;
  final int index;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  if (video.thumbnailUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: video.thumbnailUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _buildVideoPlaceholder(),
                    )
                  else if (context.read<DisasterProvider>().selectedDisaster?.imageUrl != null && context.read<DisasterProvider>().selectedDisaster!.imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: context.read<DisasterProvider>().selectedDisaster!.imageUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _buildVideoPlaceholder(),
                    )
                  else
                    _buildVideoPlaceholder(),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4)
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: AppColors.saatBencana, size: 30),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        video.duration,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 100 * index))
          .fadeIn()
          .slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      color: AppColors.primarySurface,
      child: const Icon(Icons.play_circle_outline_rounded,
          size: 60, color: AppColors.primary),
    );
  }
}
