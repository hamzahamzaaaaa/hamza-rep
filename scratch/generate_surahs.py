import re

# Existing file content
with open('../lib/core/models/surah.dart', 'r', encoding='utf-8') as f:
    old_content = f.read()

# Extract URLs
url_dict = {}
# simple extraction based on id
blocks = old_content.split('Surah(')
for block in blocks[1:]:
    # extract id
    id_match = re.search(r'id:\s*"([^"]+)"', block)
    url_match = re.search(r'url:\s*"([^"]+)"', block)
    if id_match and url_match:
        url_dict[id_match.group(1)] = url_match.group(1)

# Quran 114 metadata (Name, isMakki, English ID)
quran_meta = [
    ("الفاتحة", True, "al-fatiha"), ("البقرة", False, "al-baqara-22"), ("آل عمران", False, "al-imran"),
    ("النساء", False, "al-nisa"), ("المائدة", False, "al-maida"), ("الأنعام", True, "al-anam"),
    ("الأعراف", True, "al-araf"), ("الأنفال", False, "al-anfal"), ("التوبة", False, "al-tawba"),
    ("يونس", True, "yunus"), ("هود", True, "hud"), ("يوسف", True, "yusuf"),
    ("الرعد", False, "al-rad"), ("إبراهيم", True, "ibrahim"), ("الحجر", True, "al-hijr"),
    ("النحل", True, "al-nahl"), ("الإسراء", True, "al-isra"), ("الكهف", True, "al-kahf"),
    ("مريم", True, "maryam"), ("طه", True, "taha"), ("الأنبياء", True, "al-anbiya"),
    ("الحج", False, "al-hajj"), ("المؤمنون", True, "al-muminun"), ("النور", False, "al-nur"),
    ("الفرقان", True, "al-furqan"), ("الشعراء", True, "al-shuara"), ("النمل", True, "al-naml"),
    ("القصص", True, "al-qasas"), ("العنكبوت", True, "al-ankabut"), ("الروم", True, "al-rum"),
    ("لقمان", True, "luqman"), ("السجدة", True, "al-sajda"), ("الأحزاب", False, "al-ahzab"),
    ("سبأ", True, "saba"), ("فاطر", True, "fatir"), ("يس", True, "yaseen"),
    ("الصافات", True, "al-saffat"), ("ص", True, "sad"), ("الزمر", True, "al-zumar"),
    ("غافر", True, "ghafir"), ("فصلت", True, "fussilat"), ("الشورى", True, "al-shura"),
    ("الزخرف", True, "al-zukhruf"), ("الدخان", True, "al-dukhan"), ("الجاثية", True, "al-jathiya"),
    ("الأحقاف", True, "al-ahqaf"), ("محمد", False, "muhammad"), ("الفتح", False, "al-fath"),
    ("الحجرات", False, "al-hujurat"), ("ق", True, "qaf"), ("الذاريات", True, "al-zariyat"),
    ("الطور", True, "al-tur"), ("النجم", True, "al-najm"), ("القمر", True, "al-qamar"),
    ("الرحمن", False, "al-rahman"), ("الواقعة", True, "al-waqia-26"), ("الحديد", False, "al-hadid"),
    ("المجادلة", False, "al-mujadila"), ("الحشر", False, "al-hashr"), ("الممتحنة", False, "al-mumtahina"),
    ("الصف", False, "al-saff"), ("الجمعة", False, "al-juma"), ("المنافقون", False, "al-munafiqun"),
    ("التغابن", False, "al-taghabun"), ("الطلاق", False, "al-talaq"), ("التحريم", False, "al-tahrim"),
    ("الملك", True, "al-mulk"), ("القلم", True, "al-qalam"), ("الحاقة", True, "al-haqqa"),
    ("المعارج", True, "al-maarij"), ("نوح", True, "nuh"), ("الجن", True, "al-jin"),
    ("المزمل", True, "al-muzzammil"), ("المدثر", True, "al-muddaththir"), ("القيامة", True, "al-qiyama"),
    ("الإنسان", False, "al-insan"), ("المرسلات", True, "al-mursalat"), ("النبأ", True, "al-naba"),
    ("النازعات", True, "al-naziat"), ("عبس", True, "abasa"), ("التكوير", True, "al-takwir"),
    ("الإنفطار", True, "al-infitar"), ("المطففين", True, "al-mutaffifin"), ("الانشقاق", True, "al-inshiqaq"),
    ("البروج", True, "al-buruj"), ("الطارق", True, "al-tariq"), ("الأعلى", True, "al-ala"),
    ("الغاشية", True, "al-ghashiya"), ("الفجر", True, "al-fajr"), ("البلد", True, "al-balad"),
    ("الشمس", True, "al-shams"), ("الليل", True, "al-lail"), ("الضحى", True, "al-duha"),
    ("الشرح", True, "al-sharh"), ("التين", True, "al-tin"), ("العلق", True, "al-alaq"),
    ("القدر", True, "al-qadr"), ("البينة", False, "al-bayyina"), ("الزلزلة", False, "al-zalzala"),
    ("العاديات", True, "al-adiyat"), ("القارعة", True, "al-qaria"), ("التكاثر", True, "al-takathur"),
    ("العصر", True, "al-asr"), ("الهمزة", True, "al-humaza"), ("الفيل", True, "al-fil"),
    ("قريش", True, "quraish"), ("الماعون", True, "al-maun"), ("الكوثر", True, "al-kawthar"),
    ("الكافرون", True, "al-kafirun"), ("النصر", False, "al-nasr"), ("المسد", True, "al-masad"),
    ("الإخلاص", True, "al-ikhlas"), ("الفلق", True, "al-falaq"), ("الناس", True, "al-nas")
]

new_dart_code = """class Surah {
  final String id;
  final String name;
  final String url;
  final Duration estimatedDuration;
  final bool isMakki; // true for Makki, false for Madani

  Surah({
    required this.id,
    required this.name,
    required this.url,
    required this.estimatedDuration,
    required this.isMakki,
  });

  factory Surah.fromMap(Map<String, dynamic> map) {
    return Surah(
      id: map['id'],
      name: map['name'],
      url: map['url'],
      estimatedDuration: Duration(seconds: map['estimatedDuration']),
      isMakki: map['isMakki'] ?? true,
    );
  }
}

final List<Surah> surahList = [
"""

for name, is_makki, sid in quran_meta:
    url = url_dict.get(sid, "")
    makki_str = "true" if is_makki else "false"
    # Estimate duration: just a dummy 1200 if not found in old? No, we need something generic.
    # Al-Baqara is 4800, small are 60.
    dur = 1200
    if sid == "al-baqara-22": dur = 4800
    elif sid in ["al-imran", "al-nisa", "al-maida"]: dur = 3000
    new_dart_code += f"""  Surah(
    id: "{sid}",
    name: "سورة {name}",
    url: "{url}",
    estimatedDuration: Duration(seconds: {dur}),
    isMakki: {makki_str},
  ),
"""

new_dart_code += "];\n"

with open('../lib/core/models/surah.dart', 'w', encoding='utf-8') as f:
    f.write(new_dart_code)
