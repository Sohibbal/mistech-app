import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/disaster_provider.dart';
import '../../../data/models/disaster_model.dart';

class DisasterListScreen extends StatefulWidget {
  const DisasterListScreen({super.key});

  @override
  State<DisasterListScreen> createState() => _DisasterListScreenState();
}

class _DisasterListScreenState extends State<DisasterListScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = [
    'Semua',
    'Geologi',
    'Hidrologi',
    'Meteorologi',
    'Klimatologi'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DisasterProvider>().loadDisasters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Semua Bencana'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildFilterChips(),
        ),
      ),
      body: Consumer<DisasterProvider>(
        builder: (context, provider, _) {
          if (provider.isListLoading) {
            return _buildLoadingState();
          }

          final filtered = _selectedFilter == 'Semua'
              ? provider.disasters
              : provider.disasters
                  .where((d) =>
                      d.category.toLowerCase() == _selectedFilter.toLowerCase())
                  .toList();

          if (filtered.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _DisasterListItem(
                disaster: filtered[index],
                index: index,
                onTap: () {
                  context.push(
                    '/disasters/${filtered[index].id}',
                    extra: filtered[index].toJson(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = filter == _selectedFilter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primary : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(18),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(
              duration: 1200.ms,
              color: Colors.white.withOpacity(0.6),
            );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 60, color: AppColors.textTertiary),
          SizedBox(height: 16),
          Text(
            'Tidak ada data',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisasterListItem extends StatelessWidget {
  final DisasterModel disaster;
  final int index;
  final VoidCallback onTap;

  const _DisasterListItem({
    required this.disaster,
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
    if (n.contains('kekeringan')) return Icons.wb_sunny_rounded;
    return Icons.warning_amber_rounded;
  }

  Color _getLevelColor(int level) {
    if (level >= 5) return AppColors.error;
    if (level >= 4) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getIcon(disaster.name),
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    disaster.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    disaster.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Level badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getLevelColor(disaster.level).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Level ${disaster.level} - ${disaster.category}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getLevelColor(disaster.level),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 80 * index))
          .fadeIn(duration: 350.ms)
          .slideX(begin: 0.1, end: 0, duration: 350.ms),
    );
  }
}
