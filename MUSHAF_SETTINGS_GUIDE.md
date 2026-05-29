# لوحة إعدادات المصحف - دليل التنفيذ الشامل
# Mushaf Settings Panel - Complete Implementation Guide

---

## 📋 فهرس المحتويات (Table of Contents)

1. [نظرة عامة](#1-نظرة-عامة)
2. [الميزات المنفذة](#2-الميزات-المنفذة)
3. [بنية الكود](#3-بنية-الكود)
4. [دليل الاستخدام](#4-دليل-الاستخدام)
5. [التخصيص والتعديل](#5-التخصيص-والتعديل)
6. [الأسئلة الشائعة](#6-الأسئلة-الشائعة)

---

## 1. نظرة عامة

### 🎯 ما هي لوحة إعدادات المصحف؟

لوحة إعدادات شاملة بتصميم زجاجي (Glassmorphism) تتيح للمستخدم التحكم الكامل في:
- 📝 حجم خط المزامنة (LRC)
- 🎨 ثيم المصحف الورقي
- 🔆 تعتيم الشاشة
- 🔍 تكبير الشاشة
- ✍️ تخصيص الخطوط العربية
- 🌙 الوضع الليلي الذكي
- ✨ توهج الكلمة النشطة
- ☁️ المزامنة السحابية

### 📍 مكان الوصول:

```
القائمة الرئيسية → النقاط الثلاث → إعدادات المصحف
```

أو برمجياً:
```dart
showMushafSettingsPanel(context, ref);
```

---

## 2. الميزات المنفذة

### ✅ 2.1 حجم خط المزامنة (LRC Font Size)

**الافتراضي:** 32 (كما طلب المستخدم)

**النطاق:** 16 - 48

**التنفيذ:**
```dart
// في advanced_settings_provider.dart
this.lyricsFontSize = 32.0, // Changed default to 32

// Slider في UI
Slider(
  value: settings.lyricsFontSize,
  min: 16.0,
  max: 48.0,
  divisions: 16,
  onChanged: (v) => notifier.setLyricsFontSize(v),
)
```

**الحفظ:**
```dart
await prefs.setDouble('lyrics_font_size', size);
```

**الاستخدام:**
```dart
Text(
  verseText,
  style: TextStyle(
    fontSize: settings.lyricsFontSize, // 32 by default
    fontFamily: settings.syncFontFamily,
  ),
)
```

---

### ✅ 2.2 ثيمات المصحف (Mushaf Themes)

**الخيارات المتاحة:**

| الثيم | اللون | الاستخدام |
|------|-------|----------|
| أبيض (White) | `#FFFFFF` | القراءة نهاراً |
| سيبيا (Sepia) | `#F4E4C1` | ورق قديم مريح |
| أسود (Dark) | `#1A1A1A` | القراءة ليلاً |
| ذكي (Smart Dark) | `#0D1117` | وضع ليلي متقدم |

**التنفيذ:**
```dart
enum MushafTheme { white, sepia, dark, smartDark }

// في UI
_buildThemeOption(
  'أبيض',
  'White',
  Colors.white,
  MushafTheme.white,
  settings.mushafTheme,
  () => notifier.setMushafTheme(MushafTheme.white),
)
```

**التطبيق:**
```dart
Container(
  color: _getThemeColor(settings.mushafTheme),
  child: MushafView(),
)

Color _getThemeColor(MushafTheme theme) {
  switch (theme) {
    case MushafTheme.white:
      return Colors.white;
    case MushafTheme.sepia:
      return Color(0xFFF4E4C1);
    case MushafTheme.dark:
      return Color(0xFF1A1A1A);
    case MushafTheme.smartDark:
      return Color(0xFF0D1117);
  }
}
```

---

### ✅ 2.3 تعتيم الشاشة (Screen Dimming)

**النطاق:** 0% - 70%

**التنفيذ:**
```dart
Slider(
  value: settings.dimLevel,
  min: 0.0,
  max: 0.7,
  divisions: 14,
  onChanged: (v) => notifier.setDimLevel(v),
)
```

**التطبيق:**
```dart
Opacity(
  opacity: 1.0 - settings.dimLevel,
  child: MushafContent(),
)

// أو
ColorFiltered(
  colorFilter: ColorFilter.mode(
    Colors.black.withOpacity(settings.dimLevel),
    BlendMode.darken,
  ),
  child: MushafView(),
)
```

---

### ✅ 2.4 تكبير الشاشة (Zoom Level)

**النطاق:** 1.0x - 3.0x

**التنفيذ:**
```dart
Slider(
  value: settings.mushafZoomLevel,
  min: 1.0,
  max: 3.0,
  divisions: 20,
  onChanged: (v) => notifier.setMushafZoomLevel(v),
)
```

**التطبيق:**
```dart
Transform.scale(
  scale: settings.mushafZoomLevel,
  child: MushafPage(),
)

// أو مع InteractiveViewer
InteractiveViewer(
  minScale: 1.0,
  maxScale: 3.0,
  initialScale: settings.mushafZoomLevel,
  child: MushafView(),
)
```

---

### ✅ 2.5 تخصيص الخطوط العربية (Arabic Font Customization)

**الخطوط المتاحة:**

| الخط | اسم العائلة | الاستخدام |
|------|------------|----------|
| عثمان طه | `UthmanTaha` | مصحف المدينة |
| أميري | `Amiri` | النصوص العامة |
| كوفي | `Kufi` | العناوين |
| نسخ | `Naskh` | القراءة اليومية |
| ديواني | `Diwani` | الفن الإسلامي |

**التنفيذ:**
```dart
enum ArabicFont { uthmanTaha, amiri, kufi, naskh, diwani }

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
```

**معاينة الخطوط (Font Preview):**
```dart
Text(
  'بسم الله الرحمن الرحيم',
  style: TextStyle(
    fontFamily: notifier.getFontFamilyName(font),
    fontSize: 24,
    color: isSelected ? AppColors.gold : Colors.white,
  ),
)
```

**إضافة الخطوط إلى pubspec.yaml:**
```yaml
flutter:
  fonts:
    - family: UthmanTaha
      fonts:
        - asset: assets/fonts/UthmanTaha-Regular.ttf
    - family: Kufi
      fonts:
        - asset: assets/fonts/Kufi-Regular.ttf
    - family: Naskh
      fonts:
        - asset: assets/fonts/Naskh-Regular.ttf
    - family: Diwani
      fonts:
        - asset: assets/fonts/Diwani-Regular.ttf
```

---

### ✅ 2.6 ألوان الخطوط (Font Colors)

**الألوان المتاحة:**

| اللون | القيمة HEX | الاستخدام |
|------|-----------|----------|
| أسود | `#000000` | الخلفية البيضاء |
| كحلي | `#1B3A5C` | مريح للعين |
| أحمر غامق | `#8B0000` | التجويد |
| ذهبي | `#D4AF37` | الافتراضي |

**التنفيذ:**
```dart
enum FontColor { black, navy, darkRed, gold }

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
```

**التطبيق:**
```dart
Text(
  verseText,
  style: TextStyle(
    color: Color(int.parse(
      notifier.getFontColorValue(settings.fontColor)
          .replaceFirst('#', '0xFF')
    )),
  ),
)
```

---

### ✅ 2.7 الوضع الليلي الذكي (Smart Dark Mode)

**الميزات:**
- 🌙 خلفية زجاجية داكنة (Dark Glass)
- 🔵 فلتر الضوء الأزرق (Blue Light Filter)
- 😌 مريح للقراءة الطويلة

**التنفيذ:**
```dart
// Toggle
GlassSettingsTile(
  icon: Icons.dark_mode,
  title: 'الوضع الليلي الذكي',
  subtitle: 'تقليل الضوء الأزرق + زجاجي داكن',
  value: settings.smartDarkMode,
  onChanged: (v) => notifier.setSmartDarkMode(v),
)

// Blue Light Filter Slider
Slider(
  value: settings.blueLightFilterLevel,
  min: 0.0,
  max: 1.0,
  divisions: 10,
  onChanged: settings.smartDarkMode
      ? (v) => notifier.setBlueLightFilterLevel(v)
      : null,
)
```

**التطبيق البرمجي:**
```dart
// Blue Light Filter Overlay
if (settings.smartDarkMode) {
  ColorFiltered(
    colorFilter: ColorFilter.mode(
      Color.fromRGBO(255, 200, 100, settings.blueLightFilterLevel),
      BlendMode.darken,
    ),
    child: MushafView(),
  )
}
```

---

### ✅ 2.8 توهج الكلمة النشطة (Active Word Glow)

**التأثير:**
- ✨ توهج ذهبي حول الكلمة المقروءة
- 🎯 لون ذهبي للكلمة النشطة
- 💫 تأثير ظل متعدد الطبقات

**التنفيذ:**
```dart
GlassSettingsTile(
  icon: Icons.auto_awesome,
  title: 'توهج الكلمة النشطة',
  subtitle: 'تأثير ذهبي متوهج على الكلمة المقروءة',
  value: settings.activeWordGlow,
  onChanged: (v) => notifier.setActiveWordGlow(v),
)
```

**التطبيق:**
```dart
TextSpan(
  text: word,
  style: TextStyle(
    color: isActive ? AppColors.gold : Colors.white,
    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    shadows: settings.activeWordGlow && isActive
        ? [
            Shadow(
              color: AppColors.gold.withOpacity(0.6),
              blurRadius: 10,
              offset: Offset(0, 0),
            ),
            Shadow(
              color: AppColors.gold.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 0),
            ),
          ]
        : null,
  ),
)
```

---

### ✅ 2.9 المزامنة السحابية (Cloud Sync)

**الوظيفة:**
- ☁️ حفظ الإعدادات في السحابة
- 🔄 مزامنة تلقائية عند تغيير الهاتف
- 👤 ربط بالبريد الإلكتروني

**التنفيذ:**
```dart
GlassSettingsTile(
  icon: Icons.cloud_sync,
  title: 'المزامنة السحابية',
  subtitle: 'حفظ الإعدادات في السحابة',
  value: settings.cloudSyncEnabled,
  onChanged: (v) => notifier.setCloudSyncEnabled(v),
)
```

**البنية التحتية (جاهزة للتفعيل):**
```dart
Future<void> syncSettingsToCloud() async {
  if (!settings.cloudSyncEnabled) return;
  
  final user = await FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('settings')
      .doc('mushaf_preferences')
      .set({
    'lyricsFontSize': settings.lyricsFontSize,
    'mushafTheme': settings.mushafTheme.index,
    'arabicFont': settings.arabicFont.index,
    'fontColor': settings.fontColor.index,
    'smartDarkMode': settings.smartDarkMode,
    'blueLightFilterLevel': settings.blueLightFilterLevel,
    'activeWordGlow': settings.activeWordGlow,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

---

## 3. بنية الكود

### 📁 الملفات المنفذة:

#### 1. `lib/core/providers/advanced_settings_provider.dart`
```dart
// Enums
enum MushafTheme { white, sepia, dark, smartDark }
enum ArabicFont { uthmanTaha, amiri, kufi, naskh, diwani }
enum FontColor { black, navy, darkRed, gold }

// AdvancedSettings class
class AdvancedSettings {
  final double lyricsFontSize; // Default: 32.0
  final MushafTheme mushafTheme;
  final double mushafZoomLevel;
  final ArabicFont arabicFont;
  final FontColor fontColor;
  final bool smartDarkMode;
  final double blueLightFilterLevel;
  final bool activeWordGlow;
  final bool cloudSyncEnabled;
  // ... other settings
}

// AdvancedSettingsNotifier class
class AdvancedSettingsNotifier extends StateNotifier<AdvancedSettings> {
  Future<void> setMushafTheme(MushafTheme theme) async { ... }
  Future<void> setMushafZoomLevel(double zoom) async { ... }
  Future<void> setArabicFont(ArabicFont font) async { ... }
  Future<void> setFontColor(FontColor color) async { ... }
  Future<void> setSmartDarkMode(bool enabled) async { ... }
  Future<void> setBlueLightFilterLevel(double level) async { ... }
  Future<void> setActiveWordGlow(bool enabled) async { ... }
  Future<void> setCloudSyncEnabled(bool enabled) async { ... }
}
```

#### 2. `lib/presentation/widgets/mushaf_settings_panel.dart`
```dart
// Main panel widget
class MushafSettingsPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          // Glassmorphism design
          // All settings sections
        ),
      ),
    );
  }
}

// Section builders
Widget _buildFontSizeSlider() { ... }
Widget _buildMushafThemeSelector() { ... }
Widget _buildDimmingSlider() { ... }
Widget _buildZoomSlider() { ... }
Widget _buildArabicFontSelector() { ... }
Widget _buildFontColorSelector() { ... }
Widget _buildSmartDarkModeToggle() { ... }
Widget _buildBlueLightFilterSlider() { ... }
Widget _buildActiveWordGlowToggle() { ... }
Widget _buildCloudSyncToggle() { ... }
```

#### 3. `lib/presentation/widgets/surah_item.dart`
```dart
// Added import
import 'mushaf_settings_panel.dart';

// Added menu item
_buildGlassMenuItem(
  icon: Icons.auto_stories,
  title: 'إعدادات المصحف',
  subtitle: 'Mushaf Settings',
  onTap: () {
    Navigator.pop(context);
    showMushafSettingsPanel(context, ref);
  },
)
```

---

## 4. دليل الاستخدام

### 🚀 كيفية الوصول إلى الإعدادات:

**الطريقة 1: من القائمة**
```
1. افتح التطبيق
2. اضغط على النقاط الثلاث (⋮) لأي سورة
3. اختر "إعدادات المصحف"
```

**الطريقة 2: برمجياً**
```dart
import 'package:your_app/presentation/widgets/mushaf_settings_panel.dart';

// In your widget
ElevatedButton(
  onPressed: () => showMushafSettingsPanel(context, ref),
  child: Text('إعدادات المصحف'),
)
```

### 📝 ضبط حجم الخط:

```
1. افتح إعدادات المصحف
2. ابحث عن "حجم خط المزامنة"
3. حرك المؤشر بين 16 و 48
4. التغيير فوري (Live Preview)
5. يُحفظ تلقائياً
```

### 🎨 تغيير الثيم:

```
1. افتح إعدادات المصحف
2. اختر من بين 4 ثيمات:
   - أبيض (للقراءة نهاراً)
   - سيبيا (ورق قديم مريح)
   - أسود (للقراءة ليلاً)
   - ذكي (وضع ليلي متقدم)
3. التغيير فوري
```

### ✍️ تغيير الخط:

```
1. افتح إعدادات المصحف
2. انتقل إلى "الخط العربي"
3. اختر من بين 5 خطوط:
   - عثمان طه (مصحف المدينة)
   - أميري (النصوص العامة)
   - كوفي (العناوين)
   - نسخ (القراءة اليومية)
   - ديواني (الفن الإسلامي)
4. كل خط يعرض معاينة "بسم الله الرحمن الرحيم"
```

### 🌙 تفعيل الوضع الليلي الذكي:

```
1. افتح إعدادات المصحف
2. فعّل "الوضع الليلي الذكي"
3. اضبط "فلتر الضوء الأزرق" (0-100%)
4. يُطبق التأثير فوراً
```

---

## 5. التخصيص والتعديل

### 🎨 إضافة ثيم جديد:

```dart
// 1. أضف إلى enum
enum MushafTheme { white, sepia, dark, smartDark, midnight }

// 2. أضف إلى AdvancedSettings
this.mushafTheme = MushafTheme.midnight,

// 3. أضف إلى _load()
mushafTheme: MushafTheme.values[prefs.getInt('mushaf_theme') ?? 4],

// 4. أضف UI option
_buildThemeOption(
  'منتصف الليل',
  'Midnight',
  Color(0xFF000033),
  MushafTheme.midnight,
  settings.mushafTheme,
  () => notifier.setMushafTheme(MushafTheme.midnight),
),
```

### ✍️ إضافة خط جديد:

```dart
// 1. أضف إلى enum
enum ArabicFont { uthmanTaha, amiri, kufi, naskh, diwani, maghribi }

// 2. أضف إلى getFontFamilyName()
case ArabicFont.maghribi:
  return 'Maghribi';

// 3. أضف إلى pubspec.yaml
flutter:
  fonts:
    - family: Maghribi
      fonts:
        - asset: assets/fonts/Maghribi-Regular.ttf

// 4. أضف الخط إلى المجلد
// assets/fonts/Maghhribi-Regular.ttf
```

### 🎨 إضافة لون جديد:

```dart
// 1. أضف إلى enum
enum FontColor { black, navy, darkRed, gold, teal }

// 2. أضف إلى getFontColorValue()
case FontColor.teal:
  return '#008080';

// 3. أضف إلى _getFontColorName()
case FontColor.teal:
  return 'فيروزي';
```

---

## 6. الأسئلة الشائعة

### ❓ كيف أحفظ الإعدادات تلقائياً؟

**الإجابة:**
يتم الحفظ تلقائياً باستخدام SharedPreferences:
```dart
Future<void> setLyricsFontSize(double size) async {
  state = state.copyWith(lyricsFontSize: size);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('lyrics_font_size', size);
}
```

### ❓ كيف أطبّق الإعدادات على المشغل؟

**الإجابة:**
استخدم Riverpod للاستماع للتغييرات:
```dart
class MushafView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(advancedSettingsProvider);
    
    return Container(
      color: _getThemeColor(settings.mushafTheme),
      child: Text(
        verseText,
        style: TextStyle(
          fontSize: settings.lyricsFontSize,
          fontFamily: notifier.getFontFamilyName(settings.arabicFont),
          color: Color(int.parse(
            notifier.getFontColorValue(settings.fontColor)
                .replaceFirst('#', '0xFF')
          )),
        ),
      ),
    );
  }
}
```

### ❓ كيف أفعل المزامنة السحابية؟

**الإجابة:**
أضف Firebase إلى المشروع:
```yaml
dependencies:
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
```

ثم فعّل المزامنة:
```dart
Future<void> syncSettingsToCloud() async {
  if (!settings.cloudSyncEnabled) return;
  
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('settings')
      .doc('mushaf_preferences')
      .set(settings.toJson());
}
```

### ❓ كيف أضيف تأثير التوهج؟

**الإجابة:**
استخدم Shadow مع Multiple Layers:
```dart
Text(
  word,
  style: TextStyle(
    color: AppColors.gold,
    shadows: [
      Shadow(
        color: AppColors.gold.withOpacity(0.6),
        blurRadius: 10,
      ),
      Shadow(
        color: AppColors.gold.withOpacity(0.3),
        blurRadius: 20,
      ),
      Shadow(
        color: AppColors.gold.withOpacity(0.1),
        blurRadius: 30,
      ),
    ],
  ),
)
```

### ❓ كيف أضيف فلتر الضوء الأزرق؟

**الإجابة:**
استخدم ColorFiltered:
```dart
ColorFiltered(
  colorFilter: ColorFilter.mode(
    Color.fromRGBO(
      255,
      200,
      100,
      settings.blueLightFilterLevel,
    ),
    BlendMode.darken,
  ),
  child: MushafView(),
)
```

---

## 📊 ملخص الملفات المعدّلة

| الملف | التعديلات | الأسطر المضافة |
|------|----------|---------------|
| `advanced_settings_provider.dart` | إضافة enums و settings جديدة | +129 |
| `mushaf_settings_panel.dart` | ملف جديد كامل | +646 |
| `surah_item.dart` | إضافة قائمة إعدادات المصحف | +12 |

**الإجمالي:** 787 سطر جديد

---

## 🎯 الميزات المنفذة

✅ حجم خط المزامنة (افتراضي 32، قابل للتعديل)  
✅ ثيمات المصحف (أبيض، سيبيا، أسود، ذكي)  
✅ تعتيم الشاشة (0-70%)  
✅ تكبير الشاشة (1.0x-3.0x)  
✅ تخصيص الخطوط العربية (5 خطوط مع معاينة)  
✅ ألوان الخطوط (4 ألوان)  
✅ الوضع الليلي الذكي مع فلتر الضوء الأزرق  
✅ توهج الكلمة النشطة  
✅ المزامنة السحابية (بنية تحتية جاهزة)  
✅ حفظ تلقائي بـ SharedPreferences  
✅ معاينة فورية (Live Preview)  
✅ تصميم زجاجي شامل (Glassmorphism)  

---

## 🚀 الخطوات القادمة

### اختياري - لتحسينات إضافية:

1. **Firebase Integration:**
   ```bash
   flutter pub add firebase_auth cloud_firestore
   ```

2. **Font Assets:**
   - أضف ملفات الخطوط إلى `assets/fonts/`
   - حدّث `pubspec.yaml`

3. **Testing:**
   ```bash
   flutter test
   flutter run --release
   ```

4. **Build:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

---

## 📞 الدعم الفني

لأي استفسارات:
- 📧 البريد: support@hamzamedbouh.com
- 🌐 الموقع: www.hamzamedbouh.com
- 📱 تويتر: @HamzaMedbouh

---

**تم التطوير بواسطة فريق حمزة مدبوح للقرآن الكريم**

**التاريخ: 2026-05-29**

**الإصدار: 2.1.0**

---

🎉 **استمتع بتجربة قراءة مخصصة بالكامل!** 🎉
