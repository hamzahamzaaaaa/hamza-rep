import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageState {
  final String selectedLanguage;
  final bool isFirstRun;

  LanguageState({
    this.selectedLanguage = 'ar',
    this.isFirstRun = true,
  });

  LanguageState copyWith({
    String? selectedLanguage,
    bool? isFirstRun,
  }) {
    return LanguageState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      isFirstRun: isFirstRun ?? this.isFirstRun,
    );
  }
}

class LanguageNotifier extends StateNotifier<LanguageState> {
  static const _langKey = '@selected_language';
  static const _firstRunKey = '@is_first_run';

  LanguageNotifier() : super(LanguageState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_langKey) ?? 'ar';
    final firstRun = prefs.getBool(_firstRunKey) ?? true;
    state = LanguageState(selectedLanguage: lang, isFirstRun: firstRun);
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
    await prefs.setBool(_firstRunKey, false);
    state = state.copyWith(selectedLanguage: lang, isFirstRun: false);
  }

  String t(String ar, String en, String pt, String fr) {
    switch (state.selectedLanguage) {
      case 'en': return en;
      case 'pt': return pt;
      case 'fr': return fr;
      default: return ar;
    }
  }

  String translateSurahName(String arName) {
    if (state.selectedLanguage == 'ar') return arName;
    
    // Remove ANY existing prefixes to avoid duplication (e.g. سورة, Surah)
    String cleanName = arName.replaceAll(RegExp(r'(سورة\s*|Surah\s*|Surat\s*|Sourate\s*)', caseSensitive: false), '').trim();
    
    // Extract suffix (like numbers or letters at the end)
    final regex = RegExp(r'^([\u0600-\u06FF\s]+)(.*)$');
    final match = regex.firstMatch(cleanName);
    
    String baseName = cleanName;
    String suffix = '';
    
    if (match != null) {
      baseName = match.group(1)!.trim();
      suffix = match.group(2)!.trim();
      if (suffix.isNotEmpty) suffix = ' $suffix';
    }

    String cleanBaseName = baseName.trim();

    final mapping = {
      'الفاتحة': {'en': 'Al-Fatihah', 'pt': 'Al-Fatihah', 'fr': 'Al-Fatihah'},
      'البقرة': {'en': 'Al-Baqarah', 'pt': 'Al-Baqarah', 'fr': 'Al-Baqarah'},
      'آل عمران': {'en': 'Ali \'Imran', 'pt': 'Ali Imran', 'fr': 'Ali Imran'},
      'النساء': {'en': 'An-Nisa\'', 'pt': 'An-Nisa', 'fr': 'An-Nisa'},
      'المائدة': {'en': 'Al-Ma\'idah', 'pt': 'Al-Maidah', 'fr': 'Al-Maidah'},
      'الأنعام': {'en': 'Al-An\'am', 'pt': 'Al-Anam', 'fr': 'Al-Anam'},
      'الأعراف': {'en': 'Al-A\'raf', 'pt': 'Al-Araf', 'fr': 'Al-Araf'},
      'الأنفال': {'en': 'Al-Anfal', 'pt': 'Al-Anfal', 'fr': 'Al-Anfal'},
      'التوبة': {'en': 'At-Tawbah', 'pt': 'At-Tawbah', 'fr': 'At-Tawbah'},
      'يونس': {'en': 'Yunus', 'pt': 'Yunus', 'fr': 'Yunus'},
      'هود': {'en': 'Hud', 'pt': 'Hud', 'fr': 'Hud'},
      'يوسف': {'en': 'Yusuf', 'pt': 'Yusuf', 'fr': 'Yusuf'},
      'الرعد': {'en': 'Ar-Ra\'d', 'pt': 'Ar-Rad', 'fr': 'Ar-Rad'},
      'إبراهيم': {'en': 'Ibrahim', 'pt': 'Ibrahim', 'fr': 'Ibrahim'},
      'الحجر': {'en': 'Al-Hijr', 'pt': 'Al-Hijr', 'fr': 'Al-Hijr'},
      'النحل': {'en': 'An-Nahl', 'pt': 'An-Nahl', 'fr': 'An-Nahl'},
      'الإسراء': {'en': 'Al-Isra\'', 'pt': 'Al-Isra', 'fr': 'Al-Isra'},
      'الكهف': {'en': 'Al-Kahf', 'pt': 'Al-Kahf', 'fr': 'Al-Kahf'},
      'مريم': {'en': 'Maryam', 'pt': 'Maryam', 'fr': 'Maryam'},
      'طه': {'en': 'Ta-Ha', 'pt': 'Ta-Ha', 'fr': 'Ta-Ha'},
      'الأنبياء': {'en': 'Al-Anbiya\'', 'pt': 'Al-Anbiya', 'fr': 'Al-Anbiya'},
      'الحج': {'en': 'Al-Hajj', 'pt': 'Al-Hajj', 'fr': 'Al-Hajj'},
      'المؤمنون': {'en': 'Al-Mu\'minun', 'pt': 'Al-Mu-minun', 'fr': 'Al-Mu-minun'},
      'النور': {'en': 'An-Nur', 'pt': 'An-Nur', 'fr': 'An-Nur'},
      'الفرقان': {'en': 'Al-Furqan', 'pt': 'Al-Furqan', 'fr': 'Al-Furqan'},
      'الشعراء': {'en': 'Ash-Shu\'ara\'', 'pt': 'Ash-Shuara', 'fr': 'Ash-Shuara'},
      'النمل': {'en': 'An-Naml', 'pt': 'An-Naml', 'fr': 'An-Naml'},
      'القصص': {'en': 'Al-Qasas', 'pt': 'Al-Qasas', 'fr': 'Al-Qasas'},
      'العنكبوت': {'en': 'Al-Ankabut', 'pt': 'Al-Ankabut', 'fr': 'Al-Ankabut'},
      'الروم': {'en': 'Ar-Rum', 'pt': 'Ar-Rum', 'fr': 'Ar-Rum'},
      'لقمان': {'en': 'Luqman', 'pt': 'Luqman', 'fr': 'Luqman'},
      'السجدة': {'en': 'As-Sajdah', 'pt': 'As-Sajdah', 'fr': 'As-Sajdah'},
      'الأحزاب': {'en': 'Al-Ahzab', 'pt': 'Al-Ahzab', 'fr': 'Al-Ahzab'},
      'سبأ': {'en': 'Saba\'', 'pt': 'Saba', 'fr': 'Saba'},
      'فاطر': {'en': 'Fatir', 'pt': 'Fatir', 'fr': 'Fatir'},
      'يس': {'en': 'Ya-Sin', 'pt': 'Ya-Sin', 'fr': 'Ya-Sin'},
      'الصافات': {'en': 'As-Saffat', 'pt': 'As-Saffat', 'fr': 'As-Saffat'},
      'ص': {'en': 'Sad', 'pt': 'Sad', 'fr': 'Sad'},
      'الزمر': {'en': 'Az-Zumar', 'pt': 'Az-Zumar', 'fr': 'Az-Zumar'},
      'غافر': {'en': 'Ghafir', 'pt': 'Ghafir', 'fr': 'Ghafir'},
      'فصلت': {'en': 'Fussilat', 'pt': 'Fussilat', 'fr': 'Fussilat'},
      'الشورى': {'en': 'Ash-Shura', 'pt': 'Ash-Shura', 'fr': 'Ash-Shura'},
      'الزخرف': {'en': 'Az-Zukhruf', 'pt': 'Az-Zukhruf', 'fr': 'Az-Zukhruf'},
      'الدخان': {'en': 'Ad-Dukhan', 'pt': 'Ad-Dukhan', 'fr': 'Ad-Dukhan'},
      'الجاثية': {'en': 'Al-Jathiyah', 'pt': 'Al-Jathiyah', 'fr': 'Al-Jathiyah'},
      'الأحقاف': {'en': 'Al-Ahqaf', 'pt': 'Al-Ahqaf', 'fr': 'Al-Ahqaf'},
      'محمد': {'en': 'Muhammad', 'pt': 'Muhammad', 'fr': 'Muhammad'},
      'الفتح': {'en': 'Al-Fath', 'pt': 'Al-Fath', 'fr': 'Al-Fath'},
      'الحجرات': {'en': 'Al-Hujurat', 'pt': 'Al-Hujurat', 'fr': 'Al-Hujurat'},
      'ق': {'en': 'Qaf', 'pt': 'Qaf', 'fr': 'Qaf'},
      'الذاريات': {'en': 'Adh-Dhariyat', 'pt': 'Adh-Dhariyat', 'fr': 'Adh-Dhariyat'},
      'الطور': {'en': 'At-Tur', 'pt': 'At-Tur', 'fr': 'At-Tur'},
      'النجم': {'en': 'An-Najm', 'pt': 'An-Najm', 'fr': 'An-Najm'},
      'القمر': {'en': 'Al-Qamar', 'pt': 'Al-Qamar', 'fr': 'Al-Qamar'},
      'الرحمن': {'en': 'Ar-Rahman', 'pt': 'Ar-Rahman', 'fr': 'Ar-Rahman'},
      'الواقعة': {'en': 'Al-Waqi\'ah', 'pt': 'Al-Waqiah', 'fr': 'Al-Waqiah'},
      'الحديد': {'en': 'Al-Hadid', 'pt': 'Al-Hadid', 'fr': 'Al-Hadid'},
      'المجادلة': {'en': 'Al-Mujadilah', 'pt': 'Al-Mujadilah', 'fr': 'Al-Mujadilah'},
      'الحشر': {'en': 'Al-Hashr', 'pt': 'Al-Hashr', 'fr': 'Al-Hashr'},
      'الممتحنة': {'en': 'Al-Mumtahanah', 'pt': 'Al-Mumtahanah', 'fr': 'Al-Mumtahanah'},
      'الصف': {'en': 'As-Saff', 'pt': 'As-Saff', 'fr': 'As-Saff'},
      'الجمعة': {'en': 'Al-Jumu\'ah', 'pt': 'Al-Jumuah', 'fr': 'Al-Jumuah'},
      'المنافقون': {'en': 'Al-Munafiqun', 'pt': 'Al-Munafiqun', 'fr': 'Al-Munafiqun'},
      'التغابن': {'en': 'At-Taghabun', 'pt': 'At-Taghabun', 'fr': 'At-Taghabun'},
      'الطلاق': {'en': 'At-Talaq', 'pt': 'At-Talaq', 'fr': 'At-Talaq'},
      'التحريم': {'en': 'At-Tahrim', 'pt': 'At-Tahrim', 'fr': 'At-Tahrim'},
      'الملك': {'en': 'Al-Mulk', 'pt': 'Al-Mulk', 'fr': 'Al-Mulk'},
      'القلم': {'en': 'Al-Qalam', 'pt': 'Al-Qalam', 'fr': 'Al-Qalam'},
      'الحاقة': {'en': 'Al-Haqqah', 'pt': 'Al-Haqqah', 'fr': 'Al-Haqqah'},
      'المعارج': {'en': 'Al-Ma\'arij', 'pt': 'Al-Maarij', 'fr': 'Al-Maarij'},
      'نوح': {'en': 'Nuh', 'pt': 'Nuh', 'fr': 'Nuh'},
      'الجن': {'en': 'Al-Jinn', 'pt': 'Al-Jinn', 'fr': 'Al-Jinn'},
      'المزمل': {'en': 'Al-Muzzammil', 'pt': 'Al-Muzzammil', 'fr': 'Al-Muzzammil'},
      'المدثر': {'en': 'Al-Muddaththir', 'pt': 'Al-Muddaththir', 'fr': 'Al-Muddaththir'},
      'القيامة': {'en': 'Al-Qiyamah', 'pt': 'Al-Qiyamah', 'fr': 'Al-Qiyamah'},
      'الإنسان': {'en': 'Al-Insan', 'pt': 'Al-Insan', 'fr': 'Al-Insan'},
      'المرسلات': {'en': 'Al-Mursalat', 'pt': 'Al-Mursalat', 'fr': 'Al-Mursalat'},
      'النبأ': {'en': 'An-Naba\'', 'pt': 'An-Naba', 'fr': 'An-Naba'},
      'النازعات': {'en': 'An-Nazi\'at', 'pt': 'An-Naziat', 'fr': 'An-Naziat'},
      'عبس': {'en': 'Abasa', 'pt': 'Abasa', 'fr': 'Abasa'},
      'التكوير': {'en': 'At-Takwir', 'pt': 'At-Takwir', 'fr': 'At-Takwir'},
      'الانفطار': {'en': 'Al-Infitar', 'pt': 'Al-Infitar', 'fr': 'Al-Infitar'},
      'المطففين': {'en': 'Al-Mutaffifin', 'pt': 'Al-Mutaffifin', 'fr': 'Al-Mutaffifin'},
      'الانشقاق': {'en': 'Al-Inshiqaq', 'pt': 'Al-Inshiqaq', 'fr': 'Al-Inshiqaq'},
      'البروج': {'en': 'Al-Buruj', 'pt': 'Al-Buruj', 'fr': 'Al-Buruj'},
      'الطارق': {'en': 'At-Tariq', 'pt': 'At-Tariq', 'fr': 'At-Tariq'},
      'الأعلى': {'en': 'Al-A\'la', 'pt': 'Al-Ala', 'fr': 'Al-Ala'},
      'الغاشية': {'en': 'Al-Ghashiyah', 'pt': 'Al-Ghashiyah', 'fr': 'Al-Ghashiyah'},
      'الفجر': {'en': 'Al-Fajr', 'pt': 'Al-Fajr', 'fr': 'Al-Fajr'},
      'البلد': {'en': 'Al-Balad', 'pt': 'Al-Balad', 'fr': 'Al-Balad'},
      'الشمس': {'en': 'Ash-Shams', 'pt': 'Ash-Shams', 'fr': 'Ash-Shams'},
      'الليل': {'en': 'Al-Lail', 'pt': 'Al-Lail', 'fr': 'Al-Lail'},
      'الضحى': {'en': 'Ad-Duha', 'pt': 'Ad-Duha', 'fr': 'Ad-Duha'},
      'الشرح': {'en': 'Ash-Sharh', 'pt': 'Ash-Sharh', 'fr': 'Ash-Sharh'},
      'التين': {'en': 'At-Tin', 'pt': 'At-Tin', 'fr': 'At-Tin'},
      'العلق': {'en': 'Al-\'Alaq', 'pt': 'Al-Alaq', 'fr': 'Al-Alaq'},
      'القدر': {'en': 'Al-Qadr', 'pt': 'Al-Qadr', 'fr': 'Al-Qadr'},
      'البينة': {'en': 'Al-Bayyinah', 'pt': 'Al-Bayyinah', 'fr': 'Al-Bayyinah'},
      'الزلزلة': {'en': 'Az-Zalzalah', 'pt': 'Az-Zalzalah', 'fr': 'Az-Zalzalah'},
      'العاديات': {'en': 'Al-\'Adiyat', 'pt': 'Al-Adiyat', 'fr': 'Al-Adiyat'},
      'القارعة': {'en': 'Al-Qari\'ah', 'pt': 'Al-Qariah', 'fr': 'Al-Qariah'},
      'التكاثر': {'en': 'At-Takathur', 'pt': 'At-Takathur', 'fr': 'At-Takathur'},
      'العصر': {'en': 'Al-\'Asr', 'pt': 'Al-Asr', 'fr': 'Al-Asr'},
      'الهمزة': {'en': 'Al-Humazah', 'pt': 'Al-Humazah', 'fr': 'Al-Humazah'},
      'الفيل': {'en': 'Al-Fil', 'pt': 'Al-Fil', 'fr': 'Al-Fil'},
      'قريش': {'en': 'Quraish', 'pt': 'Quraish', 'fr': 'Quraish'},
      'الماعون': {'en': 'Al-Ma\'un', 'pt': 'Al-Maun', 'fr': 'Al-Maun'},
      'الكوثر': {'en': 'Al-Kawthar', 'pt': 'Al-Kawthar', 'fr': 'Al-Kawthar'},
      'الكافرون': {'en': 'Al-Kafirun', 'pt': 'Al-Kafirun', 'fr': 'Al-Kafirun'},
      'الناصر': {'en': 'An-Nasr', 'pt': 'An-Nasr', 'fr': 'An-Nasr'},
      'المسد': {'en': 'Al-Masad', 'pt': 'Al-Masad', 'fr': 'Al-Masad'},
      'الإخلاص': {'en': 'Al-Ikhlas', 'pt': 'Al-Ikhlas', 'fr': 'Al-Ikhlas'},
      'الفلق': {'en': 'Al-Falaq', 'pt': 'Al-Falaq', 'fr': 'Al-Falaq'},
      'الناس': {'en': 'An-Nas', 'pt': 'An-Nas', 'fr': 'An-Nas'},
    };

    final entry = mapping[cleanBaseName];
    if (entry != null) {
      final prefix = t('سورة', 'Surah', 'Surat', 'Sourate');
      return "$prefix ${entry[state.selectedLanguage] ?? cleanBaseName}$suffix";
    }
    
    // Fallback: Just prepend prefix
    final prefix = t('سورة', 'Surah', 'Surat', 'Sourate');
    return "$prefix ${cleanBaseName.replaceAll('سورة ', '')}$suffix";
  }

}

final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier();
});
