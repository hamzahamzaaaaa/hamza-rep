// Native (dart:io) implementations for mobile/desktop platforms
import 'dart:io';
import 'package:path_provider/path_provider.dart';

String _transliterate(String arabicName) {
  final mapping = {
    'الفاتحة': 'fatihah', 'البقرة': 'baqarah', 'آل عمران': 'ali_imran',
    'النساء': 'nisa', 'المائدة': 'maidah', 'الأنعام': 'anam',
    'الأعراف': 'araf', 'الأنفال': 'anfal', 'التوبة': 'tawbah',
    'يونس': 'yunus', 'هود': 'hud', 'يوسف': 'yusuf', 'الرعد': 'rad',
    'إبراهيم': 'ibrahim', 'الحجر': 'hijr', 'النحل': 'nahl',
    'الإسراء': 'isra', 'الكهف': 'kahf', 'مريم': 'maryam',
    'طه': 'taha', 'الأنبياء': 'anbiya', 'الحج': 'hajj',
    'المؤمنون': 'muminun', 'النور': 'nur', 'الفرقان': 'furqan',
    'الشعراء': 'shuara', 'النمل': 'naml', 'القصص': 'qasas',
    'العنكبوت': 'ankabut', 'الروم': 'rum', 'لقمان': 'luqman',
    'السجدة': 'sajdah', 'الأحزاب': 'ahzab', 'سبأ': 'saba',
    'فاطر': 'fatir', 'يس': 'yasin', 'الصافات': 'saffat',
    'ص': 'sad', 'الزمر': 'zumar', 'غافر': 'ghafir',
    'فصلت': 'fussilat', 'الشورى': 'shura', 'الزخرف': 'zukhruf',
    'الدخان': 'dukhan', 'الجاثية': 'jathiyah', 'الأحقاف': 'ahqaf',
    'محمد': 'muhammad', 'الفتح': 'fath', 'الحجرات': 'hujurat',
    'ق': 'qaf', 'الذاريات': 'dhariyat', 'الطور': 'tur',
    'النجم': 'najm', 'القمر': 'qamar', 'الرحمن': 'rahman',
    'الواقعة': 'waqiah', 'الحديد': 'hadid', 'المجادلة': 'mujadilah',
    'الحشر': 'hashr', 'الممتحنة': 'mumtahanah', 'الصف': 'saff',
    'الجمعة': 'jumuah', 'المنافقون': 'munafiqun', 'التغابن': 'taghabun',
    'الطلاق': 'talaq', 'التحريم': 'tahrim', 'الملك': 'mulk',
    'القلم': 'qalam', 'الحاقة': 'haqqah', 'المعارج': 'maarij',
    'نوح': 'nuh', 'الجن': 'jinn', 'المزمل': 'muzzammil',
    'المدثر': 'muddaththir', 'القيامة': 'qiyamah', 'الإنسان': 'insan',
    'المرسلات': 'mursalat', 'النبأ': 'naba', 'النازعات': 'naziat',
    'عبس': 'abasa', 'التكوير': 'takwir', 'الانفطار': 'infitar',
    'المطففين': 'mutaffifin', 'الانشقاق': 'inshiqaq', 'البروج': 'buruj',
    'الطارق': 'tariq', 'الأعلى': 'ala', 'الغاشية': 'ghashiyah',
    'الفجر': 'fajr', 'البلد': 'balad', 'الشمس': 'shams',
    'الليل': 'layl', 'الضحى': 'duha', 'الشرح': 'sharh',
    'التين': 'tin', 'العلق': 'alaq', 'القدر': 'qadr',
    'البينة': 'bayyinah', 'الزلزلة': 'zalzalah', 'العاديات': 'adiyat',
    'القارعة': 'qariah', 'التكاثر': 'takathur', 'العصر': 'asr',
    'الهمزة': 'humazah', 'الفيل': 'fil', 'قريش': 'quraish',
    'الماعون': 'maun', 'الكوثر': 'kawthar', 'الكافرون': 'kafirun',
    'الناصر': 'nasr', 'المسد': 'masad', 'الإخلاص': 'ikhlas',
    'الفلق': 'falaq', 'الناس': 'nas',
  };

  String cleanName = arabicName.replaceFirst('سورة ', '').trim();
  String? translit = mapping[cleanName];
  
  if (translit != null) return translit;

  // Fallback: simple character replacement for other names
  return arabicName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
}

Future<String> resolveLocalPath(String surahId, String folderName, {bool isLrc = false, String? surahName}) async {
  final appDir = await getApplicationDocumentsDirectory();
  
  String filename;
  if (surahName != null && surahName.isNotEmpty) {
    final translit = _transliterate(surahName);
    filename = 'surah_${translit}_hamza';
  } else {
    filename = surahId.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  String cleanFolderName = folderName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final subDir = isLrc ? 'Lyrics' : cleanFolderName;
  final dirPath = '${appDir.path}/Hamza_Medbouh/$subDir';
  
  final dir = Directory(dirPath);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final extension = isLrc ? 'lrc' : 'mp3';
  return '$dirPath/$filename.$extension';
}

Future<void> writeAudioMetadata(String path, {required String title, required String artist, required String album}) async {
  // Placeholder for future metadata support once library incompatibilities are resolved
  // Both audiotags and metadata_god currently have Gradle/Cargokit build issues in this environment.
}

Future<void> deleteLocalFile(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}
