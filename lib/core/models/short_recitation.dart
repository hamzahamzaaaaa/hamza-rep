import 'surah.dart';

class ShortRecitation {
  final String id;
  final String aliasName; // Example: 'تلاوة هادئة'
  final String originalName; // Example: 'سورة البقرة'
  final String url;
  final String? lrcUrl;

  ShortRecitation({
    required this.id,
    required this.aliasName,
    required this.originalName,
    required this.url,
    this.lrcUrl,
  });

  // Convert to Surah model for the player
  Surah toSurah() {
    return Surah(
      id: id,
      name: aliasName, // Use alias name for display in player
      url: url,
      lrcUrl: lrcUrl,
      estimatedDuration: const Duration(minutes: 5), // Generic
      isMakki: true,
      category: 'Short Recitations',
    );
  }
}

final List<ShortRecitation> shortRecitationsList = [
  ShortRecitation(
    id: 'short_1',
    aliasName: '✨ تلاوة خاشعة تريح القلوب.. استمع الآن 🌙',
    originalName: 'سورة طه',
    url: 'https://www.dropbox.com/scl/fi/sizsomjc6n1hirlf2jqsk/.mp3?rlkey=5f9iir09k8agzjtxwhujynffo&st=y63mq8mo&dl=1',
  ),
  ShortRecitation(
    id: 'short_2',
    aliasName: '💎 آيات السكينة.. لمن يبحث عن هدوء البال 🕯️',
    originalName: 'سورة مريم',
    url: 'https://www.dropbox.com/scl/fi/stz7dbox8ns8wyf106w2j/n.mp3?rlkey=yu1lgrs863k6vlzxvyqzzwc89&st=6xwd6v6o&dl=1',
  ),
  ShortRecitation(
    id: 'short_3',
    aliasName: '📜 مقطع يأخذك إلى عالم آخر.. هدوء لا يوصف 🤍',
    originalName: 'سورة الكهف',
    url: 'https://www.dropbox.com/scl/fi/g6tl44c2imcx9wtc37cgm/.mp3?rlkey=05xuo2dwqm7k8fdfq4zm3gqsp&st=wid9kfrc&dl=1',
  ),
  ShortRecitation(
    id: 'short_4',
    aliasName: '🌧️ درر قرآنية تجلي الهموم.. سورة الرحمن بصوت شجي ✨',
    originalName: 'سورة الرحمن',
    url: 'https://www.dropbox.com/scl/fi/a32xztams2nkei9gkoqaz/23.mp3?rlkey=0mm7gav24hw7ivgn3kzrwczwa&st=lsvsuhji&dl=1',
  ),
  ShortRecitation(
    id: 'short_5',
    aliasName: '🛡️ تحصين وراحة.. أواخر سورة الحشر المباركة 📖',
    originalName: 'سورة الحشر',
    url: 'https://www.dropbox.com/scl/fi/x7lej5gjzkdot4n24thuq/2-c.mp3?rlkey=15jri8mux8699ht09a863q6t9&st=etr8zj8p&dl=1',
  ),
  ShortRecitation(
    id: 'short_6',
    aliasName: '🌿 تلاوة من عالم آخر تذهب بالهم والغم 🕊️',
    originalName: 'سورة يوسف',
    url: 'https://www.dropbox.com/scl/fi/qtssi53n6z3udqq61zvj1/26.mp3?rlkey=53uqlzj0oni8tzcfsoka4lyv4&st=q8cwfmj3&dl=1',
  ),
  ShortRecitation(
    id: 'short_7',
    aliasName: '🌟 لمحات من الجمال القرآني.. سورة ق 💎',
    originalName: 'سورة ق',
    url: 'https://www.dropbox.com/scl/fi/lgg75rlevdp8lw1cm7nxc/.mp3?rlkey=aevw7f0vjwrqx6nqrc0hzqxse&st=38gkhs11&dl=1',
  ),
  ShortRecitation(
    id: 'short_8',
    aliasName: '🔥 آيات الوعيد والرجاء.. سورة القيامة بصوت مبكي 🕯️',
    originalName: 'سورة القيامة',
    url: 'https://www.dropbox.com/scl/fi/cq5vk3y69d0n9f4nzlxof/2.mp3?rlkey=l31ffzq7boy28aihrpyi9oafp&st=0137bcbx&dl=1',
  ),
  ShortRecitation(
    id: 'short_9',
    aliasName: '🌈 رحلة إيمانية في سورة النجم ✨',
    originalName: 'سورة النجم',
    url: 'https://www.dropbox.com/scl/fi/hxjklqbuxiwp3id81xbp7/h.mp3?rlkey=o97quvarb6abycdfaynrkumwg&st=ydljs6sn&dl=1',
  ),
  ShortRecitation(
    id: 'short_10',
    aliasName: '🕌 صلاة التراويح.. هدوء وطمأنينة 🌙',
    originalName: 'سورة الملك',
    url: 'https://www.dropbox.com/scl/fi/4odx7tbwrf2k0vmiibsma/s.mp3?rlkey=v39t64gfatiadpjnkmkgzecbb&st=b724y272&dl=1',
  ),
];
