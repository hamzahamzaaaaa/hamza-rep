import urllib.parse
text = '''تسجيلات 2022(2 من سورة سبا 1-
https://www.dropbox.com/scl/fi/rc3t5flql8myljg88x4b1/ayat-min-sorat-sabe-hamzamedbouh-1.mp3?rlkey=tcu8eelhvm5cewxe42xm8m42u&st=mlnxmq37&dl=0
من سورة سبا
https://www.dropbox.com/scl/fi/jxkp8j9avgfbyg04p7u3x/ayat-min-sorat-sabe-hamzamedbouh.mp3?rlkey=gyan5ha6kh7d1z0t63o85je30&st=g388vag5&dl=0
من سورة الانعام
https://www.dropbox.com/scl/fi/tzyxdezjrn0q1umvnb04v/ayayt-min-sorat-el-AN3AM.mp3?rlkey=ncru0ashzk1fjgmbixxnk3uek&st=nipxa10r&dl=0
من سورة الانبياء
https://www.dropbox.com/scl/fi/gqdvexavyxkxbgihmf198/ayayt-min-sorat-el-anbiaa.mp3?rlkey=qgfgs85kmbvjwqerb8k2potu2&st=6p152wt1&dl=0
من سورة العتكبوت
https://www.dropbox.com/scl/fi/ozzeuyjrhnkpl3t2fgkvn/ayayt-min-sorat-el-ankaboot.mp3?rlkey=mlclz5ewy83a02m8j3289itdf&st=qd2in0tu&dl=0
من سورة البقرة 1
https://www.dropbox.com/scl/fi/i2cv1637x5b3okkaoo49d/ayayt-min-sorat-el-baqara-1.mp3?rlkey=ficqrgfkfbu4ymf1s2x6y05wk&st=35tw4xp3&dl=0
من سورة البقرة 2
https://www.dropbox.com/scl/fi/0jyd5ug9oxyb6eobn82lt/ayayt-min-sorat-el-baqara-2.mp3?rlkey=mk2liulrig1syadyc5rjess5g&st=ghftas0s&dl=0
من سورة البقرة 2
https://www.dropbox.com/scl/fi/uqrrk3d92ue9s0fgrlq65/ayayt-min-sorat-el-baqara-3.mp3?rlkey=66wz6tu4id2e6sfpklf9b22a3&st=19f77tp2&dl=0
من سورة البقرة 3
https://www.dropbox.com/scl/fi/uqrrk3d92ue9s0fgrlq65/ayayt-min-sorat-el-baqara-3.mp3?rlkey=66wz6tu4id2e6sfpklf9b22a3&st=h8f6n1a9&dl=0
من سورة البقرة 4
https://www.dropbox.com/scl/fi/4lhszr9s7tbtt4vp0sw79/ayayt-min-sorat-el-baqara-4.mp3?rlkey=ilihlrbtw7oyoze52smk0i9s0&st=cxm43o5i&dl=0
من سورة البقرة 3-
https://www.dropbox.com/scl/fi/eyxcooye1z03f27nzao4b/ayayt-min-sorat-el-baqara.mp3?rlkey=d2jteck7yra8105qdjov7nq5v&st=143t0f98&dl=0
من سورة البقرة
https://www.dropbox.com/scl/fi/eyxcooye1z03f27nzao4b/ayayt-min-sorat-el-baqara.mp3?rlkey=d2jteck7yra8105qdjov7nq5v&st=f3r63irl&dl=0
من سورة الحديد
https://www.dropbox.com/scl/fi/ttpjn01jzvs1vtrh9jw6f/ayayt-min-sorat-el-HADID.mp3?rlkey=ajn3lm9govppzdfhtpz19rxx7&st=c0n9jsr9&dl=0
من سورة الحجر 2
https://www.dropbox.com/scl/fi/067lh45lf79orpabcswx4/ayayt-min-sorat-el-hijre-2.mp3?rlkey=88lzt7tg0k9c1s166p6ukisch&st=pt7addj0&dl=0
من سورة الحجر 3
https://www.dropbox.com/scl/fi/mgjl67oc91i0d1j0gtko0/ayayt-min-sorat-el-hijre-3.mp3?rlkey=6ey4h1s3aemiiof3z0yranrky&st=bngze1xi&dl=0
من سورة الحجر
https://www.dropbox.com/scl/fi/36qv29srdn2n886qlk93t/ayayt-min-sorat-el-hijre.mp3?rlkey=whovhv5c40m39zczclq6ozksx&st=ltlnnyzj&dl=0
من سورة الحجرات
https://www.dropbox.com/scl/fi/h3por2tnk7a4mb2ezsanm/ayayt-min-sorat-el-houjorat.mp3?rlkey=7cr8vuckjmis8eipvvlruvm0t&st=hq4vd2dl&dl=0
من سورة الجن 1
https://www.dropbox.com/scl/fi/grkc4rirjm7ztuygpusic/ayayt-min-sorat-el-jine-1.mp3?rlkey=no6abea5x4r2shui0a9fu0ffz&st=cs8tnwlb&dl=0
من سورة الجن
https://www.dropbox.com/scl/fi/tyifno8ntuhep3f4gsu24/ayayt-min-sorat-el-jine.mp3?rlkey=xq6rjxgjgb2bco4r3c1r30w1x&st=916oz09r&dl=0
من سورة ق 1
https://www.dropbox.com/scl/fi/vd7w2kygt10hog7y7u7ea/ayayt-min-sorat-el-Kafe-1.mp3?rlkey=rwpsp03mioq0jc4lrvv1508pc&st=40wslrs9&dl=0
من سورة ق
https://www.dropbox.com/scl/fi/ppeibb5q1aadflqjkc279/ayayt-min-sorat-el-Kafe.mp3?rlkey=i8obslfxx9302vpqicgiozjys&st=2n7yxvb4&dl=0
من سورة الكهف
https://www.dropbox.com/scl/fi/apo50i5ng93t72075sf27/ayayt-min-sorat-el-kahf.mp3?rlkey=fzfvdcqim65m068ov3ldd09xu&st=pzn5mc72&dl=0
من سورة المائدة 1
https://www.dropbox.com/scl/fi/cnqo68rsji5m8fww51t3c/ayayt-min-sorat-el-maida-1.mp3?rlkey=2xedroy3efbkpq0cnpva5drqe&st=ricghbxk&dl=0
من سورة المائدة 2
https://www.dropbox.com/scl/fi/djoxysnrb1leobh937a1f/ayayt-min-sorat-el-maida-2.mp3?rlkey=yaugqw8lmefre8av0sycwf4z7&st=0j7reyst&dl=0
من سورة المائدة 3
https://www.dropbox.com/scl/fi/5bf7thy7x9il0wpmd5pzl/ayayt-min-sorat-el-maida-3.mp3?rlkey=gzkh10wkirpfbja4zqzrn3m0x&st=y4pe22s5&dl=0
من سورة المائدة 4
https://www.dropbox.com/scl/fi/vga2vzhlgu2gklxuqhjst/ayayt-min-sorat-el-maida-4.mp3?rlkey=lgfq627r3b38ai6hw8er7we5j&st=e61e2czg&dl=0
من سورة المائدة
https://www.dropbox.com/scl/fi/447a863he14hi8ls8f60s/ayayt-min-sorat-el-maida.mp3?rlkey=hjzyr7kylbz8vi593pzp7wk46&st=josiij2x&dl=0
من سورة المؤمنون 1
https://www.dropbox.com/scl/fi/0q9h90v0dlzhvjw5jlfod/ayayt-min-sorat-el-moueminoun-1.mp3?rlkey=d55dl34rczegknpixhetmhyue&st=98i8hm62&dl=0
من سورة المؤمنون 2
https://www.dropbox.com/scl/fi/dkpwku9weksyi0zr1jaxi/ayayt-min-sorat-el-moueminoun-2.mp3?rlkey=uzovrs9oq72cfflxx8ixjksgd&st=b4vpvgae&dl=0
من سورة المؤمنون 3
https://www.dropbox.com/scl/fi/smpzueiyrptxb3sjh2367/ayayt-min-sorat-el-moueminoun-3.mp3?rlkey=xant9i49w72zro09bclegoi17&st=zz2n5nsj&dl=0
من سورة النحل 1
https://www.dropbox.com/scl/fi/tiqeseymuymytpb6kzmam/ayayt-min-sorat-el-nahl-1.mp3?rlkey=visxrigsicphk4ndznkk8pfll&st=6xo6j35c&dl=0
من سورة النحل 2
https://www.dropbox.com/scl/fi/dmcp04qwbxjb55ni27qdn/ayayt-min-sorat-el-nahl-2.mp3?rlkey=85qrt4pq2c2uq1rnzwucp6vga&st=vr15w8tf&dl=0
من سورة النحل 3
https://www.dropbox.com/scl/fi/ix8qoamk7nbio67x0wj83/ayayt-min-sorat-el-nahl-3.mp3?rlkey=1990zm6eczwboxglx4c8q65z4&st=jgj81bme&dl=0
من سورة النحل
https://www.dropbox.com/scl/fi/p743fu0iyg0noio115f1b/ayayt-min-sorat-el-nahl.mp3?rlkey=a1p34bb5fnyv7cz69d7hoi2kx&st=n6m0wz4h&dl=0
من سورة النجم
https://www.dropbox.com/scl/fi/0c0hyisahjcwk66w6sykd/ayayt-min-sorat-el-najme.mp3?rlkey=63nbpaqcub1mc5l2mqulblhsz&st=706ruddk&dl=0
من سورة النساء 1
https://www.dropbox.com/scl/fi/qiil4hnvg15swpdyytxn5/ayayt-min-sorat-el-nissaa-1.mp3?rlkey=4ja469j266bmda8hj5stxm1qv&st=swav8de3&dl=0
من سورة النساء 3
https://www.dropbox.com/scl/fi/d4wmh8arn4734pfkfjwqc/ayayt-min-sorat-el-nissaa-3.mp3?rlkey=kd6ihz69m7dkf21tbjp91v1bb&st=no4bgwi9&dl=0
من سورة النساء 4
https://www.dropbox.com/scl/fi/nb3b709s23eud4cqj3dli/ayayt-min-sorat-el-nissaa-4.mp3?rlkey=sgw9jbn0aiitqouni16ldoekk&st=d20jghp8&dl=0
من سورة النساء 5
https://www.dropbox.com/scl/fi/0yo8fed8ot89epa7bz2th/ayayt-min-sorat-el-nissaa-5.mp3?rlkey=w8sv97xext14vvuzdpun08neh&st=7a5esb44&dl=0
من سورة النساء 6
https://www.dropbox.com/scl/fi/uuwj0dtzhsoqb5tz3h0j5/ayayt-min-sorat-el-nissaa-6.mp3?rlkey=7yfal1f37x4dm8qi7883snong&st=9f33lqot&dl=0
من سورة النساء
https://www.dropbox.com/scl/fi/5rt5y0ni7b1bhvwctktvb/ayayt-min-sorat-el-nissaa.mp3?rlkey=zkaplxbvjxz07h9zvitxdxu8g&st=bwjyndju&dl=0
من سورة الرعد
https://www.dropbox.com/scl/fi/gnz7fzrxws5qpsve8o91m/ayayt-min-sorat-el-raad.mp3?rlkey=2m0nitny4xa5jqf4vbtmjnz3w&st=6mauhr9v&dl=0
من سورة الروم
https://www.dropbox.com/scl/fi/w3v0ogz1y1d5gi4yyteln/ayayt-min-sorat-el-roome.mp3?rlkey=w0ptz6vz9n4osegldv2s4jpf0&st=9mvxqg5e&dl=0
من سورة الصافات
https://www.dropbox.com/scl/fi/8w593gp95py15kb2uoki3/ayayt-min-sorat-el-saffat.mp3?rlkey=xze3n3j4ncof3mcdkg7ji2t08&st=b9s5jhpd&dl=0
من سورة الواقعة
https://www.dropbox.com/scl/fi/4mwqrpw42rhzpg8ztfz0c/ayayt-min-sorat-el-wa9I3A.mp3?rlkey=2e7jargj24j83xflgk41hqnul&st=jkie08g1&dl=0
من سورة الزمر
https://www.dropbox.com/scl/fi/t3e7699i1njftgahqbido/ayayt-min-sorat-el-zomar.mp3?rlkey=kpkoyshmh355sfg2wj7wxb0gf&st=aeqbvdbl&dl=0
من سورة فصلت 1
https://www.dropbox.com/scl/fi/vpnw3vr84qn6zxp972ape/ayayt-min-sorat-eli-FOSSLET-1.mp3?rlkey=ls8dmmsd6zjvs206di5mc87pd&st=ek7tnt2t&dl=0
من سورة فصلت
https://www.dropbox.com/scl/fi/kyvylvey6qwdacsvmxs2r/ayayt-min-sorat-eli-FOSSLET.mp3?rlkey=xjkvrla1prc428hruyfetbbfe&st=a6wnxtx9&dl=0
ايات من سورة الحج 1
https://www.dropbox.com/scl/fi/5wh7bbfyx65gtfwedwkzt/ayayt-min-sorat-eli-HAJE-1.mp3?rlkey=lsmw117dm2ltp5xjr7mv09ft9&st=a7bviok0&dl=0
ايات من سورة الحج 2
https://www.dropbox.com/scl/fi/s7tqjq6z4mo8sx36f68lg/ayayt-min-sorat-eli-HAJE-2.mp3?rlkey=db8si7cnlhv7r0pyncrjkrwy9&st=0zmo0165&dl=0
ايات من سورة الحج
https://www.dropbox.com/scl/fi/zlujujqpjupdypv1l65yd/ayayt-min-sorat-eli-HAJE.mp3?rlkey=mvw9y1egoquiynp13ermaypx3&st=4efa5dkx&dl=0
من سورة ال عمران تلاوة 1
https://www.dropbox.com/scl/fi/j0mjkrgskkdd7ofel46gy/ayayt-min-sorat-eli-imrane-1.mp3?rlkey=12mqlltt3j6wsyd455s9qhz8i&st=7aehw7qv&dl=0
من سورة ال عمران  تلاوة 2
https://www.dropbox.com/scl/fi/h13boweborfnqleh4x3c7/ayayt-min-sorat-eli-imrane-2.mp3?rlkey=lz3ml3ky8ktkdldo8rm6wpr03&st=5ba2gq4f&dl=0
من سورة ال عمران تلاوة 3
https://www.dropbox.com/scl/fi/ozvn8lcjljgfnw83me1y2/ayayt-min-sorat-eli-imrane-3.mp3?rlkey=mwfolkwzu96qfmj2jfqzxpbue&st=qd8ym9zq&dl=0
من سورة ال عمران تلاوة 4
https://www.dropbox.com/scl/fi/xc635wgjyg6w7zzxcu0f3/ayayt-min-sorat-eli-imrane-4.mp3?rlkey=562j14tuez6g6yaqtm7a3hl3f&st=9lp2s2xq&dl=0
من سورة ال عمران تلاوة 5
https://www.dropbox.com/scl/fi/zu9mpitprkbugpl2u4yab/ayayt-min-sorat-eli-imrane-5.mp3?rlkey=9bc6b8b4p4kk2qqg306evje9b&st=n7q4maat&dl=0
من سورة ال عمران تلاوة 6
https://www.dropbox.com/scl/fi/t2mbcfnpkhl0khqd98w1u/ayayt-min-sorat-eli-imrane-6.mp3?rlkey=r9ebbtp1271vgya9s3wafhk48&st=tagqqdtq&dl=0
من سورة ال عمران تلاوة 7
https://www.dropbox.com/scl/fi/dh5tc9czuzzxx7hi9xpfc/ayayt-min-sorat-eli-imrane-7.mp3?rlkey=cthsatmozy429uer2dxxpc7lv&st=l46ll6yd&dl=0
من سورة ال عمران 8
https://www.dropbox.com/scl/fi/tbqpbyth49rlcanbow8ve/ayayt-min-sorat-eli-imrane-8.mp3?rlkey=ihey5sxp55t4endpsmdxapc1x&st=f046i02u&dl=0
من سورة ال عمران
https://www.dropbox.com/scl/fi/8epumm7lgb8dimoaz64ql/ayayt-min-sorat-eli-imrane.mp3?rlkey=w6pqpefzv62i8zrvbee00tn4d&st=cnflbymm&dl=0
من سورة ابراهيم 1
https://www.dropbox.com/scl/fi/81k51ib9pdyfks6wt5s9s/ayayt-min-sorat-IBRAHIM-1.mp3?rlkey=dgmcl6hdfy79v8adr2c6ym1a7&st=hvntk1ux&dl=0
من سورة ابراهيم
https://www.dropbox.com/scl/fi/9qoj1n7liuw7hrsunav3m/ayayt-min-sorat-IBRAHIM.mp3?rlkey=1jnmg2erjroanewxfzni7e4zo&st=che947u4&dl=0
من سورة غافر
https://www.dropbox.com/scl/fi/mgtoke6vigbth5xp8o6rc/ayayt-min-sorat-kafir.mp3?rlkey=jjuyhu4snfqbh448uoy1m634q&st=n46lvr40&dl=0
من سورة مريم 1
https://www.dropbox.com/scl/fi/ws5bpd47hivobpsrvn0lu/ayayt-min-sorat-MARIAM-1.mp3?rlkey=4580qaxwkgr94u5oikch2p5m5&st=q3zpy40b&dl=0
من سورة مريم 2
https://www.dropbox.com/scl/fi/bi7up80epha3eel645138/ayayt-min-sorat-MARIAM-2.mp3?rlkey=bjjqfosnjpb1vx0l7fcgoyy5t&st=f75q4w9l&dl=0
من سورة مريم 3
https://www.dropbox.com/scl/fi/2getn6oxoi6a9q2o82h71/ayayt-min-sorat-MARIAM-3.mp3?rlkey=tpphockw1sonb6drz7zhm8imr&st=fb1smbrt&dl=0
من سورة مريم 4
https://www.dropbox.com/scl/fi/8hfln5och6yib3aqspnnc/ayayt-min-sorat-MARIAM-4.mp3?rlkey=cknsemwyu9m5yn4o4ezo7ob1h&st=9x8832wj&dl=0
من سورة مريم
https://www.dropbox.com/scl/fi/ctrj5vgfi8504xqp075yj/ayayt-min-sorat-MARIAM.mp3?rlkey=moeeahmb9b9lu9qt39smu4fwo&st=5wtgf915&dl=0
من سورة ص 1
https://www.dropbox.com/scl/fi/q2a3tju7sznq32twfyac7/ayayt-min-sorat-sade-1.mp3?rlkey=cr488a2r5vppxvpm0nswh7xlb&st=iw56ra45&dl=0
من سورة ص 2
https://www.dropbox.com/scl/fi/kp3203h8ding6cewyh4mj/ayayt-min-sorat-sade-2.mp3?rlkey=p86b0ryw2ue2adnanxjmqype8&st=sivc4bp3&dl=0
من سورة ص
https://www.dropbox.com/scl/fi/cf53gddut4mulsmain1yx/ayayt-min-sorat-sade.mp3?rlkey=uvph5y7ah8geb4ji4ds0h6fqw&st=jm6vmu55&dl=0
من سورة طه 1
https://www.dropbox.com/scl/fi/ieza5k383sdh17oyade6o/ayayt-min-sorat-taha-1.mp3?rlkey=8f1wwz06pbjaakj9pzdfzflsf&st=qvr4w8tn&dl=0
من سورة طه 2
https://www.dropbox.com/scl/fi/m8yok36nvyonywkmdjrtw/ayayt-min-sorat-taha-2.mp3?rlkey=nhec6zs9f67sfbvervnunltnk&st=y4t2yoa8&dl=0
من سورة طه
https://www.dropbox.com/scl/fi/025xk47uks6gmf5rkra2w/ayayt-min-sorat-taha.mp3?rlkey=ynbbnmgn3cscp55pwgox0kbq2&st=9zgbxurl&dl=0
'''

order = {
    'البقرة': 2,
    'ال عمران': 3,
    'النساء': 4,
    'المائدة': 5,
    'الانعام': 6,
    'الرعد': 13,
    'ابراهيم': 14,
    'الحجر': 15,
    'النحل': 16,
    'الكهف': 18,
    'مريم': 19,
    'طه': 20,
    'الانبياء': 21,
    'الحج': 22,
    'المؤمنون': 23,
    'العتكبوت': 29,  # typo in input
    'الروم': 30,
    'سبا': 34,
    'الصافات': 37,
    'ص': 38,
    'الزمر': 39,
    'غافر': 40,
    'فصلت': 41,
    'الحجرات': 49,
    'ق': 50,
    'النجم': 53,
    'الواقعة': 56,
    'الحديد': 57,
    'الجن': 72
}

lines = [l.strip() for l in text.split('\n') if l.strip()]
if lines[0].startswith('تسجيلات'):
    lines[0] = 'من سورة سبا 1'

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

with open('lib/core/data/recordings_2022.dart', 'w', encoding='utf-8') as f:
    f.write('import \\'package:medbouh_flutter/core/models/surah.dart\\';\\n\\n')
    f.write('final List<Surah> recordings2022List = [\\n')
    for idx, (name, url, surah_name) in enumerate(items):
        clean_name = name.replace("ايات", "").replace("من", "").strip()
        f.write('  Surah(\\n')
        f.write(f'    id: "rec_2022_{idx}",\\n')
        f.write(f'    name: "{clean_name}",\\n')
        f.write(f'    url: "{url}",\\n')
        f.write('    estimatedDuration: const Duration(minutes: 30),\\n')
        f.write('    isMakki: true,\\n')
        f.write('  ),\\n')
    f.write('];\\n')
