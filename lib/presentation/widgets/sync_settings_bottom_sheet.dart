import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/advanced_settings_provider.dart';
import '../../core/constants/colors.dart';

void showSyncSettingsBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _SyncSettingsSheet(),
  );
}

class _SyncSettingsSheet extends ConsumerWidget {
  const _SyncSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(advancedSettingsProvider);
    final notifier = ref.read(advancedSettingsProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.9), // Royal Black glass
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'إعدادات المزامنة',
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Font Size
          Text('حجم الخط', style: TextStyle(color: AppColors.textSecondary)),
          Slider(
            value: settings.lyricsFontSize,
            min: 20.0,
            max: 60.0,
            activeColor: AppColors.gold,
            inactiveColor: AppColors.gold.withOpacity(0.2),
            onChanged: (v) => notifier.setLyricsFontSize(v),
          ),
          
          // Font Family
          const SizedBox(height: 10),
          Text('نوع الخط', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              _FontChip(family: 'Amiri', current: settings.syncFontFamily, onTap: () => notifier.setSyncFontFamily('Amiri')),
              _FontChip(family: 'Cairo', current: settings.syncFontFamily, onTap: () => notifier.setSyncFontFamily('Cairo')),
              _FontChip(family: 'Tajawal', current: settings.syncFontFamily, onTap: () => notifier.setSyncFontFamily('Tajawal')),
            ],
          ),

          // Font Color
          const SizedBox(height: 20),
          Text('اللون', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              _ColorChip(hexColor: '#D4AF37', current: settings.syncFontColorHex, onTap: () => notifier.setSyncFontColorHex('#D4AF37')), // Gold
              _ColorChip(hexColor: '#FFFFFF', current: settings.syncFontColorHex, onTap: () => notifier.setSyncFontColorHex('#FFFFFF')), // White
              _ColorChip(hexColor: '#FF6B6B', current: settings.syncFontColorHex, onTap: () => notifier.setSyncFontColorHex('#FF6B6B')), // Red
              _ColorChip(hexColor: '#4ECDC4', current: settings.syncFontColorHex, onTap: () => notifier.setSyncFontColorHex('#4ECDC4')), // Cyan
            ],
          ),

          // Layout Scale (Display Area Size)
          const SizedBox(height: 20),
          Text('حجم منطقة العرض', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              _SizeChip(
                label: 'ربع الشاشة',
                value: SyncDisplayAreaSize.quarter,
                current: settings.syncDisplayAreaSize,
                onTap: () => notifier.setSyncDisplayAreaSize(SyncDisplayAreaSize.quarter),
              ),
              _SizeChip(
                label: 'نصف الشاشة',
                value: SyncDisplayAreaSize.half,
                current: settings.syncDisplayAreaSize,
                onTap: () => notifier.setSyncDisplayAreaSize(SyncDisplayAreaSize.half),
              ),
              _SizeChip(
                label: 'ملء الشاشة',
                value: SyncDisplayAreaSize.full,
                current: settings.syncDisplayAreaSize,
                onTap: () => notifier.setSyncDisplayAreaSize(SyncDisplayAreaSize.full),
              ),
            ],
          ),

          // Dimming Level
          const SizedBox(height: 20),
          Text('مستوى التعتيم (Dimming)', style: TextStyle(color: AppColors.textSecondary)),
          Slider(
            value: settings.dimLevel,
            min: 0.0,
            max: 0.9,
            activeColor: AppColors.gold,
            inactiveColor: AppColors.gold.withOpacity(0.2),
            onChanged: (v) => notifier.setDimLevel(v),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _FontChip extends StatelessWidget {
  final String family;
  final String current;
  final VoidCallback onTap;

  const _FontChip({required this.family, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = family == current;
    return ChoiceChip(
      label: Text(family),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.gold.withOpacity(0.3),
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(color: isSelected ? AppColors.gold : Colors.white),
      side: BorderSide(color: isSelected ? AppColors.gold : Colors.white30),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String hexColor;
  final String current;
  final VoidCallback onTap;

  const _ColorChip({required this.hexColor, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = hexColor == current;
    final color = Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : [],
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final SyncDisplayAreaSize value;
  final SyncDisplayAreaSize current;
  final VoidCallback onTap;

  const _SizeChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.white30,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.gold.withOpacity(0.2), blurRadius: 8)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.gold : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
