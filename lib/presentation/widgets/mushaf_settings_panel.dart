import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/advanced_settings_provider.dart';
import '../../core/constants/colors.dart';
import 'glassmorphism_theme.dart';

/// ============================================================================
/// MUSHAF SETTINGS PANEL - COMPREHENSIVE GLASSMORPHISM UI
/// ============================================================================
/// 
/// Features:
/// - LRC font size settings (default 32, adjustable)
/// - Visual Mushaf themes (White, Sepia, Dark, Smart Dark)
/// - Screen dimming slider
/// - Zoom controls
/// - Arabic font customization with preview
/// - Font color selection
/// - Smart Dark Mode with blue light filter
/// - Active Word Glow toggle
/// - Cloud Sync option
/// - Live preview on all changes
/// - SharedPreferences persistence

void showMushafSettingsPanel(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const MushafSettingsPanel(),
  );
}

class MushafSettingsPanel extends ConsumerWidget {
  final Color? currentPaperColor;
  final double? currentFontSize;
  final String? currentFontName;
  final double? currentOpacity;
  final Function(Color)? onPaperColorChanged;
  final Function(double)? onFontSizeChanged;
  final Function(String)? onFontNameChanged;
  final Function(double)? onOpacityChanged;

  const MushafSettingsPanel({
    super.key,
    this.currentPaperColor,
    this.currentFontSize,
    this.currentFontName,
    this.currentOpacity,
    this.onPaperColorChanged,
    this.onFontSizeChanged,
    this.onFontNameChanged,
    this.onOpacityChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(advancedSettingsProvider);
    final notifier = ref.read(advancedSettingsProvider.notifier);

    // Check if using custom callbacks (from SmartMushafPage)
    final useCustomCallbacks = onPaperColorChanged != null || onFontSizeChanged != null;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A141F).withOpacity(0.95),
                const Color(0xFF2D1B3D).withOpacity(0.9),
                const Color(0xFF1A141F).withOpacity(0.95),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: AppColors.gold.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories, color: AppColors.gold, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'إعدادات المصحف',
                    style: GoogleFonts.amiri(
                      fontSize: 24,
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Mushaf Settings',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),

              // Settings content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Section 1: Paper Color (for SmartMushafPage)
                    if (useCustomCallbacks) ...[
                      _buildSectionTitle('لون الورق', 'Paper Color'),
                      const SizedBox(height: 12),
                      _buildPaperColorSelector(),
                      const SizedBox(height: 24),
                    ],

                    // Section 2: Font Size
                    _buildSectionTitle(
                      useCustomCallbacks ? 'حجم الخط' : 'حجم خط المزامنة',
                      useCustomCallbacks ? 'Font Size' : 'LRC Font Size',
                    ),
                    const SizedBox(height: 12),
                    if (useCustomCallbacks)
                      _buildCustomFontSizeSlider()
                    else
                      _buildFontSizeSlider(ref, notifier),
                    const SizedBox(height: 24),

                    // Section 3: Font Selection
                    _buildSectionTitle('الخط العربي', 'Arabic Font'),
                    const SizedBox(height: 12),
                    if (useCustomCallbacks)
                      _buildCustomFontSelector()
                    else
                      _buildArabicFontSelector(ref, notifier),
                    const SizedBox(height: 24),

                    // Section 4: Opacity (for SmartMushafPage)
                    if (useCustomCallbacks) ...[
                      _buildSectionTitle('التعتيم', 'Opacity'),
                      const SizedBox(height: 12),
                      _buildCustomOpacitySlider(),
                      const SizedBox(height: 24),
                    ],

                    // Original sections (only when not using custom callbacks)
                    if (!useCustomCallbacks) ...[
                      // Mushaf Theme
                      _buildSectionTitle('ثيم المصحف', 'Mushaf Theme'),
                      const SizedBox(height: 12),
                      _buildMushafThemeSelector(ref, notifier),
                      const SizedBox(height: 24),

                      // Screen Dimming
                      _buildSectionTitle('تعتيم الشاشة', 'Screen Dimming'),
                      const SizedBox(height: 12),
                      _buildDimmingSlider(ref, notifier),
                      const SizedBox(height: 24),

                      // Zoom Level
                      _buildSectionTitle('تكبير الشاشة', 'Zoom Level'),
                      const SizedBox(height: 12),
                      _buildZoomSlider(ref, notifier),
                      const SizedBox(height: 24),

                      // Font Color
                      _buildSectionTitle('لون الخط', 'Font Color'),
                      const SizedBox(height: 12),
                      _buildFontColorSelector(ref, notifier),
                      const SizedBox(height: 24),

                      // Smart Dark Mode
                      _buildSectionTitle('الوضع الليلي الذكي', 'Smart Dark Mode'),
                      const SizedBox(height: 12),
                      _buildSmartDarkModeToggle(ref, notifier),
                      const SizedBox(height: 12),
                      _buildBlueLightFilterSlider(ref, notifier),
                      const SizedBox(height: 24),

                      // Active Word Glow
                      _buildSectionTitle('توهج الكلمة النشطة', 'Active Word Glow'),
                      const SizedBox(height: 12),
                      _buildActiveWordGlowToggle(ref, notifier),
                      const SizedBox(height: 24),

                      // Cloud Sync
                      _buildSectionTitle('المزامنة السحابية', 'Cloud Sync'),
                      const SizedBox(height: 12),
                      _buildCloudSyncToggle(ref, notifier),
                      const SizedBox(height: 30),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // SECTION BUILDERS
  // ============================================================================

  Widget _buildSectionTitle(String arabicTitle, String englishTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          arabicTitle,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          englishTitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الحجم الحالي',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                ),
                child: Text(
                  '${settings.lyricsFontSize.toInt()}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: settings.lyricsFontSize,
            min: 16.0,
            max: 48.0,
            divisions: 16,
            activeColor: AppColors.gold,
            inactiveColor: Colors.white.withOpacity(0.2),
            onChanged: (v) => notifier.setLyricsFontSize(v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('16', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              Text('32 (افتراضي)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              Text('48', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMushafThemeSelector(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildThemeOption(
                'أبيض',
                'White',
                Colors.white,
                MushafTheme.white,
                settings.mushafTheme,
                () => notifier.setMushafTheme(MushafTheme.white),
              ),
              _buildThemeOption(
                'سيبيا',
                'Sepia',
                const Color(0xFFF4E4C1),
                MushafTheme.sepia,
                settings.mushafTheme,
                () => notifier.setMushafTheme(MushafTheme.sepia),
              ),
              _buildThemeOption(
                'أسود',
                'Dark',
                const Color(0xFF1A1A1A),
                MushafTheme.dark,
                settings.mushafTheme,
                () => notifier.setMushafTheme(MushafTheme.dark),
              ),
              _buildThemeOption(
                'ذكي',
                'Smart',
                const Color(0xFF0D1117),
                MushafTheme.smartDark,
                settings.mushafTheme,
                () => notifier.setMushafTheme(MushafTheme.smartDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    String arabicName,
    String englishName,
    Color color,
    MushafTheme theme,
    MushafTheme currentTheme,
    VoidCallback onTap,
  ) {
    final isSelected = theme == currentTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              arabicName,
              style: TextStyle(
                color: isSelected ? AppColors.gold : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              englishName,
              style: TextStyle(
                color: isSelected ? AppColors.gold.withOpacity(0.8) : Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimmingSlider(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مستوى التعتيم',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
              Text(
                '${(settings.dimLevel * 100).toInt()}%',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: settings.dimLevel,
            min: 0.0,
            max: 0.7,
            divisions: 14,
            activeColor: AppColors.gold,
            inactiveColor: Colors.white.withOpacity(0.2),
            onChanged: (v) => notifier.setDimLevel(v),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomSlider(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مستوى التكبير',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
              Text(
                '${settings.mushafZoomLevel.toStringAsFixed(1)}x',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: settings.mushafZoomLevel,
            min: 1.0,
            max: 3.0,
            divisions: 20,
            activeColor: AppColors.gold,
            inactiveColor: Colors.white.withOpacity(0.2),
            onChanged: (v) => notifier.setMushafZoomLevel(v),
          ),
        ],
      ),
    );
  }

  Widget _buildArabicFontSelector(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return GlassCard(
      child: Column(
        children: ArabicFont.values.map((font) {
          final isSelected = font == settings.arabicFont;
          final fontFamily = notifier.getFontFamilyName(font);

          return GestureDetector(
            onTap: () => notifier.setArabicFont(font),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check_circle, color: AppColors.gold, size: 20),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بسم الله الرحمن الرحيم',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 24,
                            color: isSelected ? AppColors.gold : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fontFamily,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.gold.withOpacity(0.8)
                                : Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFontColorSelector(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: FontColor.values.map((color) {
          final isSelected = color == settings.fontColor;
          final colorValue = notifier.getFontColorValue(color);
          final actualColor = Color(int.parse(colorValue.replaceFirst('#', '0xFF')));

          return GestureDetector(
            onTap: () => notifier.setFontColor(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: actualColor.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.2),
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: actualColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFontColorName(color),
                    style: TextStyle(
                      color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFontColorName(FontColor color) {
    switch (color) {
      case FontColor.black:
        return 'أسود';
      case FontColor.navy:
        return 'كحلي';
      case FontColor.darkRed:
        return 'أحمر';
      case FontColor.gold:
        return 'ذهبي';
    }
  }

  // Helper method to build paper color selector
  Widget _buildPaperColorSelector() {
    if (onPaperColorChanged == null) return const SizedBox.shrink();

    final colors = [
      ('سيبيا', const Color(0xFFF5E6D3)),
      ('أبيض', const Color(0xFFFFFDF5)),
      ('كريمي', const Color(0xFFFAF0E6)),
      ('داكن', const Color(0xFF2C2C2C)),
    ];

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: colors.map((colorData) {
              final isSelected = currentPaperColor == colorData.$2;
              return GestureDetector(
                onTap: () => onPaperColorChanged!(colorData.$2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorData.$2.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.2),
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorData.$2,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        colorData.$1,
                        style: TextStyle(
                          color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Custom font size slider for SmartMushafPage
  Widget _buildCustomFontSizeSlider() {
    if (onFontSizeChanged == null || currentFontSize == null) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الحجم الحالي',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                ),
                child: Text(
                  '${currentFontSize!.toInt()}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: currentFontSize!,
            min: 20.0,
            max: 48.0,
            divisions: 14,
            activeColor: AppColors.gold,
            inactiveColor: Colors.white.withOpacity(0.2),
            onChanged: onFontSizeChanged!,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('20', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              Text('32 (افتراضي)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              Text('48', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // Custom font selector for SmartMushafPage
  Widget _buildCustomFontSelector() {
    if (onFontNameChanged == null || currentFontName == null) {
      return const SizedBox.shrink();
    }

    final fonts = ['Amiri', 'Cairo', 'Noto Naskh Arabic', 'Scheherazade New'];

    return GlassCard(
      child: Column(
        children: fonts.map((font) {
          final isSelected = currentFontName == font;
          return GestureDetector(
            onTap: () => onFontNameChanged!(font),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check_circle, color: AppColors.gold, size: 20),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      'بسم الله الرحمن الرحيم',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 24,
                        color: isSelected ? AppColors.gold : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Custom opacity slider for SmartMushafPage
  Widget _buildCustomOpacitySlider() {
    if (onOpacityChanged == null || currentOpacity == null) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مستوى التعتيم',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
              Text(
                '${(currentOpacity! * 100).toInt()}%',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: currentOpacity!,
            min: 0.5,
            max: 1.0,
            divisions: 10,
            activeColor: AppColors.gold,
            inactiveColor: Colors.white.withOpacity(0.2),
            onChanged: onOpacityChanged!,
          ),
        ],
      ),
    );
  }

  Widget _buildSmartDarkModeToggle(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return GlassSettingsTile(
      icon: Icons.dark_mode,
      title: 'الوضع الليلي الذكي',
      subtitle: 'تقليل الضوء الأزرق + زجاجي داكن',
      value: settings.smartDarkMode,
      onChanged: (v) => notifier.setSmartDarkMode(v),
    );
  }

  Widget _buildBlueLightFilterSlider(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'فلتر الضوء الأزرق',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
              Text(
                '${(settings.blueLightFilterLevel * 100).toInt()}%',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: settings.blueLightFilterLevel,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            activeColor: AppColors.gold,
            inactiveColor: Colors.white.withOpacity(0.2),
            onChanged: settings.smartDarkMode
                ? (v) => notifier.setBlueLightFilterLevel(v)
                : null,
          ),
          if (!settings.smartDarkMode)
            Text(
              'فعّل الوضع الليلي الذكي أولاً',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveWordGlowToggle(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return GlassSettingsTile(
      icon: Icons.auto_awesome,
      title: 'توهج الكلمة النشطة',
      subtitle: 'تأثير ذهبي متوهج على الكلمة المقروءة',
      value: settings.activeWordGlow,
      onChanged: (v) => notifier.setActiveWordGlow(v),
    );
  }

  Widget _buildCloudSyncToggle(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return GlassSettingsTile(
      icon: Icons.cloud_sync,
      title: 'المزامنة السحابية',
      subtitle: 'حفظ الإعدادات في السحابة',
      value: settings.cloudSyncEnabled,
      onChanged: (v) => notifier.setCloudSyncEnabled(v),
    );
  }
}
