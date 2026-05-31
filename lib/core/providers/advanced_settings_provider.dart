import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum LyricsDisplayMode { onlyCurrent, consecutive }
enum SyncDisplayAreaSize { quarter, half, full }
enum MushafTheme { white, sepia, dark, smartDark }
enum ArabicFont { uthmanTaha, amiri, kufi, naskh, diwani }
enum FontColor { black, navy, darkRed, gold }

// LRC-specific settings (independent from Mushaf)
class LrcSettings {
  final double fontSize;
  final FontColor textColor;
  final bool autoScroll;
  final double scrollSpeed;
  final bool showVerseNumbers;
  final bool highlightCurrentWord;
  final double highlightGlowIntensity;

  const LrcSettings({
    this.fontSize = 32.0,
    this.textColor = FontColor.gold,
    this.autoScroll = true,
    this.scrollSpeed = 1.0,
    this.showVerseNumbers = true,
    this.highlightCurrentWord = true,
    this.highlightGlowIntensity = 0.8,
  });

  LrcSettings copyWith({
    double? fontSize,
    FontColor? textColor,
    bool? autoScroll,
    double? scrollSpeed,
    bool? showVerseNumbers,
    bool? highlightCurrentWord,
    double? highlightGlowIntensity,
  }) {
    return LrcSettings(
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      autoScroll: autoScroll ?? this.autoScroll,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      showVerseNumbers: showVerseNumbers ?? this.showVerseNumbers,
      highlightCurrentWord: highlightCurrentWord ?? this.highlightCurrentWord,
      highlightGlowIntensity: highlightGlowIntensity ?? this.highlightGlowIntensity,
    );
  }
}

// Mushaf Paper-specific settings (independent from LRC)
class MushafPaperSettings {
  final MushafTheme paperTheme;
  final double zoomLevel;
  final double brightness;
  final double contrast;
  final bool pageTurnAnimation;
  final bool showPageNumbers;
  final double sepiaIntensity;

  const MushafPaperSettings({
    this.paperTheme = MushafTheme.white,
    this.zoomLevel = 1.0,
    this.brightness = 1.0,
    this.contrast = 1.0,
    this.pageTurnAnimation = true,
    this.showPageNumbers = false,
    this.sepiaIntensity = 0.5,
  });

  MushafPaperSettings copyWith({
    MushafTheme? paperTheme,
    double? zoomLevel,
    double? brightness,
    double? contrast,
    bool? pageTurnAnimation,
    bool? showPageNumbers,
    double? sepiaIntensity,
  }) {
    return MushafPaperSettings(
      paperTheme: paperTheme ?? this.paperTheme,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      pageTurnAnimation: pageTurnAnimation ?? this.pageTurnAnimation,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      sepiaIntensity: sepiaIntensity ?? this.sepiaIntensity,
    );
  }
}

class AdvancedSettings {
  final double lyricsFontSize;
  final LyricsDisplayMode lyricsDisplayMode;
  final bool isWakeLockEnabled;
  final double blurLevel;
  final double playerTransparency;
  final bool isWarmMode;
  final String syncFontFamily;
  final String syncFontColorHex;
  final double dimLevel;
  final bool showSync;
  final SyncDisplayAreaSize syncDisplayAreaSize;
  
  // Independent LRC Settings
  final LrcSettings lrcSettings;
  
  // Independent Mushaf Paper Settings
  final MushafPaperSettings mushafPaperSettings;
  
  // Custom Mushaf Colors
  final String mushafPageColorHex;
  final String mushafBarColorHex;
  final String mushafVerseHighlightColorHex;
  final String mushafVerseTextColorHex;
  
  // Legacy Mushaf Settings (for backward compatibility)
  final MushafTheme mushafTheme;
  final double mushafZoomLevel;
  final ArabicFont arabicFont;
  final FontColor fontColor;
  final bool smartDarkMode;
  final double blueLightFilterLevel;
  final bool activeWordGlow;
  final bool cloudSyncEnabled;

  AdvancedSettings({
    this.lyricsFontSize = 32.0, // Changed default to 32 as requested
    this.lyricsDisplayMode = LyricsDisplayMode.consecutive,
    this.isWakeLockEnabled = false,
    this.blurLevel = 15.0,
    this.playerTransparency = 0.2,
    this.isWarmMode = false,
    this.syncFontFamily = 'Amiri',
    this.syncFontColorHex = '#D4AF37', // Default Gold
    this.dimLevel = 0.0,
    this.showSync = true,
    this.syncDisplayAreaSize = SyncDisplayAreaSize.full,
    this.lrcSettings = const LrcSettings(),
    this.mushafPaperSettings = const MushafPaperSettings(),
    this.mushafPageColorHex = '#F5E6D3', // Default Sepia
    this.mushafBarColorHex = '#D4AF37', // Default Gold
    this.mushafVerseHighlightColorHex = '#FFD700', // Default Golden Yellow
    this.mushafVerseTextColorHex = '#000000', // Default Black
    this.mushafTheme = MushafTheme.dark,
    this.mushafZoomLevel = 1.0,
    this.arabicFont = ArabicFont.amiri,
    this.fontColor = FontColor.gold,
    this.smartDarkMode = true,
    this.blueLightFilterLevel = 0.3,
    this.activeWordGlow = true,
    this.cloudSyncEnabled = false,
  });

  AdvancedSettings copyWith({
    double? lyricsFontSize,
    LyricsDisplayMode? lyricsDisplayMode,
    bool? isWakeLockEnabled,
    double? blurLevel,
    double? playerTransparency,
    bool? isWarmMode,
    String? syncFontFamily,
    String? syncFontColorHex,
    double? dimLevel,
    bool? showSync,
    SyncDisplayAreaSize? syncDisplayAreaSize,
    LrcSettings? lrcSettings,
    MushafPaperSettings? mushafPaperSettings,
    String? mushafPageColorHex,
    String? mushafBarColorHex,
    String? mushafVerseHighlightColorHex,
    String? mushafVerseTextColorHex,
    MushafTheme? mushafTheme,
    double? mushafZoomLevel,
    ArabicFont? arabicFont,
    FontColor? fontColor,
    bool? smartDarkMode,
    double? blueLightFilterLevel,
    bool? activeWordGlow,
    bool? cloudSyncEnabled,
  }) {
    return AdvancedSettings(
      lyricsFontSize: lyricsFontSize ?? this.lyricsFontSize,
      lyricsDisplayMode: lyricsDisplayMode ?? this.lyricsDisplayMode,
      isWakeLockEnabled: isWakeLockEnabled ?? this.isWakeLockEnabled,
      blurLevel: blurLevel ?? this.blurLevel,
      playerTransparency: playerTransparency ?? this.playerTransparency,
      isWarmMode: isWarmMode ?? this.isWarmMode,
      syncFontFamily: syncFontFamily ?? this.syncFontFamily,
      syncFontColorHex: syncFontColorHex ?? this.syncFontColorHex,
      dimLevel: dimLevel ?? this.dimLevel,
      showSync: showSync ?? this.showSync,
      syncDisplayAreaSize: syncDisplayAreaSize ?? this.syncDisplayAreaSize,
      lrcSettings: lrcSettings ?? this.lrcSettings,
      mushafPaperSettings: mushafPaperSettings ?? this.mushafPaperSettings,
      mushafPageColorHex: mushafPageColorHex ?? this.mushafPageColorHex,
      mushafBarColorHex: mushafBarColorHex ?? this.mushafBarColorHex,
      mushafVerseHighlightColorHex: mushafVerseHighlightColorHex ?? this.mushafVerseHighlightColorHex,
      mushafVerseTextColorHex: mushafVerseTextColorHex ?? this.mushafVerseTextColorHex,
      mushafTheme: mushafTheme ?? this.mushafTheme,
      mushafZoomLevel: mushafZoomLevel ?? this.mushafZoomLevel,
      arabicFont: arabicFont ?? this.arabicFont,
      fontColor: fontColor ?? this.fontColor,
      smartDarkMode: smartDarkMode ?? this.smartDarkMode,
      blueLightFilterLevel: blueLightFilterLevel ?? this.blueLightFilterLevel,
      activeWordGlow: activeWordGlow ?? this.activeWordGlow,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
    );
  }
}

class AdvancedSettingsNotifier extends StateNotifier<AdvancedSettings> {
  AdvancedSettingsNotifier() : super(AdvancedSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AdvancedSettings(
      lyricsFontSize: prefs.getDouble('lyrics_font_size') ?? 32.0,
      lyricsDisplayMode: LyricsDisplayMode.values[prefs.getInt('lyrics_display_mode') ?? 1],
      isWakeLockEnabled: prefs.getBool('wake_lock_enabled') ?? false,
      blurLevel: prefs.getDouble('blur_level') ?? 15.0,
      playerTransparency: prefs.getDouble('player_transparency') ?? 0.2,
      isWarmMode: prefs.getBool('warm_mode') ?? false,
      syncFontFamily: prefs.getString('sync_font_family') ?? 'Amiri',
      syncFontColorHex: prefs.getString('sync_font_color_hex') ?? '#D4AF37',
      dimLevel: prefs.getDouble('dim_level') ?? 0.0,
      showSync: prefs.getBool('show_sync') ?? true,
      syncDisplayAreaSize: SyncDisplayAreaSize.values[prefs.getInt('sync_display_area_size') ?? 2],
      mushafPageColorHex: prefs.getString('mushaf_page_color_hex') ?? '#F5E6D3',
      mushafBarColorHex: prefs.getString('mushaf_bar_color_hex') ?? '#D4AF37',
      mushafVerseHighlightColorHex: prefs.getString('mushaf_verse_highlight_color_hex') ?? '#FFD700',
      mushafVerseTextColorHex: prefs.getString('mushaf_verse_text_color_hex') ?? '#000000',
      mushafTheme: MushafTheme.values[prefs.getInt('mushaf_theme') ?? 3],
      mushafZoomLevel: prefs.getDouble('mushaf_zoom_level') ?? 1.0,
      arabicFont: ArabicFont.values[prefs.getInt('arabic_font') ?? 1],
      fontColor: FontColor.values[prefs.getInt('font_color') ?? 3],
      smartDarkMode: prefs.getBool('smart_dark_mode') ?? true,
      blueLightFilterLevel: prefs.getDouble('blue_light_filter_level') ?? 0.3,
      activeWordGlow: prefs.getBool('active_word_glow') ?? true,
      cloudSyncEnabled: prefs.getBool('cloud_sync_enabled') ?? false,
    );
    _applyWakeLock(state.isWakeLockEnabled);
  }

  Future<void> toggleSync() async {
    final newValue = !state.showSync;
    state = state.copyWith(showSync: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_sync', newValue);
  }

  Future<void> setSyncFontFamily(String family) async {
    state = state.copyWith(syncFontFamily: family);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sync_font_family', family);
  }

  Future<void> setSyncFontColorHex(String hexColor) async {
    state = state.copyWith(syncFontColorHex: hexColor);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sync_font_color_hex', hexColor);
  }

  Future<void> setDimLevel(double level) async {
    state = state.copyWith(dimLevel: level);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dim_level', level);
  }

  Future<void> setLyricsFontSize(double size) async {
    state = state.copyWith(lyricsFontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lyrics_font_size', size);
  }

  Future<void> setLyricsDisplayMode(LyricsDisplayMode mode) async {
    state = state.copyWith(lyricsDisplayMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lyrics_display_mode', mode.index);
  }

  Future<void> setWakeLock(bool enabled) async {
    state = state.copyWith(isWakeLockEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wake_lock_enabled', enabled);
    _applyWakeLock(enabled);
  }

  void _applyWakeLock(bool enabled) {
    if (enabled) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  Future<void> setBlurLevel(double level) async {
    state = state.copyWith(blurLevel: level);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('blur_level', level);
  }

  Future<void> setPlayerTransparency(double transparency) async {
    state = state.copyWith(playerTransparency: transparency);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('player_transparency', transparency);
  }

  Future<void> setWarmMode(bool enabled) async {
    state = state.copyWith(isWarmMode: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('warm_mode', enabled);
  }

  Future<void> setSyncDisplayAreaSize(SyncDisplayAreaSize size) async {
    state = state.copyWith(syncDisplayAreaSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sync_display_area_size', size.index);
  }

  // ============================================================================
  // MUSHAF SETTINGS METHODS
  // ============================================================================

  Future<void> setMushafTheme(MushafTheme theme) async {
    state = state.copyWith(mushafTheme: theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('mushaf_theme', theme.index);
  }

  Future<void> setMushafZoomLevel(double zoom) async {
    state = state.copyWith(mushafZoomLevel: zoom);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mushaf_zoom_level', zoom);
  }

  Future<void> setArabicFont(ArabicFont font) async {
    state = state.copyWith(arabicFont: font);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('arabic_font', font.index);
  }

  Future<void> setFontColor(FontColor color) async {
    state = state.copyWith(fontColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('font_color', color.index);
  }

  Future<void> setSmartDarkMode(bool enabled) async {
    state = state.copyWith(smartDarkMode: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_dark_mode', enabled);
  }

  Future<void> setBlueLightFilterLevel(double level) async {
    state = state.copyWith(blueLightFilterLevel: level);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('blue_light_filter_level', level);
  }

  Future<void> setActiveWordGlow(bool enabled) async {
    state = state.copyWith(activeWordGlow: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('active_word_glow', enabled);
  }

  Future<void> setCloudSyncEnabled(bool enabled) async {
    state = state.copyWith(cloudSyncEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cloud_sync_enabled', enabled);
  }

  Future<void> setMushafPageColorHex(String hex) async {
    state = state.copyWith(mushafPageColorHex: hex);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mushaf_page_color_hex', hex);
  }

  Future<void> setMushafBarColorHex(String hex) async {
    state = state.copyWith(mushafBarColorHex: hex);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mushaf_bar_color_hex', hex);
  }

  Future<void> setMushafVerseHighlightColorHex(String hex) async {
    state = state.copyWith(mushafVerseHighlightColorHex: hex);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mushaf_verse_highlight_color_hex', hex);
  }

  Future<void> setMushafVerseTextColorHex(String hex) async {
    state = state.copyWith(mushafVerseTextColorHex: hex);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mushaf_verse_text_color_hex', hex);
  }

  /// Get font family name from ArabicFont enum
  String getFontFamilyName(ArabicFont font) {
    switch (font) {
      case ArabicFont.uthmanTaha:
        return 'UthmanTaha';
      case ArabicFont.amiri:
        return 'Amiri';
      case ArabicFont.kufi:
        return 'Kufi';
      case ArabicFont.naskh:
        return 'Naskh';
      case ArabicFont.diwani:
        return 'Diwani';
    }
  }

  /// Get color value from FontColor enum
  String getFontColorValue(FontColor color) {
    switch (color) {
      case FontColor.black:
        return '#000000';
      case FontColor.navy:
        return '#1B3A5C';
      case FontColor.darkRed:
        return '#8B0000';
      case FontColor.gold:
        return '#D4AF37';
    }
  }
}

final advancedSettingsProvider = StateNotifierProvider<AdvancedSettingsNotifier, AdvancedSettings>((ref) {
  return AdvancedSettingsNotifier();
});
