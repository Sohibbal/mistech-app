import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/disaster_provider.dart';
import '../../../providers/quiz_provider.dart';
import '../../../providers/music_provider.dart';
import '../../../data/models/disaster_model.dart';
import '../widgets/disaster_category_card.dart';
import '../widgets/daily_mission_card.dart';
import '../widgets/safety_tip_banner.dart';
import '../../quiz/screens/quiz_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  String _userName = 'Pengguna';

  // ── Animasi floating icons ──
  late AnimationController _floatCtrl1;
  late AnimationController _floatCtrl2;
  late AnimationController _floatCtrl3;
  late Animation<double> _floatAnim1;
  late Animation<double> _floatAnim2;
  late Animation<double> _floatAnim3;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _loadUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DisasterProvider>().loadDisasters();
      context.read<QuizProvider>().fetchMaterials();
    });

    // Setup floating animations (offset Y, durasi berbeda agar tidak sinkron)
    _floatCtrl1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatCtrl2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatCtrl3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _floatAnim1 = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _floatCtrl1, curve: Curves.easeInOut));
    _floatAnim2 = Tween<double>(
      begin: 0,
      end: -8,
    ).animate(CurvedAnimation(parent: _floatCtrl2, curve: Curves.easeInOut));
    _floatAnim3 = Tween<double>(
      begin: 0,
      end: -12,
    ).animate(CurvedAnimation(parent: _floatCtrl3, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatCtrl1.dispose();
    _floatCtrl2.dispose();
    _floatCtrl3.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Pengguna';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody()),
      floatingActionButton: _buildScannerFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return _buildHomeContent();
      case 2:
        return const QuizListScreen();
      default:
        return _buildHomeContent();
    }
  }

  Future<void> _handleRefresh() async {
    final dProv = context.read<DisasterProvider>();
    final qProv = context.read<QuizProvider>();

    await Future.wait([
      dProv.loadDisasters(),
      qProv.loadQuiz(),
      _loadUserName(),
    ]);
  }

  // ─── HOME TAB ───────────────────────────────────
  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          // ── Animated disaster icons banner ──
          SliverToBoxAdapter(child: _buildAnimatedBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: const DailyMissionCard().animate().fadeIn(
                duration: 400.ms,
                delay: 200.ms,
              ),
            ),
          ),
          // ── Tombol Berita full-width ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child:
                  Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warning.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Opacity(
                                  opacity: 0.25,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: -100,
                                        top: -100,
                                        right: -100,
                                        bottom: -100,
                                        child:
                                            Wrap(
                                                  spacing: 20,
                                                  runSpacing: 20,
                                                  children: List.generate(
                                                    30,
                                                    (i) => const Text(
                                                      '📰',
                                                      style: TextStyle(
                                                        fontSize: 28,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .animate(
                                                  onPlay: (c) => c.repeat(),
                                                )
                                                .slideX(
                                                  begin: 0,
                                                  end: 0.1,
                                                  duration: 4000.ms,
                                                  curve: Curves.linear,
                                                )
                                                .slideY(
                                                  begin: 0,
                                                  end: 0.1,
                                                  duration: 5000.ms,
                                                  curve: Curves.linear,
                                                ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  context.read<QuizProvider>().markNewsOpened();
                                  context.push('/news');
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.newspaper_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Berita',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(
                        duration: 2500.ms,
                        color: Colors.white.withOpacity(0.15),
                      ),
            ),
          ),
          // ── Padding atas grid ──
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          // ── Grid LKPD / E-Modul / Disaster cards ──
          Consumer<DisasterProvider>(
            builder: (context, provider, _) {
              if (provider.isListLoading) {
                return const SliverToBoxAdapter(child: _ShimmerGrid());
              }
              if (provider.disasters.isEmpty) {
                return const SliverToBoxAdapter(child: _EmptyState());
              }
              final items = provider.disasters;
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == 0) {
                      return _buildPdfCard(
                        context,
                        title: 'LKPD',
                        icon: Icons.assignment_rounded,
                        color: AppColors.primary,
                        url:
                            context.watch<QuizProvider>().lkpdUrl ??
                            'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                        imagePath: 'assets/images/sampul_lkpd.png',
                      );
                    } else if (index == 1) {
                      return _buildPdfCard(
                        context,
                        title: 'E-Modul',
                        icon: Icons.menu_book_rounded,
                        color: Colors.orange,
                        url:
                            context.watch<QuizProvider>().eModulUrl ??
                            'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                        imagePath: 'assets/images/sampul_emodul.png',
                      );
                    } else {
                      final disasterIndex = index - 2;
                      return DisasterCategoryCard(
                        disaster: items[disasterIndex],
                        index: disasterIndex,
                        onTap: () => context.push(
                          '/disasters/${items[disasterIndex].id}',
                          extra: items[disasterIndex].toJson(),
                        ),
                      );
                    }
                  }, childCount: items.length + 2),
                ),
              );
            },
          ),
          // ── Tombol Semua Bencana full-width ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/disasters'),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.grid_view_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Semua Bencana',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                    duration: 2500.ms,
                    color: Colors.white.withOpacity(0.15),
                  ),
            ),
          ),
          // ── Tombol Zepquiz full-width ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B1FA2).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final uri = Uri.parse('https://quiz.zep.us/id/play/XW4B0P');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.quiz_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Zepquiz',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                    duration: 2500.ms,
                    color: Colors.white.withOpacity(0.15),
                  ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: const SafetyTipBanner().animate().fadeIn(
                duration: 400.ms,
                delay: 500.ms,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  // ── Animated floating icons banner ──────────────
  Widget _buildAnimatedBanner() {
    return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.12),
                AppColors.secondary.withOpacity(0.08),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.15),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yuk, Belajar Bencana! 🌟',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Kenali bencana & tetap aman',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Floating icon 1 – Api (kebakaran hutan)
              AnimatedBuilder(
                animation: _floatAnim1,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _floatAnim1.value),
                  child: _buildFloatIcon('🔥', const Color(0xFFFF6B35)),
                ),
              ),
              const SizedBox(width: 8),
              // Floating icon 2 – Banjir
              AnimatedBuilder(
                animation: _floatAnim2,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _floatAnim2.value),
                  child: _buildFloatIcon('🌊', const Color(0xFF4FC3F7)),
                ),
              ),
              const SizedBox(width: 8),
              // Floating icon 3 – Buku edukasi
              AnimatedBuilder(
                animation: _floatAnim3,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _floatAnim3.value),
                  child: _buildFloatIcon('📚', const Color(0xFF81C784)),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: 100.ms)
        .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 100.ms);
  }

  Widget _buildFloatIcon(String emoji, Color bgColor) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(color: bgColor.withOpacity(0.4), width: 1.5),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $_userName! 👋',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Siap belajar hari ini?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tombol Music Toggle
          Consumer<MusicProvider>(
            builder: (context, musicProv, _) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => musicProv.toggleMusic(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: Icon(
                    musicProv.isMusicEnabled 
                      ? Icons.volume_up_rounded 
                      : Icons.volume_off_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildScannerFAB() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => context.push('/scanner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  // ─── BOTTOM NAV ─────────────────────────────────
  Widget _buildBottomNav() {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 20,
        shadowColor: AppColors.primary.withOpacity(0.5),
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                // Home
                Expanded(
                  child: _navItem(
                    0,
                    Icons.home_rounded,
                    Icons.home_outlined,
                    'Beranda',
                  ),
                ),
                // Empty space for FAB
                const Expanded(child: SizedBox()),
                // Quiz
                Expanded(
                  child: _navItem(
                    2,
                    Icons.quiz_rounded,
                    Icons.quiz_outlined,
                    'Evaluasi',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentNavIndex = index);
        if (index == 2) {
          context.read<QuizProvider>().loadQuiz();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primarySurface : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                color: isActive ? AppColors.primary : AppColors.textTertiary,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String url,
    String? imagePath,
  }) {
    ImageProvider? imageProvider;
    if (imagePath != null) {
      if (imagePath.startsWith('http')) {
        imageProvider = NetworkImage(imagePath);
      } else {
        imageProvider = AssetImage(imagePath);
      }
    }

    return Card(
          elevation: 4,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () async {
              if (title == 'LKPD') {
                context.read<QuizProvider>().markLkpdOpened();
              } else if (title == 'E-Modul') {
                context.read<QuizProvider>().markEmodulOpened();
              }
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                gradient: imageProvider == null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color.withOpacity(0.8), color],
                      )
                    : null,
                image: imageProvider != null
                    ? DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.25),
                          BlendMode.darken,
                        ),
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2500.ms, color: Colors.white.withOpacity(0.15));
  }
}

// ─── Helpers ───────────────────────────────────────
class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.0,
        ),
        itemCount: 6,
        itemBuilder: (context, index) =>
            Container(
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                  duration: 1200.ms,
                  color: Colors.white.withOpacity(0.6),
                ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 60,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
