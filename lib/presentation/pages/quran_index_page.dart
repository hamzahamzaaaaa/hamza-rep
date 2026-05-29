import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/content_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/collection_provider.dart';
import '../widgets/surah_item.dart';
import '../widgets/mini_player.dart';

class QuranIndexPage extends ConsumerStatefulWidget {
  const QuranIndexPage({super.key});

  @override
  ConsumerState<QuranIndexPage> createState() => _QuranIndexPageState();
}

class _QuranIndexPageState extends ConsumerState<QuranIndexPage> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'all'; // 'all', 'favorites', 'later'

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(languageProvider.notifier);
    final playerState = ref.watch(playerProvider);
    final contentState = ref.watch(contentProvider);
    final collectionState = ref.watch(collectionProvider);

    // Use the remote Quran list if it's available, otherwise fallback to surahList
    final fullList = contentState.quranKareemRemote.isNotEmpty
        ? contentState.quranKareemRemote
        : surahList;

    // Filter logic
    final filteredSurahs = fullList.where((surah) {
      // Search filter
      final query = _searchController.text.toLowerCase();
      bool matchesSearch = true;
      if (query.isNotEmpty) {
        final nameAr = surah.name.toLowerCase();
        final nameTranslated = notifier.translateSurahName(surah.name).toLowerCase();
        matchesSearch = nameAr.contains(query) || nameTranslated.contains(query);
      }

      if (!matchesSearch) return false;

      // Category filter
      if (_activeFilter == 'favorites') {
        return collectionState.favorites.contains(surah.id);
      } else if (_activeFilter == 'later') {
        return collectionState.listenLater.contains(surah.id);
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          notifier.t('القرآن الكريم', 'The Holy Quran', 'O Alcorão Sagrado', 'Le Saint Coran'),
          style: GoogleFonts.amiri(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: notifier.t('بحث عن سورة...', 'Search Surah...', 'Pesquisar...', 'Rechercher...'),
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: notifier.t('الكل', 'All', 'Tudo', 'Tout'),
                      filter: 'all',
                      icon: Icons.list,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: notifier.t('المفضلة', 'Favorites', 'Favoritos', 'Favoris'),
                      filter: 'favorites',
                      icon: Icons.favorite,
                      count: collectionState.favorites.length,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: notifier.t('الاستماع لاحقاً', 'Listen Later', 'Ouvir Depois', 'Écouter plus tard'),
                      filter: 'later',
                      icon: Icons.watch_later,
                      count: collectionState.listenLater.length,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredSurahs.isEmpty
                    ? _buildEmptyState(notifier)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: filteredSurahs.length,
                        itemBuilder: (context, index) {
                          final surah = filteredSurahs[index];
                          return SurahItem(
                            key: ValueKey(surah.id),
                            surah: surah,
                            index: index,
                            isPlaying: playerState.currentSurah?.id == surah.id && playerState.isPlaying,
                            onTap: () => ref.read(playerProvider.notifier).playSurah(surah, filteredSurahs),
                          );
                        },
                      ),
              ),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String filter, required IconData icon, int? count}) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.gold : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.gold : AppColors.muted.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.backgroundDefault : AppColors.gold,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.backgroundDefault : Colors.white,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.backgroundDefault.withOpacity(0.2) : AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isActive ? AppColors.backgroundDefault : AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(LanguageNotifier notifier) {
    String message = '';
    IconData icon = Icons.search_off;

    if (_activeFilter == 'favorites') {
      message = notifier.t('لا توجد سور في المفضلة', 'No favorite surahs yet', 'Nenhuma surah favorita ainda', 'Aucune sourate favorite encore');
      icon = Icons.favorite_border;
    } else if (_activeFilter == 'later') {
      message = notifier.t('قائمة الاستماع لاحقاً فارغة', 'Listen later list is empty', 'Lista de ouvir depois está vazia', 'La liste à écouter plus tard est vide');
      icon = Icons.watch_later_outlined;
    } else {
      message = notifier.t('لم يتم العثور على نتائج', 'No results found', 'Nenhum resultado encontrado', 'Aucun résultat trouvé');
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.muted.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
