import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/download_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/collection_provider.dart';
import 'pulsing_download_icon.dart';

class PlayDownloadAllBar extends ConsumerWidget {
  final List<Surah> surahs;
  final String category;

  const PlayDownloadAllBar({
    super.key,
    required this.surahs,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(languageProvider.notifier);

    if (surahs.isEmpty) return const SizedBox.shrink();

    // Check if any surahs in the list are not yet downloaded
    final downloads = ref.watch(downloadProvider);
    final hasPending = surahs.any((s) => !(downloads.items[s.id]?.isCompleted ?? false));
    
    final collection = ref.watch(collectionProvider);
    final isAllFavorite = surahs.every((s) => collection.favorites.contains(s.id));
    final isAllListenLater = surahs.every((s) => collection.listenLater.contains(s.id));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute icons evenly
        children: [
          _buildActionButton(
            icon: Icons.play_circle_filled,
            tooltip: notifier.t('استماع للجميع', 'Play All', 'Ouvir Tudo', 'Écouter Tout'),
            onPressed: () {
              if (surahs.isNotEmpty) {
                ref.read(playerProvider.notifier).playSurah(surahs.first, surahs);
              }
            },
          ),
          _buildActionButton(
            icon: hasPending ? null : Icons.check_circle,
            customIcon: hasPending ? const PulsingDownloadIcon(size: 26) : null,
            color: hasPending ? AppColors.gold : Colors.green.withValues(alpha: 0.7),
            tooltip: hasPending 
                  ? notifier.t('تحميل الكل', 'Download All', 'Baixar Tudo', 'Télécharger tout')
                  : notifier.t('تم تحميل الكل', 'All Downloaded', 'Tudo Baixado', 'Tout téléchargé'),
            onPressed: hasPending
                ? () {
                    if (surahs.isNotEmpty) {
                      ref.read(downloadProvider.notifier).downloadAll(surahs, category: category);
                    }
                  }
                : null,
          ),
          _buildActionButton(
            icon: isAllFavorite ? Icons.favorite : Icons.favorite_border,
            tooltip: notifier.t('إضافة الكل للمفضلة', 'Favorite All', 'Favoritar Todos', 'Favoris tout'),
            onPressed: () {
              ref.read(collectionProvider.notifier).addAllToFavorites(surahs.map((s) => s.id).toList());
            },
          ),
          _buildActionButton(
            icon: isAllListenLater ? Icons.watch_later : Icons.watch_later_outlined,
            tooltip: notifier.t('الاستماع للكل لاحقاً', 'Listen All Later', 'Ouvir Todos Depois', 'Écouter tout plus tard'),
            onPressed: () {
              ref.read(collectionProvider.notifier).addAllToListenLater(surahs.map((s) => s.id).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    Widget? customIcon,
    Color? color,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: customIcon ?? Icon(icon, color: color ?? AppColors.gold, size: 26),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }
}
