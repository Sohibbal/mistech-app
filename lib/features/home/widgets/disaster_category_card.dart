import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/disaster_model.dart';

class DisasterCategoryCard extends StatelessWidget {
  final DisasterModel disaster;
  final int index;
  final VoidCallback onTap;

  const DisasterCategoryCard({
    super.key,
    required this.disaster,
    required this.index,
    required this.onTap,
  });

  static const List<_DisasterStyle> _styles = [
    _DisasterStyle(
      gradient: [Color(0xFF1565C0), Color(0xFF1976D2)],
      iconBg: Color(0x331976D2),
      icon: Icons.terrain_rounded, // Gempa
    ),
    _DisasterStyle(
      gradient: [Color(0xFF0277BD), Color(0xFF0288D1)],
      iconBg: Color(0x330288D1),
      icon: Icons.water_rounded, // Banjir
    ),
    _DisasterStyle(
      gradient: [Color(0xFF00838F), Color(0xFF00ACC1)],
      iconBg: Color(0x3300ACC1),
      icon: Icons.volcano_rounded, // Gunung
    ),
    _DisasterStyle(
      gradient: [Color(0xFF01579B), Color(0xFF0277BD)],
      iconBg: Color(0x330277BD),
      icon: Icons.waves_rounded, // Tsunami
    ),
    _DisasterStyle(
      gradient: [Color(0xFF283593), Color(0xFF3949AB)],
      iconBg: Color(0x333949AB),
      icon: Icons.landslide_rounded, // Longsor
    ),
    _DisasterStyle(
      gradient: [Color(0xFF1A237E), Color(0xFF283593)],
      iconBg: Color(0x33283593),
      icon: Icons.local_fire_department_rounded, // Kebakaran
    ),
    _DisasterStyle(
      gradient: [Color(0xFF006064), Color(0xFF00838F)],
      iconBg: Color(0x3300838F),
      icon: Icons.air_rounded, // Puting Beliung
    ),
    _DisasterStyle(
      gradient: [Color(0xFF0D47A1), Color(0xFF1565C0)],
      iconBg: Color(0x331565C0),
      icon: Icons.wb_sunny_rounded, // Kekeringan
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    final style = _styles[index % _styles.length];
    final icon = _getIcon(disaster.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: style.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: style.gradient[0].withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const Spacer(),

                  // Disaster name
                  Text(
                    disaster.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mulai Belajar',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 100 * index))
          .fadeIn(duration: 400.ms)
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }
}

class _DisasterStyle {
  final List<Color> gradient;
  final Color iconBg;
  final IconData icon;

  const _DisasterStyle({
    required this.gradient,
    required this.iconBg,
    required this.icon,
  });
}
