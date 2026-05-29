import re

data = """سورة القمر 
https://youtu.be/YPpsppxS0s8
سورة الأحزاب
https://youtu.be/ETgSsf6oL9g
سورة يس
https://youtu.be/imZwZgLGV2s
أذكار الصباح والمساء
https://youtu.be/4KhC8jzpF6g
سورة المعارج
https://youtu.be/8iqZgpI2P5A
سورة الزخرف
https://youtu.be/xZgmssjP6sc
سورة السجدة
https://youtu.be/UY4wLLksQes
سورة الأنفال
https://youtu.be/jnjXz6Crflc
سورة الروم
https://youtu.be/4X6XzITABQk
سورة فصلت
https://youtu.be/rEDFhKA1roM
سورة المطففين
https://youtu.be/ht7O3rO8Qes
سورة الكهف
https://youtu.be/AYu4ywjeWwc
سورة الدخان
https://youtu.be/LSSOh4lXTiE
سورة الملك
https://youtu.be/DwLtFMBy7iA
سورة المائدة
https://youtu.be/APkpqqf6pyk
سورة طه
https://youtu.be/jJU_tSAxfko
سورة القصص
https://youtu.be/LKQsABxTA6M
سورة التوبة
https://youtu.be/On7nw0wFgK4
سورة الواقعة
https://youtu.be/IRyTjiKhD4Y
سورة الزمر
https://youtu.be/d-D6HEmIN_U
سورة الشورى
https://youtu.be/unhDP0XAAiU
سورة مريم
https://youtu.be/FPGO6F25PKU
سورة ق
https://youtu.be/IfDy4huqx90
سورة يوسف
https://youtu.be/qtn1Y2uUHXk
سورة القيامة
https://youtu.be/_cRRX445sAU
سورة الجن
https://youtu.be/x33ujHNhmLA
سورة الحديد
https://youtu.be/4z6KzVEY5Zk
سورة الرعد 
https://youtu.be/apopfCDeuq0 
سورة فاطر 
https://youtu.be/dCN1MnGrAi0
سورة الفتح 
https://youtu.be/BnCt9iZG6Mk 
سورة الحاقة 
https://youtu.be/mNwKuZzyVoE 
سورة الفرقان 
https://youtu.be/Cp7a9tcWxfs 
سورة الجاثية 
https://youtu.be/gqCtAslCPZI
سورة المطففين 
https://youtu.be/ucEK1mr5MA4 
سورة الأنبياء 
https://youtu.be/p4liJ1dji7U
سورة النحل 
https://youtu.be/J75Xveh8ukc 
سورة البروج 
https://youtu.be/zpjSJmLDmKc 
سورة المزمل
https://youtu.be/sSYbwjMhd6A 
سورة لقمان 
https://youtu.be/UcSRCXCKtzI 
سورة النازعات 
https://youtu.be/H8itpytFIaU 
سورة محمد 
https://youtu.be/zTy2tmVL0PM 
سورة القمر 2
https://youtu.be/xVsQcfLtYmo
سورة نوح
https://youtu.be/D20s41osHKU
سورة المجادلة 
https://youtu.be/EewzddTuw8o
سورة الروم
https://youtu.be/r5xHz4JbI2o
سورة الرمر 2
https://youtu.be/6r27LYDD49Y 
سورة الذاريات 
https://youtu.be/9Uheq1JEqBM 
سورة النجم 
https://youtu.be/XCMFe3HqHxs 
سورة الأحقاف 
https://youtu.be/R5A_mRJ4EKU 
سورة يوسف 
https://youtu.be/ks2_wuWk_KI 
سورة النبأ 
https://youtu.be/D6zCgsIixW8 
سورة الجمعة 
https://youtu.be/6oH7UgBRBuU"""

lines = [line.strip() for line in data.split("\n") if line.strip()]

output = ["import '../models/surah.dart';", "", "final List<Surah> recordingsHqList = ["]

for i in range(0, len(lines), 2):
    name = lines[i]
    url = lines[i+1]
    
    surah_id = f"hq_{i//2}"
    output.append(f"""  Surah(
    id: "{surah_id}",
    name: "{name}",
    url: "{url}",
    estimatedDuration: const Duration(minutes: 30),
    isMakki: true,
  ),""")

output.append("];")

with open("lib/core/data/recordings_hq.dart", "w", encoding="utf-8") as f:
    f.write("\n".join(output))

print("Created recordings_hq.dart")
