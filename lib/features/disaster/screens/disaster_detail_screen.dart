import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/disaster_provider.dart';
import '../../../data/models/disaster_model.dart';

class DisasterDetailScreen extends StatefulWidget {
  final String disasterId;
  final Map<String, dynamic>? disasterData;

  const DisasterDetailScreen({
    super.key,
    required this.disasterId,
    this.disasterData,
  });

  @override
  State<DisasterDetailScreen> createState() => _DisasterDetailScreenState();
}

class _DisasterDetailScreenState extends State<DisasterDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DisasterProvider>().loadDisasterDetail(widget.disasterId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<DisasterProvider>(
        builder: (context, provider, _) {
          if (provider.isDetailLoading) {
            return _buildLoadingState();
          }

          final disaster = provider.selectedDisaster;
          if (disaster == null) {
            // Use passed data as fallback
            final data = widget.disasterData;
            if (data != null) {
              return _buildContent(DisasterModel.fromJson(data));
            }
            return _buildErrorState();
          }

          return _buildContent(disaster);
        },
      ),
    );
  }

  Widget _buildContent(DisasterModel disaster) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Hero Header
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          stretch: true,
          backgroundColor: AppColors.primary,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          title: const Text(
            'MiSTech',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Hero Image
                if (disaster.imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: disaster.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.primarySurface,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.primarySurface,
                      child: const Icon(Icons.image_not_supported_rounded,
                          color: AppColors.textTertiary, size: 60),
                    ),
                  )
                else
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Disaster name at bottom
                Positioned(
                  bottom: 16,
                  left: 20,
                  right: 20,
                  child: Text(
                    disaster.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Description
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disaster.description,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 24),

                // Section title
                const Text(
                  'Langkah Kesiapsiagaan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tonton video seru, lihat foto, & pelajari panduan lengkap untuk keselamatan Anda.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Phase Cards
                _PhaseCard(
                  phase: 'pra',
                  title: 'Pra Bencana',
                  subtitle: 'Kenali bahaya & bersiap diri.',
                  icon: Icons.backpack_rounded,
                  color: AppColors.praBencana,
                  bgColor: AppColors.praBencanaLight,
                  index: 0,
                  onTap: () => context.push(
                    '/disasters/${disaster.id}/phase/pra',
                    extra: {
                      'disasterName': disaster.name,
                      'phase': 'pra',
                    },
                  ),
                ),

                const SizedBox(height: 12),

                _PhaseCard(
                  phase: 'saat',
                  title: 'Saat Bencana',
                  subtitle: 'Tahu cara bertindak cepat & aman.',
                  icon: Icons.campaign_rounded,
                  color: AppColors.saatBencana,
                  bgColor: AppColors.saatBencanaLight,
                  index: 1,
                  onTap: () => context.push(
                    '/disasters/${disaster.id}/phase/saat',
                    extra: {
                      'disasterName': disaster.name,
                      'phase': 'saat',
                    },
                  ),
                ),

                const SizedBox(height: 12),

                _PhaseCard(
                  phase: 'pasca',
                  title: 'Pasca Bencana',
                  subtitle: 'Pulih kembali & peduli sesama.',
                  icon: Icons.eco_rounded,
                  color: AppColors.pascaBencana,
                  bgColor: AppColors.pascaBencanaLight,
                  index: 2,
                  onTap: () => context.push(
                    '/disasters/${disaster.id}/phase/pasca',
                    extra: {
                      'disasterName': disaster.name,
                      'phase': 'pasca',
                    },
                  ),
                ),

                const SizedBox(height: 24),

                if (disaster.name.toLowerCase().contains('banjir')) ...[
                  const Text(
                    'Mini Game: Siap Siaga Banjir',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _MiniGameView(assetPath: 'assets/html/minigame_banjir.html'),
                  const SizedBox(height: 24),
                ] else if (disaster.name.toLowerCase().contains('kebakaran')) ...[
                  const Text(
                    'Mini Game: Siap Siaga Kebakaran Hutan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _MiniGameView(assetPath: 'assets/html/minigame_kebakaran_hutan.html'),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
        ),

        // Bottom Buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side:
                            const BorderSide(color: AppColors.border, width: 1.5),
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Kembali',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.push(
                        '/disasters/${disaster.id}/phase/pra',
                        extra: {
                          'disasterName': disaster.name,
                          'phase': 'pra',
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Mulai Belajar',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      appBar: AppBar(leading: BackButton()),
      body: const Center(
        child: Text(
          'Gagal memuat data',
          style:
              TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final String phase;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final int index;
  final VoidCallback onTap;

  const _PhaseCard({
    required this.phase,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withOpacity(0.7),
              size: 24,
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 100 * index))
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.1, end: 0, duration: 300.ms),
    );
  }
}

class _MiniGameView extends StatefulWidget {
  final String assetPath;

  const _MiniGameView({required this.assetPath});

  @override
  State<_MiniGameView> createState() => _MiniGameViewState();
}

class _MiniGameViewState extends State<_MiniGameView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));
    _loadLocalHtml();
  }

  Future<void> _loadLocalHtml() async {
    try {
      final String htmlContent =
          await rootBundle.loadString(widget.assetPath);
      _controller.loadHtmlString(htmlContent);
    } catch (e) {
      debugPrint("Gagal meload HTML minigame: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 680,
      width: double.infinity,
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
      clipBehavior: Clip.antiAlias,
      child: WebViewWidget(controller: _controller),
    );
  }
}
