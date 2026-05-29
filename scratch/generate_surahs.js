const fs = require('fs');

const oldContent = fs.readFileSync('../lib/core/models/surah.dart', 'utf-8');

const urlDict = {};
const blocks = oldContent.split('Surah(');
for (let i = 1; i < blocks.length; i++) {
    const idMatch = blocks[i].match(/id:\s*"([^"]+)"/);
    const urlMatch = blocks[i].match(/url:\s*"([^"]+)"/);
    if (idMatch && urlMatch) {
        urlDict[idMatch[1]] = urlMatch[1];
    }
}

const quranMeta = [
    ["الفاتحة", true, "al-fatiha"], ["البقرة", false, "al-baqara-22"], ["آل عمران", false, "al-imran"],
    ["النساء", false, "al-nisa"], ["المائدة", false, "al-maida"], ["الأنعام", true, "al-anam"],
    ["الأعراف", true, "al-araf"], ["الأنفال", false, "al-anfal"], ["التوبة", false, "al-tawba"],
    ["يونس", true, "yunus"], ["هود", true, "hud"], ["يوسف", true, "yusuf"],
    ["الرعد", false, "al-rad"], ["إبراهيم", true, "ibrahim"], ["الحجر", true, "al-hijr"],
    ["النحل", true, "al-nahl"], ["الإسراء", true, "al-isra"], ["الكهف", true, "al-kahf"],
    ["مريم", true, "maryam"], ["طه", true, "taha"], ["الأنبياء", true, "al-anbiya"],
    ["الحج", false, "al-hajj"], ["المؤمنون", true, "al-muminun"], ["النور", false, "al-nur"],
    ["الفرقان", true, "al-furqan"], ["الشعراء", true, "al-shuara"], ["النمل", true, "al-naml"],
    ["القصص", true, "al-qasas"], ["العنكبوت", true, "al-ankabut"], ["الروم", true, "al-rum"],
    ["لقمان", true, "luqman"], ["السجدة", true, "al-sajda"], ["الأحزاب", false, "al-ahzab"],
    ["سبأ", true, "saba"], ["فاطر", true, "fatir"], ["يس", true, "yaseen"],
    ["الصافات", true, "al-saffat"], ["ص", true, "sad"], ["الزمر", true, "al-zumar"],
    ["غافر", true, "ghafir"], ["فصلت", true, "fussilat"], ["الشورى", true, "al-shura"],
    ["الزخرف", true, "al-zukhruf"], ["الدخان", true, "al-dukhan"], ["الجاثية", true, "al-jathiya"],
    ["الأحقاف", true, "al-ahqaf"], ["محمد", false, "muhammad"], ["الفتح", false, "al-fath"],
    ["الحجرات", false, "al-hujurat"], ["ق", true, "qaf"], ["الذاريات", true, "al-zariyat"],
    ["الطور", true, "al-tur"], ["النجم", true, "al-najm"], ["القمر", true, "al-qamar"],
    ["الرحمن", false, "al-rahman"], ["الواقعة", true, "al-waqia-26"], ["الحديد", false, "al-hadid"],
    ["المجادلة", false, "al-mujadila"], ["الحشر", false, "al-hashr"], ["الممتحنة", false, "al-mumtahina"],
    ["الصف", false, "al-saff"], ["الجمعة", false, "al-juma"], ["المنافقون", false, "al-munafiqun"],
    ["التغابن", false, "al-taghabun"], ["الطلاق", false, "al-talaq"], ["التحريم", false, "al-tahrim"],
    ["الملك", true, "al-mulk"], ["القلم", true, "al-qalam"], ["الحاقة", true, "al-haqqa"],
    ["المعارج", true, "al-maarij"], ["نوح", true, "nuh"], ["الجن", true, "al-jin"],
    ["المزمل", true, "al-muzzammil"], ["المدثر", true, "al-muddaththir"], ["القيامة", true, "al-qiyama"],
    ["الإنسان", false, "al-insan"], ["المرسلات", true, "al-mursalat"], ["النبأ", true, "al-naba"],
    ["النازعات", true, "al-naziat"], ["عبس", true, "abasa"], ["التكوير", true, "al-takwir"],
    ["الإنفطار", true, "al-infitar"], ["المطففين", true, "al-mutaffifin"], ["الانشقاق", true, "al-inshiqaq"],
    ["البروج", true, "al-buruj"], ["الطارق", true, "al-tariq"], ["الأعلى", true, "al-ala"],
    ["الغاشية", true, "al-ghashiya"], ["الفجر", true, "al-fajr"], ["البلد", true, "al-balad"],
    ["الشمس", true, "al-shams"], ["الليل", true, "al-lail"], ["الضحى", true, "al-duha"],
    ["الشرح", true, "al-sharh"], ["التين", true, "al-tin"], ["العلق", true, "al-alaq"],
    ["القدر", true, "al-qadr"], ["البينة", false, "al-bayyina"], ["الزلزلة", false, "al-zalzala"],
    ["العاديات", true, "al-adiyat"], ["القارعة", true, "al-qaria"], ["التكاثر", true, "al-takathur"],
    ["العصر", true, "al-asr"], ["الهمزة", true, "al-humaza"], ["الفيل", true, "al-fil"],
    ["قريش", true, "quraish"], ["الماعون", true, "al-maun"], ["الكوثر", true, "al-kawthar"],
    ["الكافرون", true, "al-kafirun"], ["النصر", false, "al-nasr"], ["المسد", true, "al-masad"],
    ["الإخلاص", true, "al-ikhlas"], ["الفلق", true, "al-falaq"], ["الناس", true, "al-nas"]
];

let newCode = `class Surah {
  final String id;
  final String name;
  final String url;
  final Duration estimatedDuration;
  final bool isMakki;

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
`;

for (const [name, isMakki, sid] of quranMeta) {
    const url = urlDict[sid] || "";
    const makkiStr = isMakki ? "true" : "false";
    let dur = 1200;
    if (sid === "al-baqara-22") dur = 4800;
    else if (["al-imran", "al-nisa", "al-maida"].includes(sid)) dur = 3000;
    
    newCode += `  Surah(
    id: "${sid}",
    name: "سورة ${name}",
    url: "${url}",
    estimatedDuration: Duration(seconds: ${dur}),
    isMakki: ${makkiStr},
  ),
`;
}

newCode += "];\n";

fs.writeFileSync('../lib/core/models/surah.dart', newCode, 'utf-8');
console.log("Done");
