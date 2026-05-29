import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/statistics_provider.dart';
import '../../core/providers/advanced_settings_provider.dart';
import '../../core/providers/player_provider.dart';
import 'reader_image.dart';

void showSettingsBottomSheet(BuildContext context, WidgetRef ref) {
  final notifier = ref.read(languageProvider.notifier);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, ref, child) {
              ref.watch(languageProvider);
              final isDark = ref.watch(themeProvider).isDark;
              final settings = ref.watch(advancedSettingsProvider);
              final settingsNotifier = ref.read(advancedSettingsProvider.notifier);
              final playerState = ref.watch(playerProvider);
              final playerNotifier = ref.read(playerProvider.notifier);

              return Container(
                padding: const EdgeInsets.all(24),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 16),
                    Text(notifier.t('الإعدادات', 'Settings', 'Configurações', 'Paramètres'),
                        style: GoogleFonts.amiri(fontSize: 24, color: AppColors.gold, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),

                    // Appearance & Theme
                    _buildSectionHeader(notifier.t('تخصيص المظهر', 'Appearance', 'Aparência', 'Apparence')),
                    ListTile(
                      leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.gold),
                      title: Text(notifier.t('المظهر الداكن', 'Dark Mode', 'Modo Escuro', 'Mode Sombre'), 
                           style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      trailing: Switch(
                        value: isDark && !ref.watch(themeProvider).isDeepBlack,
                        activeThumbColor: AppColors.gold,
                        onChanged: (val) {
                          if (val) {
                            ref.read(themeProvider.notifier).setDark();
                          } else {
                            ref.read(themeProvider.notifier).setLight();
                          }
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.nightlight_round, color: AppColors.gold),
                      title: Text(notifier.t('الأسود العميق', 'Deep Black', 'Preto Profundo', 'Noir Profond'), 
                           style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      trailing: Switch(
                        value: ref.watch(themeProvider).isDeepBlack,
                        activeThumbColor: AppColors.gold,
                        onChanged: (val) {
                          if (val) {
                            ref.read(themeProvider.notifier).setDeepBlack();
                          } else {
                            ref.read(themeProvider.notifier).setDark();
                          }
                        },
                      ),
                    ),
                    _buildSliderTile(
                      title: notifier.t('مستوى التغبيش', 'Blur Level', 'Nível de Desfoque', 'Niveau de flou'),
                      value: settings.blurLevel,
                      min: 0,
                      max: 30,
                      onChanged: (val) => settingsNotifier.setBlurLevel(val),
                    ),
                    _buildSliderTile(
                      title: notifier.t('شفافية المشغل', 'Player Transparency', 'Transparência do Player', 'Transparence du lecteur'),
                      value: settings.playerTransparency,
                      min: 0.0,
                      max: 0.8,
                      onChanged: (val) => settingsNotifier.setPlayerTransparency(val),
                    ),
                    SwitchListTile(
                      title: Text(notifier.t('الوضع الليلي الذكي', 'Smart Night Mode', 'Modo Noturno Inteligente', 'Mode nuit intelligent'),
                           style: TextStyle(color: AppColors.textPrimary)),
                      value: settings.isWarmMode,
                      activeThumbColor: Colors.orangeAccent,
                      onChanged: (val) => settingsNotifier.setWarmMode(val),
                    ),

                    const SizedBox(height: 24),
                    // Language
                    _buildSectionHeader(notifier.t('اللغة', 'Language', 'Idioma', 'Langue')),
                    ListTile(
                      leading: const Icon(Icons.language, color: AppColors.gold),
                      title: Text(notifier.t('تغيير اللغة', 'Change Language', 'Mudar Idioma', 'Changer de langue'), 
                           style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          showLanguageSwitcher(Navigator.of(context).context, ref);
                        });
                      },
                    ),

                    const SizedBox(height: 24),
                    // Lyrics Settings
                    _buildSectionHeader(notifier.t('إعدادات المزامنة', 'Lyrics Settings', 'Configurações de Letras', 'Paramètres des paroles')),
                    _buildSliderTile(
                      title: notifier.t('حجم الخط', 'Font Size', 'Tamanho da Fonte', 'Taille de police'),
                      value: settings.lyricsFontSize,
                      min: 14,
                      max: 60,
                      onChanged: (val) => settingsNotifier.setLyricsFontSize(val),
                    ),
                    ListTile(
                      title: Text(notifier.t('نمط الظهور', 'Display Mode', 'Modo de Exibição', 'Mode d\'affichage'),
                           style: TextStyle(color: AppColors.textPrimary)),
                      trailing: DropdownButton<LyricsDisplayMode>(
                        dropdownColor: AppColors.surface,
                        value: settings.lyricsDisplayMode,
                        items: [
                          DropdownMenuItem(value: LyricsDisplayMode.consecutive, child: Text(notifier.t('قائمة متتالية', 'Consecutive', 'Consecutivo', 'Consécutif'), style: TextStyle(color: AppColors.textPrimary))),
                          DropdownMenuItem(value: LyricsDisplayMode.onlyCurrent, child: Text(notifier.t('الآية الحالية فقط', 'Current Only', 'Apenas Atual', 'Actuel uniquement'), style: TextStyle(color: AppColors.textPrimary))),
                        ],
                        onChanged: (val) => settingsNotifier.setLyricsDisplayMode(val!),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Playback
                    _buildSectionHeader(notifier.t('إعدادات التشغيل', 'Playback Settings', 'Configurações de Reprodução', 'Paramètres de lecture')),
                    SwitchListTile(
                      title: Text(notifier.t('منع إغلاق الشاشة', 'Wake Lock', 'Bloqueio de Despertar', 'Verrouillage du réveil'),
                           style: TextStyle(color: AppColors.textPrimary)),
                      value: settings.isWakeLockEnabled,
                      activeThumbColor: AppColors.gold,
                      onChanged: (val) => settingsNotifier.setWakeLock(val),
                    ),
                    ListTile(
                      title: Text(notifier.t('مؤقت النوم', 'Sleep Timer', 'Temporizador', 'Minuteur de mise en veille'),
                           style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: playerState.sleepTimerRemaining != null
                        ? Text('${playerState.sleepTimerRemaining! ~/ 60}m remaining', style: const TextStyle(color: AppColors.gold))
                        : null,
                      trailing: const Icon(Icons.timer, color: AppColors.gold),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppColors.surface,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (context) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(title: Text(notifier.t('إيقاف المؤقت', 'Stop Timer', 'Parar', 'Arrêter'), textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary)), onTap: () { playerNotifier.setSleepTimer(null); Navigator.pop(context); }),
                              ListTile(title: Text(notifier.t('بعد نهاية السورة', 'After Current Surah', 'Após Surata Atual', 'Après la sourate actuelle'), textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary)), onTap: () { playerNotifier.setSleepTimer(null, stopAfterCurrent: true); Navigator.pop(context); }),
                              ListTile(title: Text('15m', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary)), onTap: () { playerNotifier.setSleepTimer(15); Navigator.pop(context); }),
                              ListTile(title: Text('30m', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary)), onTap: () { playerNotifier.setSleepTimer(30); Navigator.pop(context); }),
                              ListTile(title: Text('60m', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary)), onTap: () { playerNotifier.setSleepTimer(60); Navigator.pop(context); }),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    // High Quality & Tools
                    _buildSectionHeader(notifier.t('خيارات إضافية', 'Additional Options', 'Opções Adicionais', 'Options supplémentaires')),
                    SwitchListTile(
                      title: Text(notifier.t('نمط الجودة العالية', 'High Quality Mode', 'Modo Alta Qualidade', 'Mode Haute Qualité'), style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text(notifier.t('تحسين معالجة الصوت', 'Enhanced audio processing', 'Melhor processamento', 'Traitement sonore amélioré'), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      value: true, 
                      activeThumbColor: Colors.cyanAccent,
                      onChanged: (val) {},
                    ),
                    ListTile(
                      title: Text(notifier.t('حجم ذاكرة التخزين المؤقت', 'Buffer Size', 'Tamanho do Buffer', 'Taille du cache'), style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text(notifier.t('لضمان تشغيل أسلس', 'For smoother playback', 'Para reprodução suave', 'Pour une lecture fluide'), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      trailing: const Text('512 KB', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(title, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
  );
}

Widget _buildSliderTile({required String title, required double value, required double min, required double max, required Function(double) onChanged}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      ),
      Slider(
        value: value,
        min: min,
        max: max,
        activeColor: AppColors.gold,
        inactiveColor: AppColors.muted,
        onChanged: onChanged,
      ),
    ],
  );
}

void showStatisticsBottomSheet(BuildContext context, WidgetRef ref) {
  final notifier = ref.read(languageProvider.notifier);
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, ref, child) {
              ref.watch(languageProvider);
              final stats = ref.watch(statisticsProvider);
              final hours = stats.totalListeningSeconds ~/ 3600;
              final minutes = (stats.totalListeningSeconds % 3600) ~/ 60;
              
              final now = DateTime.now();
              final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
              final todaySeconds = stats.dailyListening[dateKey] ?? 0;
              final todayMins = todaySeconds ~/ 60;
              
              final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
              final monthSeconds = stats.monthlyListening[monthKey] ?? 0;
              final monthHours = monthSeconds ~/ 3600;

              return Container(
                padding: const EdgeInsets.all(24),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 16),
                    Text(notifier.t('إحصائيات الاستماع', 'Listening Stats', 'Estatísticas', 'Statistiques'), style: GoogleFonts.amiri(fontSize: 24, color: AppColors.gold, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard('شعلة الاستمرار', '${stats.currentStreak} يوم 🔥', Icons.local_fire_department, Colors.orange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard('اليوم', '$todayMins دقيقة', Icons.today, Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard('الشهر الحالي', '$monthHours ساعة', Icons.calendar_month, Colors.purple),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard('الإجمالي', '$hours ساعة', Icons.headphones, AppColors.gold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    Text(notifier.t('الأوسمة والإنجازات 🏆', 'Badges & Achievements 🏆', 'Emblemas 🏆', 'Badges 🏆'), 
                         style: GoogleFonts.amiri(fontSize: 20, color: AppColors.textPrimary, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildBadge(notifier.t('الخطوة الأولى', 'First Step', 'Primeiro Passo', 'Premier Pas'), 'first_step', stats.unlockedBadges.contains('first_step'), Icons.directions_walk),
                        _buildBadge(notifier.t('المثابر', 'Consistent', 'Consistente', 'Constant'), 'consistent', stats.unlockedBadges.contains('consistent'), Icons.auto_graph),
                        _buildBadge(notifier.t('العادة القرآنية', 'Habit Builder', 'Hábito', 'Habitude'), 'habit_builder', stats.unlockedBadges.contains('habit_builder'), Icons.diamond),
                        _buildBadge(notifier.t('قارئ الليل', 'Night Owl', 'Noturno', 'Oiseau de nuit'), 'night_owl', stats.unlockedBadges.contains('night_owl'), Icons.nights_stay),
                        _buildBadge(notifier.t('مستمع الفجر', 'Dawn Seeker', 'Madrugada', 'Chercheur d\'aube'), 'dawn_seeker', stats.unlockedBadges.contains('dawn_seeker'), Icons.wb_sunny),
                        _buildBadge(notifier.t('الصاحب المخلص', 'Devoted', 'Devotado', 'Dévoué'), 'devoted', stats.unlockedBadges.contains('devoted'), Icons.favorite),
                        _buildBadge(notifier.t('حارس الذكر', 'Guardian', 'Guardião', 'Gardien'), 'guardian', stats.unlockedBadges.contains('guardian'), Icons.shield),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _buildStatCard(String title, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    ),
  );
}

Widget _buildBadge(String name, String id, bool unlocked, IconData icon) {
  final color = unlocked ? AppColors.gold : Colors.grey;
  return Container(
    width: 100,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: unlocked ? AppColors.gold.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(name, style: TextStyle(color: unlocked ? AppColors.textPrimary : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ],
    ),
  );
}

void showLanguageSwitcher(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyanAccent, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const ReaderImage(isCircle: true),
          ),
          ListTile(title: Text('العربية', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)), onTap: () { ref.read(languageProvider.notifier).setLanguage('ar'); Navigator.pop(context); }),
          ListTile(title: Text('English', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)), onTap: () { ref.read(languageProvider.notifier).setLanguage('en'); Navigator.pop(context); }),
          ListTile(title: Text('Português', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)), onTap: () { ref.read(languageProvider.notifier).setLanguage('pt'); Navigator.pop(context); }),
          ListTile(title: Text('Français', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)), onTap: () { ref.read(languageProvider.notifier).setLanguage('fr'); Navigator.pop(context); }),
        ],
      ),
    ),
  );
}
