import 'dart:io';

void main() {
  String data = '''سورة الأحزاب
https://www.dropbox.com/scl/fi/j5su62n6f7wso6ov1d1rh/.mp3?rlkey=efl2kiqojuky7gw64z5lvn1lp&st=pt1xonrn&dl=0
سورة الاحقاف
https://www.dropbox.com/scl/fi/jlyeazz4dp8was9qstr9j/.mp3?rlkey=74l6te7980fqgmqw7bnmmpsk7&st=d4kd1d9i&dl=0
سورة الانبياء
https://www.dropbox.com/scl/fi/i0lyba4tu5ect29mjh12v/n_2.mp3?rlkey=s6e5k7a7xh02qz4i1m3t8i52z&st=fjks5ewl&dl=0
سورة الانسان
https://www.dropbox.com/scl/fi/dzx8p7mfvcj7xp3sqby0q/.mp3?rlkey=18xyabz9qzzaoyechl8hlakk2&st=ikh7kh6b&dl=0
سورة الانفال
https://www.dropbox.com/scl/fi/njysjl99sgkid27en3xqf/3.mp3?rlkey=riwip3ifr1iokagdprt3yif6s&st=3z7wf5o8&dl=0
سورة البروج
https://www.dropbox.com/scl/fi/n4zazya0ora4kjkk178ja/.mp3?rlkey=l7i84hht8ccq0tsczixtl632b&st=q4bmcser&dl=0
سورة التوبة1
https://www.dropbox.com/scl/fi/2udjfbnvyuky2aqvfbw57/1.mp3?rlkey=qoo9sj8jkdfivjnfecs2r7hqh&st=tt7fx61y&dl=0
سورة التوبة
https://www.dropbox.com/scl/fi/8blzk8s0dntzxpwffvmyg/.mp3?rlkey=2wa1sx4gz6mszlqo5sjbnh06x&st=0gvaux06&dl=0
سورة الجاثية
https://www.dropbox.com/scl/fi/8blzk8s0dntzxpwffvmyg/.mp3?rlkey=2wa1sx4gz6mszlqo5sjbnh06x&st=0gvaux06&dl=0
سورة الجمعة
https://www.dropbox.com/scl/fi/xy6g0fwdqety3ddc0rs6j/3.mp3?rlkey=ufbtl8yzh8it4z35gg0r76sc6&st=41nz9qty&dl=0
سورة الجن
https://www.dropbox.com/scl/fi/ee1v5vejwkeniw6y8gy5m/2.mp3?rlkey=v8j5ll3w3qyz4m6ffs5g10s3o&st=ck6b4fsx&dl=0
سورة الحاقة
https://www.dropbox.com/scl/fi/b7jwf5mz1z34ky5ukrsco/.mp3?rlkey=0hph7f8shpzp8xtd3cbazbvl0&st=6xtz99r4&dl=0
سورة الدخان
https://www.dropbox.com/scl/fi/ifx6dj8m8oaj0miw5q106/2.mp3?rlkey=z86cy4kwl4zk7vtm74r975nv9&st=v8pyb29v&dl=0
سورة الحديد
https://www.dropbox.com/scl/fi/9csdp8xe0gm5bbh86ke9w/.mp3?rlkey=2xbr0xd1yp8xjimbmmqm03i67&st=odcaphax&dl=0
سورة الذاريات
https://www.dropbox.com/scl/fi/5gano27ijdytupu9rpnf5/.mp3?rlkey=9jxe530c4u3xe7nqqomd9jn0m&st=s09ju7kw&dl=0
سورة الرحمان
https://www.dropbox.com/scl/fi/a32xztams2nkei9gkoqaz/23.mp3?rlkey=0mm7gav24hw7ivgn3kzrwczwa&st=lsvsuhji&dl=0
سورة الرعد
https://www.dropbox.com/scl/fi/zb4xmqlgph22up70fgoxe/.mp3?rlkey=70fkmnqdtfqj3g6egxnp2k5zy&st=w8zwmhof&dl=0
سورة الزخرف
https://www.dropbox.com/scl/fi/zuk4etucdflijoqdsaytd/.mp3?rlkey=ia8wi2g0svmqq8er0lqgom7rm&st=l8bcsexg&dl=0
سورة الزمر
https://www.dropbox.com/scl/fi/5829yx5rjms0nz6w7s473/4.mp3?rlkey=7ctdn4pw60zpo1zs5lxlyqzbj&st=mffwn7z1&dl=0
سورة الزمر 1
https://www.dropbox.com/scl/fi/2oh2920744i2zm45e7c3e/.mp3?rlkey=g42uwznkeympvkib9v7ec4ttr&st=7wzwtlze&dl=0
سورة السجدة
https://www.dropbox.com/scl/fi/2oh2920744i2zm45e7c3e/.mp3?rlkey=g42uwznkeympvkib9v7ec4ttr&st=wnho81d0&dl=0
سورة الشورى
https://www.dropbox.com/scl/fi/lpyqowai8n778mwey9f7z/2-1.mp3?rlkey=x301i047uthd0lxeh5tza0873&st=veal83es&dl=0
سورة الفتح
https://www.dropbox.com/scl/fi/x7lej5gjzkdot4n24thuq/2-c.mp3?rlkey=15jri8mux8699ht09a863q6t9&st=etr8zj8p&dl=0
سورة الفرقان
https://www.dropbox.com/scl/fi/bo3xk1g0cqk2bagcqhd7s/.mp3?rlkey=jatpgx00zps2pg9ljocg26q4t&st=gywh4o79&dl=0
سورة القصص
https://www.dropbox.com/scl/fi/jz19eq6hin4m2x1jyqu1o/3.mp3?rlkey=u04uiczabhkufxmb79qzc6hc4&st=5njeclfu&dl=0
سورة القلم
https://www.dropbox.com/scl/fi/8ahefnvu50hb9zu9f2puk/5.mp3?rlkey=ynwrwtvbzwg0bb4y57nvz34k5&st=tna5sakk&dl=0
سورة القمر
https://www.dropbox.com/scl/fi/hxjklqbuxiwp3id81xbp7/h.mp3?rlkey=o97quvarb6abycdfaynrkumwg&st=ydljs6sn&dl=0
سورة الكهف
https://www.dropbox.com/scl/fi/g6tl44c2imcx9wtc37cgm/.mp3?rlkey=05xuo2dwqm7k8fdfq4zm3gqsp&st=wid9kfrc&dl=0
سورة القيامة
https://www.dropbox.com/scl/fi/cq5vk3y69d0n9f4nzlxof/2.mp3?rlkey=l31ffzq7boy28aihrpyi9oafp&st=0137bcbx&dl=0
سورة المائدة EL
https://www.dropbox.com/scl/fi/ugbx6p7sl3fxvtopra15q/EL-2.mp3?rlkey=cvp17j5ma21m9pfu19alxflsh&st=ln2a47t8&dl=0
سورة المائدة
https://www.dropbox.com/scl/fi/1q8dxyf9gzx5h95yvsh06/.mp3?rlkey=quymor6ab3otwvwtns63m4uyq&st=7le1jwpk&dl=0
سورة المجادلة
https://www.dropbox.com/scl/fi/vnogti321t9nn10kh2iqd/5.mp3?rlkey=viadl0oje0ih19ahcl64dzy37&st=rxesvuqy&dl=0
سورة المطففين
https://www.dropbox.com/scl/fi/7ksq6lbx637xh1lc0smsh/.mp3?rlkey=477bip18jl024ovvv66w9o95l&st=5rxjadvb&dl=0
سورة الملك
https://www.dropbox.com/scl/fi/a467isv6dhcvr9c092uku/2.mp3?rlkey=zpeno8u7r741ljbmdmvexeqdj&st=k9tkxuw2&dl=0
سورة النازعات
https://www.dropbox.com/scl/fi/31fqfdhdtjasofkekjoti/12.mp3?rlkey=4u9oqchodbesqlk02a2pbttet&st=4j459kp8&dl=0
سورة النبا
https://www.dropbox.com/scl/fi/j5sly6g6d8ecyuva6x4pb/3.mp3?rlkey=5x8lfsiswtt28jtyxtidgqogs&st=wghbuq8o&dl=0
سورة الواقعة 26
https://www.dropbox.com/scl/fi/xk6c4bqpenw5xxdfzhqe5/26.mp3?rlkey=3xukcftbzcyj1wggkkbxyjsqr&st=j1zy8mcb&dl=0
سورة ق
https://www.dropbox.com/scl/fi/lgg75rlevdp8lw1cm7nxc/.mp3?rlkey=aevw7f0vjwrqx6nqrc0hzqxse&st=38gkhs11&dl=0
سورة مريم n
https://www.dropbox.com/scl/fi/stz7dbox8ns8wyf106w2j/n.mp3?rlkey=yu1lgrs863k6vlzxvyqzzwc89&st=6xwd6v6o&dl=0
سورة يوسف
https://www.dropbox.com/scl/fi/qtssi53n6z3udqq61zvj1/26.mp3?rlkey=53uqlzj0oni8tzcfsoka4lyv4&st=q8cwfmj3&dl=0
سورة البقرة 22
https://www.dropbox.com/scl/fi/uh4at7bgnev1m6k6aw69s/hamza-medbouH-surat-baqara-1.mp3?rlkey=lolajavs7g07n8a5koixtkygm&st=l8u5kyoi&dl=0
سورة الملك S
https://www.dropbox.com/scl/fi/4odx7tbwrf2k0vmiibsma/s.mp3?rlkey=v39t64gfatiadpjnkmkgzecbb&st=b724y272&dl=0''';

  Map<String, int> quranOrder = {
    'الفاتحة': 1, 'البقرة': 2, 'آل عمران': 3, 'النساء': 4, 'المائدة': 5,
    'الأنعام': 6, 'الانعام': 6, 'الأعراف': 7, 'الاعراف': 7, 'الأنفال': 8, 'الانفال': 8,
    'التوبة': 9, 'يونس': 10, 'هود': 11, 'يوسف': 12, 'الرعد': 13,
    'إبراهيم': 14, 'ابراهيم': 14, 'الحجر': 15, 'النحل': 16, 'الإسراء': 17, 'الاسراء': 17,
    'الكهف': 18, 'مريم': 19, 'طه': 20, 'الأنبياء': 21, 'الانبياء': 21,
    'الحج': 22, 'المؤمنون': 23, 'النور': 24, 'الفرقان': 25, 'الشعراء': 26,
    'النمل': 27, 'القصص': 28, 'العنكبوت': 29, 'الروم': 30, 'لقمان': 31,
    'السجدة': 32, 'الأحزاب': 33, 'الاحزاب': 33, 'سبأ': 34, 'فاطر': 35,
    'يس': 36, 'الصافات': 37, 'ص': 38, 'الزمر': 39, 'غافر': 40,
    'فصلت': 41, 'الشورى': 42, 'الزخرف': 43, 'الدخان': 44, 'الجاثية': 45,
    'الأحقاف': 46, 'الاحقاف': 46, 'محمد': 47, 'الفتح': 48, 'الحجرات': 49,
    'ق': 50, 'الذاريات': 51, 'الطور': 52, 'النجم': 53, 'القمر': 54,
    'الرحمن': 55, 'الرحمان': 55, 'الواقعة': 56, 'الحديد': 57, 'المجادلة': 58,
    'الحشر': 59, 'الممتحنة': 60, 'الصف': 61, 'الجمعة': 62, 'المنافقون': 63,
    'التغابن': 64, 'الطلاق': 65, 'التحريم': 66, 'الملك': 67, 'القلم': 68,
    'الحاقة': 69, 'المعارج': 70, 'نوح': 71, 'الجن': 72, 'المزمل': 73,
    'المدثر': 74, 'القيامة': 75, 'الإنسان': 76, 'الانسان': 76, 'المرسلات': 77,
    'النبأ': 78, 'النبا': 78, 'النازعات': 79, 'عبس': 80, 'التكوير': 81,
    'الانفطار': 82, 'المطففين': 83, 'الانشقاق': 84, 'البروج': 85
  };

  List<String> lines = data.trim().split('\\n');
  List<Map<String, dynamic>> surahs = [];
  
  for (int i = 0; i < lines.length; i += 2) {
    String name = lines[i].trim();
    String url = lines[i+1].trim().replaceAll('dl=0', 'dl=1');
    
    String cleanName = name.replaceAll('سورة ', '');
    String baseName = cleanName.split(' ').first;
    
    int order = quranOrder[baseName] ?? 999;
    if (baseName == 'التوبة1') order = 9;
    
    surahs.add({
      'name': name,
      'url': url,
      'order': order,
      'id': 'surah_${order}_${name.replaceAll(" ", "_")}',
    });
  }

  surahs.sort((a, b) {
    int cmp = (a['order'] as int).compareTo(b['order'] as int);
    if (cmp == 0) return (a['name'] as String).compareTo(b['name'] as String);
    return cmp;
  });

  String output = 'final List<Surah> surahList = [\n';
  for (var s in surahs) {
    output += '  Surah(\n';
    output += '    id: "${s['id']}",\n';
    output += '    name: "${s['name']}",\n';
    output += '    url: "${s['url']}",\n';
    output += '    estimatedDuration: const Duration(minutes: 30),\n';
    output += '    isMakki: true,\n';
    output += '  ),\n';
  }
  output += '];\n';

  File('surahs_output.dart').writeAsStringSync(output);
}
