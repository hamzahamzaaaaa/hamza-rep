import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/surah.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/player_provider.dart';

class QuickIndexOverlay extends ConsumerStatefulWidget {
  final List<Surah> surahs;
  final Function(Surah) onSurahSelected;
  final VoidCallback onClose;

  const QuickIndexOverlay({
    super.key,
    required this.surahs,
    required this.onSurahSelected,
    required this.onClose,
  });

  @override
  ConsumerState<QuickIndexOverlay> createState() => _QuickIndexOverlayState();
}

class _QuickIndexOverlayState extends ConsumerState<QuickIndexOverlay>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _slideController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(languageProvider.notifier);
    final playerState = ref.watch(playerProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    final filtered = _searchQuery.isEmpty
        ? widget.surahs
        : widget.surahs
            .where((s) => s.name.contains(_searchQuery))
            .toList();

    return Positioned.fill(
      child: GestureDetector(
        onTap: _dismiss,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.1),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {}, // Prevent dismissal when tapping inside
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    height: screenHeight * 0.75,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.15),
                        width: 1.0,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Column(
                          children: [
                            // Handle bar
                            const SizedBox(height: 12),
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        color: Colors.white60, size: 22),
                                    onPressed: _dismiss,
                                  ),
                                  Text(
                                    notifier.t(
                                      'فهرس السور',
                                      'Surah Index',
                                      'Índice de Suras',
                                      'Index des Sourates',
                                    ),
                                    style: GoogleFonts.amiri(
                                      fontSize: 22,
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),

                            // Search Bar
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.gold.withOpacity(0.2),
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.amiri(
                                      color: Colors.white, fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: notifier.t(
                                      'ابحث عن سورة...',
                                      'Search surah...',
                                      'Pesquisar...',
                                      'Rechercher...',
                                    ),
                                    hintStyle: GoogleFonts.amiri(
                                        color: Colors.white38),
                                    prefixIcon: const Icon(Icons.search,
                                        color: AppColors.gold, size: 20),
                                    border: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 16),
                                  ),
                                  onChanged: (value) {
                                    setState(() => _searchQuery = value);
                                  },
                                ),
                              ),
                            ),

                            // Surah List
                            Expanded(
                              child: filtered.isEmpty
                                  ? Center(
                                      child: Text(
                                        notifier.t('لا توجد نتائج', 'No results',
                                            'Sem resultados', 'Aucun résultat'),
                                        style: const TextStyle(
                                            color: Colors.white38),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 32),
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, __) => Divider(
                                        color: Colors.white.withOpacity(0.06),
                                        height: 1,
                                        indent: 16,
                                        endIndent: 16,
                                      ),
                                      itemBuilder: (context, index) {
                                        final surah = filtered[index];
                                        final isPlaying =
                                            playerState.currentSurah?.id ==
                                                surah.id;
                                        return _SurahTile(
                                          surah: surah,
                                          isPlaying: isPlaying,
                                          isActuallyPlaying:
                                              isPlaying && playerState.isPlaying,
                                          onTap: () =>
                                              widget.onSurahSelected(surah),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Surah tile with animated equalizer ─────────────────────────────────────
class _SurahTile extends StatelessWidget {
  final Surah surah;
  final bool isPlaying;
  final bool isActuallyPlaying;
  final VoidCallback onTap;

  const _SurahTile({
    required this.surah,
    required this.isPlaying,
    required this.isActuallyPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.gold.withOpacity(0.08),
        highlightColor: AppColors.gold.withOpacity(0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isPlaying
                ? AppColors.gold.withOpacity(0.07)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Trailing: active indicator or index number
              SizedBox(
                width: 36,
                child: isPlaying
                    ? _EqualizerIcon(isAnimating: isActuallyPlaying)
                    : const SizedBox.shrink(),
              ),
              // Title
              Expanded(
                child: Text(
                  surah.name,
                  style: GoogleFonts.amiri(
                    color: isPlaying
                        ? AppColors.gold
                        : Colors.white.withOpacity(0.85),
                    fontSize: 19,
                    fontWeight:
                        isPlaying ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              // Leading: dot or space
              SizedBox(
                width: 10,
                child: isPlaying
                    ? Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.6),
                              blurRadius: 6,
                            )
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated Equalizer bars ─────────────────────────────────────────────────
class _EqualizerIcon extends StatefulWidget {
  final bool isAnimating;
  const _EqualizerIcon({required this.isAnimating});

  @override
  State<_EqualizerIcon> createState() => _EqualizerIconState();
}

class _EqualizerIconState extends State<_EqualizerIcon>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final duration = Duration(milliseconds: 300 + _random.nextInt(300));
      final controller = AnimationController(
        vsync: this,
        duration: duration,
      );
      final animation = Tween<double>(begin: 0.15, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
      _controllers.add(controller);
      _animations.add(animation);
    }
    _updateAnimation();
  }

  void _updateAnimation() {
    for (var c in _controllers) {
      if (widget.isAnimating) {
        c.repeat(reverse: true);
      } else {
        c.animateTo(0.3);
      }
    }
  }

  @override
  void didUpdateWidget(_EqualizerIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAnimating != widget.isAnimating) {
      _updateAnimation();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, _) {
              return Container(
                width: 4,
                height: 20 * _animations[i].value,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.5),
                      blurRadius: 4,
                    )
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
