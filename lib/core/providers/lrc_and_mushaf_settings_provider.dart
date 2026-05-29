import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'advanced_settings_provider.dart';

/// ============================================================================
/// LRC SETTINGS PROVIDER - Independent from Mushaf Settings
/// ============================================================================
/// 
/// Features:
/// - Font size (default 32)
/// - Text color
/// - Auto-scroll toggle
/// - Scroll speed
/// - Verse numbers visibility
/// - Current word highlight
/// - Highlight glow intensity
/// - Auto-save to SharedPreferences

class LrcSettingsNotifier extends StateNotifier<LrcSettings> {
  LrcSettingsNotifier() : super(const LrcSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = LrcSettings(
      fontSize: prefs.getDouble('lrc_font_size') ?? 32.0,
      textColor: FontColor.values[prefs.getInt('lrc_text_color') ?? 3],
      autoScroll: prefs.getBool('lrc_auto_scroll') ?? true,
      scrollSpeed: prefs.getDouble('lrc_scroll_speed') ?? 1.0,
      showVerseNumbers: prefs.getBool('lrc_show_verse_numbers') ?? true,
      highlightCurrentWord: prefs.getBool('lrc_highlight_current_word') ?? true,
      highlightGlowIntensity: prefs.getDouble('lrc_highlight_glow') ?? 0.8,
    );
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lrc_font_size', size);
  }

  Future<void> setTextColor(FontColor color) async {
    state = state.copyWith(textColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lrc_text_color', color.index);
  }

  Future<void> toggleAutoScroll() async {
    state = state.copyWith(autoScroll: !state.autoScroll);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lrc_auto_scroll', state.autoScroll);
  }

  Future<void> setScrollSpeed(double speed) async {
    state = state.copyWith(scrollSpeed: speed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lrc_scroll_speed', speed);
  }

  Future<void> toggleVerseNumbers() async {
    state = state.copyWith(showVerseNumbers: !state.showVerseNumbers);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lrc_show_verse_numbers', state.showVerseNumbers);
  }

  Future<void> toggleHighlightCurrentWord() async {
    state = state.copyWith(highlightCurrentWord: !state.highlightCurrentWord);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lrc_highlight_current_word', state.highlightCurrentWord);
  }

  Future<void> setHighlightGlowIntensity(double intensity) async {
    state = state.copyWith(highlightGlowIntensity: intensity);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lrc_highlight_glow', intensity);
  }
}

final lrcSettingsProvider = StateNotifierProvider<LrcSettingsNotifier, LrcSettings>((ref) {
  return LrcSettingsNotifier();
});

/// ============================================================================
/// MUSHAF PAPER SETTINGS PROVIDER - Independent from LRC Settings
/// ============================================================================
/// 
/// Features:
/// - Paper theme (White, Sepia, Dark, Smart Dark)
/// - Zoom level
/// - Brightness control
/// - Contrast control
/// - Page turn animation
/// - Page numbers visibility
/// - Sepia intensity
/// - Auto-save to SharedPreferences

class MushafPaperSettingsNotifier extends StateNotifier<MushafPaperSettings> {
  MushafPaperSettingsNotifier() : super(const MushafPaperSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = MushafPaperSettings(
      paperTheme: MushafTheme.values[prefs.getInt('mushaf_paper_theme') ?? 0],
      zoomLevel: prefs.getDouble('mushaf_paper_zoom') ?? 1.0,
      brightness: prefs.getDouble('mushaf_paper_brightness') ?? 1.0,
      contrast: prefs.getDouble('mushaf_paper_contrast') ?? 1.0,
      pageTurnAnimation: prefs.getBool('mushaf_page_turn_anim') ?? true,
      showPageNumbers: prefs.getBool('mushaf_show_page_numbers') ?? false,
      sepiaIntensity: prefs.getDouble('mushaf_sepia_intensity') ?? 0.5,
    );
  }

  Future<void> setPaperTheme(MushafTheme theme) async {
    state = state.copyWith(paperTheme: theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('mushaf_paper_theme', theme.index);
  }

  Future<void> setZoomLevel(double zoom) async {
    state = state.copyWith(zoomLevel: zoom);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mushaf_paper_zoom', zoom);
  }

  Future<void> setBrightness(double brightness) async {
    state = state.copyWith(brightness: brightness);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mushaf_paper_brightness', brightness);
  }

  Future<void> setContrast(double contrast) async {
    state = state.copyWith(contrast: contrast);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mushaf_paper_contrast', contrast);
  }

  Future<void> togglePageTurnAnimation() async {
    state = state.copyWith(pageTurnAnimation: !state.pageTurnAnimation);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mushaf_page_turn_anim', state.pageTurnAnimation);
  }

  Future<void> togglePageNumbers() async {
    state = state.copyWith(showPageNumbers: !state.showPageNumbers);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mushaf_show_page_numbers', state.showPageNumbers);
  }

  Future<void> setSepiaIntensity(double intensity) async {
    state = state.copyWith(sepiaIntensity: intensity);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mushaf_sepia_intensity', intensity);
  }
}

final mushafPaperSettingsProvider = StateNotifierProvider<MushafPaperSettingsNotifier, MushafPaperSettings>((ref) {
  return MushafPaperSettingsNotifier();
});
