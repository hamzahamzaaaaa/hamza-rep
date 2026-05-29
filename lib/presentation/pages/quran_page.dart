import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/content_provider.dart';
import '../../core/providers/player_provider.dart';
import '../widgets/surah_item.dart';
import '../widgets/global_search.dart';
import 'all_surahs_page.dart';
import '../widgets/play_download_all_bar.dart';

class QuranPage extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;
  const QuranPage({super.key, this.onNavigate});

  @override
  ConsumerState<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends ConsumerState<QuranPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(languageProvider.notifier);
    final content = ref.watch(contentProvider);
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        toolbarHeight: 10, // Reduce app bar height to shift content up
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.gold),
                onPressed: () {
                  final notifier = ref.read(languageProvider.notifier);
                  final content = ref.read(contentProvider);

                  List<Surah> currentScope = [];
                  String hint = "";

                  switch (_tabController.index) {
                    case 0:
                      currentScope = surahList;
                      hint = notifier.t('ابحث في المصحف', 'Search in Quran', 'Pesquisar no Alcorão', 'Chercher dans le Coran');
                      break;
                    case 1:
                      currentScope = [
                        ...content.telawat2018, ...content.telawat2020, ...content.telawat2022,
                        ...content.telawat2023, ...content.telawat2024, ...content.telawat2025,
                        ...content.telawat2026, ...content.telawat2026Local
                      ];
                      hint = notifier.t('ابحث في التلاوات', 'Search in Recitations', 'Pesquisar em Recitações', 'Chercher dans les Récitations');
                      break;
                    case 2:
                      currentScope = content.azkar;
                      hint = notifier.t('ابحث في الأذكار', 'Search in Azkar', 'Pesquisar em Azkar', 'Chercher dans les Azkar');
                      break;
                    case 3:
                      currentScope = content.doae;
                      hint = notifier.t('ابحث في الأدعية', 'Search in Dua', 'Pesquisar em Dua', 'Chercher dans les Dua');
                      break;
                    default:
                      currentScope = [];
                  }

                  showSearch(
                    context: context,
                    delegate: GlobalSearchDelegate(
                      ref: ref,
                      customHint: hint,
                      scope: currentScope.isNotEmpty ? currentScope : null,
                    ),
                  );
                },
              ),
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppColors.gold,
                  labelColor: AppColors.gold,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(text: notifier.t('القرآن', 'Quran', 'Alcorão', 'Coran')),
                    Tab(text: notifier.t('التلاوات', 'Recitations', 'Recitações', 'Récitations')),
                    Tab(text: notifier.t('الأذكار', 'Azkar', 'Azkar', 'Azkar')),
                    Tab(text: notifier.t('الأدعية', 'Dua', 'Dua', 'Dua')),
                    Tab(text: notifier.t('الأناشيد', 'Anashid', 'Anashid', 'Anashid')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 1. Holy Quran
          _buildAllSurahsList(surahList, playerState, "القرآن الكريم"),

          // 2. Yearly Recitations
          _buildYearlyGrid(context, content),

          // 3. Azkar
          _buildAllSurahsList(content.azkar, playerState, "الأذكار"),

          // 4. Doae
          _buildAllSurahsList(content.doae, playerState, "الأدعية"),

          // 5. Anashid
          _buildAnashidYearlyGrid(context, content),
        ],
      ),
    );
  }

  Widget _buildAnashidYearlyGrid(BuildContext context, ContentState content) {
    final years = [
      {'year': '2018', 'list': content.anashid2018, 'img': 'assets/images/reader.jpg'},
      {'year': '2019', 'list': content.anashid2019, 'img': 'assets/images/reader.jpg'},
      {'year': '2020', 'list': content.anashid2020, 'img': 'assets/images/reader.jpg'},
      {'year': '2022', 'list': content.anashid2022, 'img': 'assets/images/reader.jpg'},
      {'year': '2023', 'list': content.anashid2023, 'img': 'assets/images/reader.jpg'},
      {'year': '2024', 'list': content.anashid2024, 'img': 'assets/images/reader.jpg'},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.1,
      ),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final item = years[index];
        final list = item['list'] as List<Surah>;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllSurahsPage(
                  title: 'أناشيد من سنة ${item['year']}',
                  allSurahs: list,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              image: DecorationImage(
                image: AssetImage(item['img'] as String),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['year'] as String,
                    style: GoogleFonts.amiri(
                      color: AppColors.gold,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'أناشيد من',
                    style: GoogleFonts.amiri(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllSurahsList(List<Surah> list, dynamic playerState, String category) {
    if (list.isEmpty) return const Center(child: CircularProgressIndicator(color: AppColors.gold));

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: PlayDownloadAllBar(surahs: list, category: category),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 10),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final surah = list[index];
              final isPlaying = playerState.currentSurah?.id == surah.id && playerState.isPlaying;
              return SurahItem(
                key: ValueKey(surah.id),
                surah: surah,
                index: index,
                isPlaying: isPlaying,
                onTap: () => ref.read(playerProvider.notifier).playSurah(surah, list),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildYearlyGrid(BuildContext context, ContentState content) {
    final years = [
      {'year': '2018', 'list': content.telawat2018, 'img': 'assets/images/reader.jpg', 'subtitle': 'تلاوات من', 'title': 'تلاوات من سنة 2018'},
      {'year': '2018', 'list': content.telawat2022, 'img': 'assets/images/reader.jpg', 'subtitle': 'سور', 'title': 'تسجيلات سور 2018'},
      {'year': '2019', 'list': content.telawat2019, 'img': 'assets/images/reader.jpg', 'subtitle': 'تلاوات من', 'title': 'تلاوات من سنة 2019'},
      {'year': '2020', 'list': content.telawat2020, 'img': 'assets/images/reader.jpg', 'subtitle': 'تلاوات من', 'title': 'تلاوات من سنة 2020'},
      {'year': '2023', 'list': content.telawat2023, 'img': 'assets/images/reader.jpg', 'subtitle': 'تلاوات من', 'title': 'تلاوات من سنة 2023'},
      {'year': '2024', 'list': content.telawat2024, 'img': 'assets/images/reader.jpg', 'subtitle': 'تلاوات من', 'title': 'تلاوات من سنة 2024'},
      {'year': '2025', 'list': content.telawat2025, 'img': 'assets/images/reader.jpg', 'subtitle': 'تلاوات من', 'title': 'تلاوات من سنة 2025'},
      {'year': '2026', 'list': content.telawat2026, 'img': 'assets/images/reader.jpg', 'subtitle': 'تلاوات من', 'title': 'تلاوات من سنة 2026'},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.1,
      ),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final item = years[index];
        final list = item['list'] as List<Surah>;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllSurahsPage(
                  title: item['title'] as String,
                  allSurahs: list,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              image: DecorationImage(
                image: AssetImage(item['img'] as String),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['year'] as String,
                    style: GoogleFonts.amiri(
                      color: AppColors.gold,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item['subtitle'] as String,
                    style: GoogleFonts.amiri(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
