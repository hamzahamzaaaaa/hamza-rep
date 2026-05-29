import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/statistics_provider.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    final totalHours = stats.totalListeningSeconds ~/ 3600;
    final totalMinutes = (stats.totalListeningSeconds % 3600) ~/ 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "إحصائيات الاستماع",
          style: GoogleFonts.amiri(
            color: AppColors.gold,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.gold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Donut Chart
            SizedBox(
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 80,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          color: AppColors.gold,
                          value: stats.totalListeningSeconds.toDouble() == 0 ? 1 : stats.totalListeningSeconds.toDouble(),
                          title: '',
                          radius: 15,
                          showTitle: false,
                        ),
                        if (stats.totalListeningSeconds == 0)
                          PieChartSectionData(
                            color: AppColors.muted,
                            value: 100,
                            title: '',
                            radius: 15,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$totalHours",
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        "ساعات و $totalMinutes دقيقة",
                        style: GoogleFonts.amiri(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_fire_department,
                    title: "أيام متتالية",
                    value: "${stats.currentStreak}",
                    subtitle: "أطول سلسلة: ${stats.longestStreak}",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.play_circle_filled,
                    title: "السور المستمعة",
                    value: "${stats.playCounts.length}",
                    subtitle: "من أصل 114",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Badges Section
            if (stats.unlockedBadges.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                "الأوسمة المكتسبة",
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.end,
                children: stats.unlockedBadges.map((badge) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: AppColors.gold, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _getBadgeName(badge),
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getBadgeName(String id) {
    switch(id) {
      case 'first_step': return 'الخطوة الأولى';
      case 'devoted': return 'مستمع وفي';
      case 'guardian': return 'صاحب القرآن';
      case 'consistent': return 'مواظب';
      case 'habit_builder': return 'باني العادات';
      case 'night_owl': return 'مستمع الليل';
      case 'dawn_seeker': return 'طالب الفجر';
      default: return 'وسام جديد';
    }
  }
}
