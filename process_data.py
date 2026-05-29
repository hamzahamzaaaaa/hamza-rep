import json

text = '''سورة الرحمان 2
https://www.dropbox.com/scl/fi/746fd75wkxypfoeuevylr/11HAMZA-MEDBOUH-SURAT-EL-RAHMAN-2.mp3?rlkey=g2hh6zcb2vufhjboz9x6913wx&st=l99mlbfi&dl=1
سورة البقرة
https://www.dropbox.com/scl/fi/c4syhdav6iwa7u8228ogf/hamza-medbouH-surat-baqara-1.mp3?rlkey=qarr4gv9ezgbpw75avr78j5x0&st=hw7j4ap9&dl=1
سورة الملك
https://www.dropbox.com/scl/fi/c4syhdav6iwa7u8228ogf/hamza-medbouH-surat-baqara-1.mp3?rlkey=qarr4gv9ezgbpw75avr78j5x0&st=hw7j4ap9&dl=1
سورة النور
https://www.dropbox.com/scl/fi/hxs0k4ra5t9uppyrv86jc/HAMZA-MEDBOUH-SURAT-Ei-NOOR.mp3?rlkey=axm3qhv8w1blo8lcje09q1xdm&st=m9bq5qdg&dl=1
سورة الرحمان
https://www.dropbox.com/scl/fi/hxs0k4ra5t9uppyrv86jc/HAMZA-MEDBOUH-SURAT-Ei-NOOR.mp3?rlkey=axm3qhv8w1blo8lcje09q1xdm&st=m9bq5qdg&dl=1
سورة الفرقان
https://www.dropbox.com/scl/fi/21gl23arvhwawfez33916/HAMZA-MEDBOUH-SURAT-Ei-FOR9AN.mp3?rlkey=kkyx8m14uu5hhp9ouxlxnxmt5&st=5ga0ltdx&dl=1
سورة القمر
https://www.dropbox.com/scl/fi/21gl23arvhwawfez33916/HAMZA-MEDBOUH-SURAT-Ei-FOR9AN.mp3?rlkey=kkyx8m14uu5hhp9ouxlxnxmt5&st=5ga0ltdx&dl=1
سورة النجم
https://www.dropbox.com/scl/fi/v4fxhlhu0kgrbavjf0lzq/HAMZA-MEDBOUH-SURAT-EL-NAJM.mp3?rlkey=1xq725jqapx0fav2v9m9s850e&st=jw05hf0g&dl=1
سورة النجم HD
https://www.dropbox.com/scl/fi/8axmwo1wlam0awdt4cnoi/HAMZA-MEDBOUH-SURAT-EL-NAJM.wav?rlkey=ty6of358kpedi7il6amjwu1gt&st=asauj1qd&dl=1
سورة القيامة
https://www.dropbox.com/scl/fi/lpxbaozool2o0tzcwk75g/HAMZA-MEDBOUH-SURAT-EL-9IYAMA.mp3?rlkey=xv402wfxiwexqulzupw3yl8py&st=4wiurh2f&dl=1
سورة الأعلى
https://www.dropbox.com/scl/fi/s8o22yvyyu4ihsvszunn1/HAMZA-MEDBOUH-SURAT-EL-A3ELA.mp3?rlkey=09iv4l0x72m4se0th4htuf0hl&st=uhxnml49&dl=1
سورة الاحقاف
https://www.dropbox.com/scl/fi/upu26q8l24g8662a98668/HAMZA-MEDBOUH-SURAT-EL-AHK9AF.mp3?rlkey=i5e7jfm17xiy63lm0s4d4h8fy&st=0elggich&dl=1
سورة الروج
https://www.dropbox.com/scl/fi/q0qfnkrhbbkktwnqg8cpa/HAMZA-MEDBOUH-SURAT-EL-BURUJ.mp3?rlkey=fkqs9d3fjitubb1oaqg9wa2n9&st=5vdqtjqc&dl=1
سورة الدخان
https://www.dropbox.com/scl/fi/nvyvzfgpzuqslv0vtungi/HAMZA-MEDBOUH-SURAT-EL-DOKHAN.mp3?rlkey=6oftw62u0yhjkr3x5zppqp0ss&st=cykttsuo&dl=1
سورة الذاريات
https://www.dropbox.com/scl/fi/z2vr8x4vgb86augc4vgv4/HAMZA-MEDBOUH-SURAT-EL-DARIYAT.mp3?rlkey=xazutqzttndzx836ke7www9gs&st=yd4rh2b2&dl=1
سورة الفجر
https://www.dropbox.com/scl/fi/5ishbm1oxom275ohfkfjr/HAMZA-MEDBOUH-SURAT-EL-FAJRE.mp3?rlkey=gp2hkz9q9yzmkvjmk7znttu0m&st=qr5gzovp&dl=1
سورة الفتح
https://www.dropbox.com/scl/fi/9ji8h9i1fse7kxzrm9m38/HAMZA-MEDBOUH-SURAT-EL-FATH-0.mp3?rlkey=ma4nyg9lqt11uyat1u1suion5&st=a9lscqlg&dl=1
سورة الحاقة
https://www.dropbox.com/scl/fi/n0a8gq8lbwx7sl8q7u93h/HAMZA-MEDBOUH-SURAT-EL-HAK9A.wav?rlkey=1dhv1srgwkbhgb4tf8qbkbqxk&st=s4q1zbkj&dl=1
سورة الحجرات
https://www.dropbox.com/scl/fi/w01dnfhtf5cu3edf1dt5c/HAMZA-MEDBOUH-SURAT-EL-HOUJORAT.mp3?rlkey=djbmf7oh8uegt6fcecd8lg38h&st=6rby7p3z&dl=1
سورة الانسان
https://www.dropbox.com/scl/fi/81s5l1qy9jcuuy3ao4esp/HAMZA-MEDBOUH-SURAT-EL-INSAN.Mp3?rlkey=tsjgbqi7uxe2ochxxh2ao4beh&st=6ab2dhsk&dl=1
سورة الاسراء
https://www.dropbox.com/scl/fi/ijpy5fooy2fmyagp9aw5g/HAMZA-MEDBOUH-SURAT-EL-ISRAE.mp3?rlkey=orclz5zclry3i6ncgw9k8jycb&st=3gjyic4c&dl=1
سورة الجاثية
https://www.dropbox.com/scl/fi/20apgr81v12v573tdzq0t/HAMZA-MEDBOUH-SURAT-EL-JATHIA.mp3?rlkey=ap1tpyqa2kxijeyiqomcb1ps1&st=fn8rig5x&dl=1
سورة الجن
https://www.dropbox.com/scl/fi/mgopyrily3kk1u1toxj34/HAMZA-MEDBOUH-SURAT-EL-JINNE.mp3?rlkey=211p3dyam7pudr6h2uvjoze3x&st=zzay4aqp&dl=1
سورة القلم
https://www.dropbox.com/scl/fi/s8m0v5axe11sfkjcq79kq/HAMZA-MEDBOUH-SURAT-EL-K9ALAM.mp3?rlkey=j6t7qp69fof10f14ripb5psk9&st=zrfck3ct&dl=1
سورة الغاشية
https://www.dropbox.com/scl/fi/55mjcdicjpm52ni6vxais/HAMZA-MEDBOUH-SURAT-EL-KAHCHIAH.mp3?rlkey=hvjudryafjj2oiglop86jyif5&st=os7y0zwg&dl=1
سورة الكهف
https://www.dropbox.com/scl/fi/hi88hvbbgmzw24aucdz37/HAMZA-MEDBOUH-SURAT-EL-KAHF-0.mp3?rlkey=aevbsvcj878n15t1lga0io2c7&st=fl07hhn9&dl=1
سورة المعارج
https://www.dropbox.com/scl/fi/2ed2k172320p6sqi5fc27/HAMZA-MEDBOUH-SURAT-EL-MA3ARIJ.mp3?rlkey=llcy96xtmqus9ywf6y871hye9&st=1ikl4ua8&dl=1
سورة الممتحنة
https://www.dropbox.com/scl/fi/0rvptcnqrrarl5a2q37v6/HAMZA-MEDBOUH-SURAT-EL-MOMTAHINA.mp3?rlkey=qlrt2r799xrnkim1n77vjvvfd&st=1h2roohz&dl=1
سورة المنافقون
https://www.dropbox.com/scl/fi/k0pi8hi2rgw5x5ufpvnvz/HAMZA-MEDBOUH-SURAT-EL-MONAFI9ON.mp3?rlkey=kxjdkfvd5dbrt8ezwjktiky8n&st=mxwmguet&dl=1
سورة المرسلات
https://www.dropbox.com/scl/fi/5buu3msxazn64evtgr5ok/HAMZA-MEDBOUH-SURAT-EL-MORSALAT.mp3?rlkey=f75ectlddtosud9kvdcczxv0z&st=0b8wutol&dl=1
سورة محمد
https://www.dropbox.com/scl/fi/4gvr3snf0osdzplkficpn/HAMZA-MEDBOUH-SURAT-EL-MOUHEMED.mp3?rlkey=peh1p78jabh02d3q0jey2t8td&st=9wxgurce&dl=1
سورة المزمل
https://www.dropbox.com/scl/fi/pdmsi94s6liiul60fgd8s/HAMZA-MEDBOUH-SURAT-EL-MOZAMIL.mp3?rlkey=8vuupeljhfvmve1ezrz56lii6&st=3t0aljko&dl=1
سورة النبا
https://www.dropbox.com/scl/fi/q9viwa850d8457w0zb02n/HAMZA-MEDBOUH-SURAT-EL-NABAE.mp3?rlkey=d26rtswb655ewpt71sh8ea8cx&st=vi4j0d9y&dl=1
سورة النجم 2
https://www.dropbox.com/scl/fi/2e5qdpkcxg0rcsysx9cuk/HAMZA-MEDBOUH-SURAT-EL-NAJM.mp3?rlkey=xiqg387h1y6ptc74x0j7vnc6e&st=ukjl4zh0&dl=1
سورة الصافات
https://www.dropbox.com/scl/fi/lnlfu6fo1a6a5githpd3l/HAMZA-MEDBOUH-SURAT-EL-SSAFF.mp3?rlkey=cz3zzvz93esg1a5bjeglutaln&st=ba3qyrk9&dl=1
سورة الملك 2
https://www.dropbox.com/scl/fi/i2k6t4rc0ixrlb1o9xlhv/HAMZA-MEDBOUH-SURAT-EL-TABARAKA.mp3?rlkey=r6nihd9oto15t83zah5cokxgi&st=wo4w0l1q&dl=1
سورة الصف
https://www.dropbox.com/scl/fi/lnlfu6fo1a6a5githpd3l/HAMZA-MEDBOUH-SURAT-EL-SSAFF.mp3?rlkey=cz3zzvz93esg1a5bjeglutaln&st=h32gtxeu&dl=1
سورة التغابن
https://www.dropbox.com/scl/fi/u5nto4tsm3g8rag9nvhjx/HAMZA-MEDBOUH-SURAT-EL-TAKABON.mp3?rlkey=73jndadjwpspm08simsoyp18m&st=a321iwu3&dl=1
سورة الطور
https://www.dropbox.com/scl/fi/n0ke1vtem6lfcknhgcwqb/HAMZA-MEDBOUH-SURAT-EL-TOOR.mp3?rlkey=de3iw0rjqn4doci8lhhw3a296&st=ql08g69m&dl=1
سورة الواقعة
https://www.dropbox.com/scl/fi/jm252zau82vp93ewp68zd/HAMZA-MEDBOUH-SURAT-EL-WA9I3A.mp3?rlkey=u4rtiyx5y758c5o5u2hc53v7r&st=zvjmwsve&dl=1
سورة ق
https://www.dropbox.com/scl/fi/olf8ojqk4m65jijswaa6d/HAMZA-MEDBOUH-SURAT-KAFE.mp3?rlkey=sk92s5tvoc3a7xqmkk1hhy6hj&st=3176h7um&dl=1
سورة مريم
https://www.dropbox.com/scl/fi/pbqjxfkvouoiytiroi83p/HAMZA-MEDBOUH-SURAT-MARIAM.mp3?rlkey=bw9z10i9yks0inwxjiv3wj6w5&st=7cqo4ren&dl=1
سورة نوح
https://www.dropbox.com/scl/fi/bb75hs5naxw6sqiran0y1/HAMZA-MEDBOUH-SURAT-NOuH.mp3?rlkey=qh6qid28eqgkvq95hrqse5217&st=i1zfii1m&dl=1
سورة سبا
https://www.dropbox.com/scl/fi/2z472l5w78ohs73alih9p/HAMZA-MEDBOUH-SURAT-SABAE.mp3?rlkey=5ubr0y792k91kdbju7xb07z9q&st=sm6wtioe&dl=1
سورة طه
https://www.dropbox.com/scl/fi/2z472l5w78ohs73alih9p/HAMZA-MEDBOUH-SURAT-SABAE.mp3?rlkey=5ubr0y792k91kdbju7xb07z9q&st=sm6wtioe&dl=1
سورة يوسف
https://www.dropbox.com/scl/fi/co3zlsh6ec9n5poeznp43/HAMZA-MEDBOUH-SURAT-YOUSSEF-1-2.mp3?rlkey=2uciyi9x84ea2tq6i8fcadq9w&st=38plw4tt&dl=1
السور الصغار
https://www.dropbox.com/scl/fi/y9g085ydajftxp9a6o9jn/HAMZA-MEDBOUH-SUWAE-SIRAR.mp3?rlkey=29166jws7x68ceezmav80q8n4&st=id7m3s61&dl=1
سورة الصافات 1
https://www.dropbox.com/scl/fi/9am0iylgwe1t0a7gce4s7/HAMZA-MEDBOUH-URAT-EL-SAFFAT-1.mp3?rlkey=l08ukq59ly8xkzi2babrfv0kr&st=vzsphms0&dl=1
سورة النجم 3
https://www.dropbox.com/scl/fi/vdyv36x3m5i24enp0rnq9/.mp3?rlkey=li20mgrmdzdhvgpotmua9g7rf&st=df81dzst&dl=1
سورة الصافات 2 HD
https://www.dropbox.com/scl/fi/nfskmfhklhaa2chi4j7g4/HAMZA-MEDBOUH-URAT-EL-SAFFAT-2.wav?rlkey=g7798alpnkzjcgmn5af2pw6m4&st=ovybiylz&dl=1
سورة إبراهيم N2
https://www.dropbox.com/scl/fi/qob513r4on5ou0hqekrzv/HAMZA-MEDBOUH-SURAT-AL-IBRAHIM-n2.mp3?rlkey=usa8608k6r4bpb6llga5elthx&st=i3yxin3k&dl=1
سورة إبراهيم
https://www.dropbox.com/scl/fi/o77kzol4s0t0lvghxk0i4/HAMZA-MEDBOUH-SURAT-AL-IBRAHIM.mp3?rlkey=9j04pem5ut1zcf5hj6udih8ea&st=lfkzrbqi&dl=1
سورة الروم n3
https://www.dropbox.com/scl/fi/26frbxg9538umpf9dsk94/HAMZA-MEDBOUH-SURAT-AL-ROOM-n3.mp3?rlkey=0nq1t7uezjgywafpycbgeqfep&st=hfookzvq&dl=1
سورة فاطر
https://www.dropbox.com/scl/fi/hj8nmo2l4kuttakhpwzxr/HAMZA-MEDBOUH-SURAT-FATIR.mp3?rlkey=rtj48g4ud230e1p57mola9q4k&st=guk7ahqe&dl=1
سورة الملك H1
https://www.dropbox.com/scl/fi/liyvphq1wu7s7vm1vswev/HAMZA-MEDBOUH-SURAT-AL-MOLK-H1.mp3?rlkey=g1nenu716ahgds09ap2gf8gt2&st=xsa8y7a4&dl=1
سورة المعارج 2 N3
https://www.dropbox.com/scl/fi/j4uanmanfh5t8yc5zcc3w/HAMZA-MEDBOUH-SURAT-AL-MA3RIJ-n3-2.mp3?rlkey=45tmiwsfbu6mq2dvqdx915blf&st=2t4xtzyf&dl=1
سورة القيامة هادئة
https://www.dropbox.com/scl/fi/y6nza6qcai4cg9nb9gine/HAMZA-MEDBOUH-SURAT-AL-9KIYAMA-HAD.mp3?rlkey=zm2zgb67debdsc9okvi4lqmma&st=la8atfpm&dl=1
سورة العنكبوت
https://www.dropbox.com/scl/fi/uk6oabvdgfsqndzp566e2/HAMZA-MEDBOUH-SURAT-EL-3ANKABOUT.mp3?rlkey=vh0eh8vbi9v01tao4umkxs7m2&st=n2qwgq7b&dl=1
سورة الحشر
https://www.dropbox.com/scl/fi/ghg922jsps089fkbzjctp/HAMZA-MEDBOUH-SURAT-EL-HACHRE.mp3?rlkey=829zbz2umirgo3zu9jkf9zp5x&st=798sacji&dl=1
سورة الحجر1
https://www.dropbox.com/scl/fi/9lrezgpfvcbwen1lhcqv1/HAMZA-MEDBOUH-SURAT-EL-HIJR-1.mp3?rlkey=9e5kr8gu4f4ji9a4r5u2vuwdo&st=15a4ogiq&dl=1
سورة الحديد
https://www.dropbox.com/scl/fi/uczvb1kywimro7qzwkdln/HAMZA-MEDBOUH-SURAT-EL-HADID.mp3?rlkey=gc2ocbvdm9w31lw0yzr0sqr70&st=tj3fgp1h&dl=1
سورة القلم
https://www.dropbox.com/scl/fi/pjl6ufdxf3w687v2qyfcl/HAMZA-MEDBOUH-SURAT-EL-KALAM.mp3?rlkey=x819ft1ox7tdkjde55h567x40&st=6hzdoudv&dl=1
سورة النمل
https://www.dropbox.com/scl/fi/5kxv356efppgqzyop9kw2/HAMZA-MEDBOUH-SURAT-EL-NAML.mp3?rlkey=r49jfcydqbifer58rgcrxavr2&st=a5wxwe9a&dl=1
سورة الملك 1-
https://www.dropbox.com/scl/fi/c682qyp35cctqjdw7u1cb/HAMZA-MEDBOUH-SURAT-MOLK-1.mp3?rlkey=td5qzgxf3636zluzq5who5a9e&st=dhfizgnt&dl=1
سورة الملك 5
https://www.dropbox.com/scl/fi/c682qyp35cctqjdw7u1cb/HAMZA-MEDBOUH-SURAT-MOLK-1.mp3?rlkey=td5qzgxf3636zluzq5who5a9e&st=o3r8vpx5&dl=1
سورة النمل 2
https://www.dropbox.com/scl/fi/f16zqvdmzlmp02bydh9p1/.mp3?rlkey=3y3ku44tanr4fxqgvt9cr7bei&st=n6svls6y&dl=1'''

order = {
    'البقرة': 2,
    'يوسف': 12,
    'إبراهيم': 14,
    'الحجر': 15,
    'الاسراء': 17,
    'الكهف': 18,
    'مريم': 19,
    'طه': 20,
    'النور': 24,
    'الفرقان': 25,
    'النمل': 27,
    'العنكبوت': 29,
    'الروم': 30,
    'سبا': 34,
    'فاطر': 35,
    'الصافات': 37,
    'الاحقاف': 46,
    'محمد': 47,
    'الفتح': 48,
    'الحجرات': 49,
    'ق': 50,
    'الذاريات': 51,
    'الطور': 52,
    'النجم': 53,
    'القمر': 54,
    'الرحمان': 55,
    'الرحمن': 55,
    'الواقعة': 56,
    'الحديد': 57,
    'الحشر': 59,
    'الممتحنة': 60,
    'الصف': 61,
    'المنافقون': 63,
    'التغابن': 64,
    'الملك': 67,
    'القلم': 68,
    'الحاقة': 69,
    'المعارج': 70,
    'نوح': 71,
    'الجن': 72,
    'المزمل': 73,
    'القيامة': 75,
    'الانسان': 76,
    'المرسلات': 77,
    'النبا': 78,
    'البروج': 85,
    'الروج': 85,
    'الأعلى': 87,
    'الغاشية': 88,
    'الفجر': 89,
    'الدخان': 44,
    'الجاثية': 45,
    'السور الصغار': 114
}

lines = [l.strip() for l in text.split('\n') if l.strip()]
items = []
for i in range(0, len(lines), 2):
    name = lines[i]
    url = lines[i+1].replace('dl=0', 'dl=1')
    
    surah_name = ''
    for k in order.keys():
        if k in name:
            surah_name = k
            break
            
    items.append((name, url, surah_name))

items.sort(key=lambda x: (order.get(x[2], 999), x[0]))

with open('lib/core/data/recordings_surah_2022.dart', 'w', encoding='utf-8') as f:
    f.write('import \'../models/surah.dart\';\n\n')
    f.write('final List<Surah> recordingsSurah2022List = [\n')
    for idx, (name, url, surah_name) in enumerate(items):
        if not name.startswith('من '):
            name = 'من ' + name
        f.write('  Surah(\n')
        f.write(f'    id: "rec_surah_2022_{idx}",\n')
        f.write(f'    name: "{name}",\n')
        f.write(f'    url: "{url}",\n')
        f.write('    estimatedDuration: const Duration(minutes: 30),\n')
        f.write('    isMakki: true,\n')
        f.write('  ),\n')
    f.write('];\n')

# Now let's fix recordings_2022.dart
with open('lib/core/data/recordings_2022.dart', 'r', encoding='utf-8') as f:
    content = f.read()

new_content = []
for line in content.split('\n'):
    if 'name: "' in line and 'سورة' in line:
        if 'name: "من ' not in line:
            line = line.replace('name: "', 'name: "من ')
    new_content.append(line)

with open('lib/core/data/recordings_2022.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_content))

print("Done")
