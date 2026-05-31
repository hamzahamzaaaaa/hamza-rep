import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/advanced_settings_provider.dart';
import '../../core/constants/colors.dart';
import 'glassmorphism_theme.dart';

/// ============================================================================
/// ENHANCED SYNC SETTINGS BOTTOM SHEET WITH GLASSMORPHISM
/// ============================================================================
/// 
/// Features:
/// - Glassmorphism theme
/// - Background color picker
/// - Zoom controls
/// - Display mode settings
/// - Sync offset adjustment
/// - Font size and color controls
/// - Smooth transitions toggle

void showEnhancedSyncSettings(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const EnhancedSyncSettingsSheet(),
  );
}

class EnhancedSyncSettingsSheet extends ConsumerWidget {
  const EnhancedSyncSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(advancedSettingsProvider);
    final notifier = ref.read(advancedSettingsProvider.notifier);

    return GlassBottomSheet(
      blurIntensity: 20.0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
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
            const Text(
              'إعدادات المزامنة',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sync Settings',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // Settings content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Glassmorphism toggle
                  _buildToggleTile(
                    title: 'الوضع الزجاجي',
                    subtitle: 'Glassmorphism Theme',
                    icon: Icons.blur_on,
                    value: settings.isGlassmorphismEnabled,
                    onChanged: (v) => notifier.setGlassmorphismEnabled(v),
                  ),

                  const SizedBox(height: 12),

                  // Show mushaf view toggle
                  _buildToggleTile(
                    title: 'عرض المصحف الورقي',
                    subtitle: 'Show Paper Mushaf',
                    icon: Icons.auto_stories,
                    value: settings.showMushafView,
                    onChanged: (v) => notifier.toggleMushafView(),
                  ),

                  const SizedBox(height: 16),
                  _buildSectionTitle('مظهر الخلفية', 'Background Appearance'),
                  const SizedBox(height: 12),

                  // Background color picker
                  _buildColorPickerSection(context, ref),

                  const SizedBox(height: 16),
                  _buildSectionTitle('التكبير والتصغير', 'Zoom Controls'),
                  const SizedBox(height: 12),

                  // Sync display area size
                  _buildDisplaySizeSelector(ref, notifier),

                  const SizedBox(height: 16),
                  _buildSectionTitle('إعدادات الخط', 'Font Settings'),
                  const SizedBox(height: 12),

                  // Font size slider
                  _buildFontSizeSlider(ref, notifier),

                  const SizedBox(height: 16),
                  _buildSectionTitle('تأخير المزامنة', 'Sync Offset'),
                  const SizedBox(height: 12),

                  // Sync offset slider
                  _buildSyncOffsetSlider(ref, notifier),

                  const SizedBox(height: 16),
                  _buildSectionTitle('خيارات إضافية', 'Additional Options'),
                  const SizedBox(height: 12),

                  // Smooth highlight toggle
                  _buildToggleTile(
                    title: 'تمييز سلس',
                    subtitle: 'Smooth Highlight Transition',
                    icon: Icons.animation,
                    value: settings.smoothHighlightEnabled,
                    onChanged: (v) => notifier.toggleSmoothHighlight(v),
                  ),

                  const SizedBox(height: 12),

                  // Dim level slider
                  _buildDimLevelSlider(ref, notifier),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String arabic, String english) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          arabic,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          english,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildColorPickerSection(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(advancedSettingsProvider);
    final notifier = ref.read(advancedSettingsProvider.notifier);

    final colors = [
      {'name': 'ذهبي', 'hex': '#D4AF37', 'color': const Color(0xFFD4AF37)},
      {'name': 'أخضر', 'hex': '#4CAF50', 'color': const Color(0xFF4CAF50)},
      {'name': 'أزرق', 'hex': '#2196F3', 'color': const Color(0xFF2196F3)},
      {'name': 'أحمر', 'hex': '#F44336', 'color': const Color(0xFFF44336)},
      {'name': 'بنفسجي', 'hex': '#9C27B0', 'color': const Color(0xFF9C27B0)},
      {'name': 'برتقالي', 'hex': '#FF9800', 'color': const Color(0xFFFF9800)},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((c) {
        final isSelected = settings.syncFontColorHex == c['hex'];
        return GestureDetector(
          onTap: () => notifier.setSyncFontColorHex(c['hex'] as String),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: c['color'] as Color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (c['color'] as Color).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDisplaySizeSelector(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return Row(
      children: SyncDisplayAreaSize.values.map((size) {
        final isSelected = settings.syncDisplayAreaSize == size;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => notifier.setSyncDisplayAreaSize(size),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? AppColors.gold : Colors.white.withOpacity(0.1),
                foregroundColor: isSelected ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _getDisplaySizeLabel(size),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getDisplaySizeLabel(SyncDisplayAreaSize size) {
    switch (size) {
      case SyncDisplayAreaSize.quarter:
        return 'ربع';
      case SyncDisplayAreaSize.half:
        return 'نصف';
      case SyncDisplayAreaSize.full:
        return 'كامل';
    }
  }

  Widget _buildFontSizeSlider(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'حجم الخط',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            Text(
              '${settings.lyricsFontSize.toInt()}',
              style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: settings.lyricsFontSize,
          min: 20,
          max: 60,
          divisions: 40,
          activeColor: AppColors.gold,
          inactiveColor: Colors.white.withOpacity(0.2),
          onChanged: (v) => notifier.setLyricsFontSize(v),
        ),
      ],
    );
  }

  Widget _buildSyncOffsetSlider(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'تأخير المزامنة',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            Text(
              '${settings.syncOffsetSeconds > 0 ? "+" : ""}${settings.syncOffsetSeconds.toStringAsFixed(1)}s',
              style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: settings.syncOffsetSeconds,
          min: -5.0,
          max: 5.0,
          divisions: 20,
          activeColor: AppColors.gold,
          inactiveColor: Colors.white.withOpacity(0.2),
          onChanged: (v) => notifier.setSyncOffsetSeconds(v),
        ),
      ],
    );
  }

  Widget _buildDimLevelSlider(WidgetRef ref, AdvancedSettingsNotifier notifier) {
    final settings = ref.watch(advancedSettingsProvider);

    return Column(
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
          max: 0.9,
          divisions: 9,
          activeColor: AppColors.gold,
          inactiveColor: Colors.white.withOpacity(0.2),
          onChanged: (v) => notifier.setDimLevel(v),
        ),
      ],
    );
  }
}
