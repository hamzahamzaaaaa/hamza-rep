import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/language_provider.dart';
import '../widgets/surah_item.dart';
import '../widgets/mini_player.dart';

class AllSurahsPage extends ConsumerStatefulWidget {
  final List<Surah> allSurahs;
  final String title;

  const AllSurahsPage({
    super.key,
    required this.allSurahs,
    required this.title,
  });

  @override
  ConsumerState<AllSurahsPage> createState() => _AllSurahsPageState();
}

class _AllSurahsPageState extends ConsumerState<AllSurahsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Surah> _filteredSurahs = [];

  @override
  void initState() {
    super.initState();
    _filteredSurahs = widget.allSurahs;
  }

  void _filterSurahs(String query) {
    setState(() {
      _filteredSurahs = widget.allSurahs.where((surah) {
        final arName = surah.name.toLowerCase();
        final enName = ref.read(languageProvider.notifier).translateSurahName(surah.name).toLowerCase();
        return arName.contains(query.toLowerCase()) || enName.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: GoogleFonts.amiri(
            color: AppColors.gold,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterSurahs,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: ref.read(languageProvider.notifier).t('بحث عن سورة...', 'Search Surah...', 'Pesquisar...', 'Rechercher...'),
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _filteredSurahs.length,
                  itemBuilder: (context, index) {
                    final surah = _filteredSurahs[index];
                    final isPlaying = playerState.currentSurah?.id == surah.id && playerState.isPlaying;

                    return SurahItem(
                      key: ValueKey(surah.id),
                      surah: surah,
                      index: index,
                      isPlaying: isPlaying,
                      onTap: () => ref.read(playerProvider.notifier).playSurah(surah, _filteredSurahs),
                    );
                  },
                ),
              ),
            ],
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}
