import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/language_provider.dart';
import 'playlists_page.dart';
import 'favorites_page.dart';
import 'listen_later_page.dart';
import 'downloads_page.dart';
import 'short_recitations_page.dart';
import '../../core/providers/statistics_provider.dart';
import '../widgets/settings_sheet.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(languageProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 40,
        title: Text(
          notifier.t('المزيد', 'More', 'Mais', 'Plus'),
          style: GoogleFonts.amiri(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMoreItem(
            context,
            icon: Icons.spa,
            title: notifier.t('تلاوات قصيرة', 'Short Recitations', 'Recitações Curtas', 'Récitations Courtes'),
            subtitle: notifier.t('تلاوات هادئة ومريحة', 'Calm & Relaxing', 'Calmo e Relaxante', 'Calme et Relaxant'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ShortRecitationsPage())),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              final stats = ref.watch(statisticsProvider);
              final hours = stats.totalListeningSeconds ~/ 3600;
              final minutes = (stats.totalListeningSeconds % 3600) ~/ 60;
              return _buildMoreItem(
                context,
                icon: Icons.bar_chart,
                title: notifier.t('إحصائيات الاستماع', 'Listening Stats', 'Estatísticas', 'Statistiques'),
                subtitle: '$hours ساعة $minutes دقيقة',
                onTap: () {
                  showStatisticsBottomSheet(context, ref);
                },
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMoreItem(
            context,
            icon: Icons.playlist_play,
            title: notifier.t('قوائم التشغيل', 'Playlists', 'Playlists', 'Playlists'),
            subtitle: notifier.t('قوائمك المخصصة', 'Your custom lists', 'Suas listas', 'Vos listes'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaylistsPage())),
          ),
          const SizedBox(height: 12),
          _buildMoreItem(
            context,
            icon: Icons.favorite,
            title: notifier.t('المفضلة', 'Favorites', 'Favoritos', 'Favoris'),
            subtitle: notifier.t('المقاطع التي أحببتها', 'Items you liked', 'Itens curtidos', 'Articles aimés'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesPage())),
          ),
          const SizedBox(height: 12),
          _buildMoreItem(
            context,
            icon: Icons.watch_later,
            title: notifier.t('الاستماع لاحقاً', 'Listen Later', 'Ouvir Depois', 'Plus tard'),
            subtitle: notifier.t('مقاطع مؤجلة', 'Items for later', 'Itens para depois', 'Articles pour plus tard'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ListenLaterPage())),
          ),
          const SizedBox(height: 12),
          _buildMoreItem(
            context,
            icon: Icons.storage,
            title: notifier.t('إدارة التخزين', 'Storage Management', 'Gerenciar Armazenamento', 'Gérer le stockage'),
            subtitle: notifier.t('المساحة والملفات', 'Space & Files', 'Espaço e Arquivos', 'Espace et fichiers'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DownloadsPage(onNavigate: (index) {}))),
          ),
          const SizedBox(height: 12),
          _buildMoreItem(
            context,
            icon: Icons.battery_charging_full,
            title: notifier.t('تحسين استهلاك البطارية', 'Battery Optimization', 'Otimização de Bateria', 'Optimisation de la batterie'),
            subtitle: notifier.t('السماح بالعمل في الخلفية', 'Allow background play', 'Permitir em segundo plano', 'Autoriser en arrière-plan'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.gold,
                  content: Text(
                    notifier.t('تحسين استهلاك البطارية مفعل', 'Battery Optimization Enabled', 'Otimização ativada', 'Optimisation activée'),
                    style: const TextStyle(color: AppColors.backgroundDefault, fontWeight: FontWeight.bold)
                  )
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMoreItem(
            context,
            icon: Icons.settings,
            title: notifier.t('الإعدادات', 'Settings', 'Configurações', 'Paramètres'),
            subtitle: notifier.t('اللغة والمظهر', 'Language & Theme', 'Idioma e Tema', 'Langue et thème'),
            onTap: () {
              showSettingsBottomSheet(context, ref);
            },
          ),
        ],
      ),
    );
  }

  // Settings methods extracted to settings_sheet.dart

  Widget _buildMoreItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.gold),
        ),
        title: Text(
          title,
          textAlign: TextAlign.right,
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          subtitle,
          textAlign: TextAlign.right,
          style: const TextStyle(color: AppColors.textSecondaryDefault, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.gold, size: 16),
      ),
    );
  }
}
