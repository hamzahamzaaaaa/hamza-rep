import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/advanced_settings_provider.dart';

/// خط لـ LRC يمثل آية مع توقيتها
class LrcLine {
  final Duration time;
  final String text;
  final int verseNumber; // رقم الآية
  final int pageNumber; // رقم الصفحة في المصحف

  LrcLine({
    required this.time,
    required this.text,
    required this.verseNumber,
    required this.pageNumber,
  });
}

/// بيانات إحداثيات الآية
class VerseCoordinates {
  final int pageNumber;
  final int verseNumber;
  final double x; // الموضع الأفقي
  final double y; // الموضع الرأسي
  final double width;
  final double height;

  VerseCoordinates({
    required this.pageNumber,
    required this.verseNumber,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// المحرك الديناميكي للمصحف الشريف
/// يجلب الصور والإحداثيات تلقائياً من الإنترنت
class DynamicQuranEngine extends StatefulWidget {
  final String surahId;
  final Duration position;
  final String? lrcUrl;
  final String surahName;

  const DynamicQuranEngine({
    super.key,
    required this.surahId,
    required this.position,
    this.lrcUrl,
    required this.surahName,
  });

  @override
  State<DynamicQuranEngine> createState() => _DynamicQuranEngineState();
}

class _DynamicQuranEngineState extends State<DynamicQuranEngine>
    with TickerProviderStateMixin {
  // حالة التحميل
  bool _isLoading = true;
  String? _errorMessage;

  // صورة الصفحة الحالية
  String? _currentPageImageUrl;
  int _currentPageNumber = 1;

  // بيانات LRC
  List<LrcLine> _lyrics = [];
  int _currentVerseIndex = -1;

  // إحداثيات الآيات
  Map<int, List<VerseCoordinates>> _verseCoordinatesMap = {};
  
  // مؤثرات الحركة للتظليل الذهبي
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Dio للتحميل
  final Dio _dio = Dio();

  // نظام التحميل الذكي - Pre-caching
  int _lastCachedPage = 0;
  bool _isPreCaching = false;

  @override
  void initState() {
    super.initState();

    // تهيئة مؤثر الحركة
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _glowAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // تحميل البيانات
    _loadLyrics();
  }

  @override
  void didUpdateWidget(DynamicQuranEngine oldWidget) {
    super.didUpdateWidget(oldWidget);

    // إعادة التحميل عند تغيير السورة
    if (oldWidget.surahId != widget.surahId ||
        oldWidget.lrcUrl != widget.lrcUrl) {
      _loadLyrics();
      setState(() {
        _currentVerseIndex = -1;
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _dio.close();
    super.dispose();
  }

  /// تحميل بيانات LRC
  Future<void> _loadLyrics() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      String? fileContent;

      if (widget.lrcUrl != null && widget.lrcUrl!.startsWith('http')) {
        final response = await _dio.get(widget.lrcUrl!);
        fileContent = response.data.toString();
      } else {
        // تحميل من assets
        try {
          fileContent = await DefaultAssetBundle.of(context)
              .loadString('assets/lyrics/${widget.surahId}.lrc');
        } catch (_) {
          throw Exception('LRC file not found');
        }
      }

      if (fileContent == null) throw Exception('LRC content is null');

      // تحليل LRC
      final parsedLines = _parseLRC(fileContent);
      
      setState(() {
        _lyrics = parsedLines;
        _isLoading = false;
      });

      // تحميل إحداثيات الآيات للصفحات المطلوبة
      await _loadVerseCoordinates();

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في تحميل البيانات: $e';
      });
    }
  }

  /// تحليل ملف LRC
  List<LrcLine> _parseLRC(String content) {
    final RegExp timeRegex = RegExp(r'\[(\d{1,2}):(\d{1,2})[.:](\d{1,3})\](.*)');
    final List<LrcLine> lines = [];
    int verseNum = 1;

    // استخراج رقم السورة من المعرف
    final surahNumber = _extractSurahNumber();

    for (final line in content.split('\n')) {
      final match = timeRegex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisText = match.group(3)!;
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          int milliseconds = int.parse(millisText);
          if (millisText.length == 1) milliseconds *= 100;
          if (millisText.length == 2) milliseconds *= 10;

          // حساب رقم الصفحة التقريبي بناءً على رقم الآية
          final pageNumber = _getApproximatePageNumber(surahNumber, verseNum);

          lines.add(LrcLine(
            time: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: milliseconds,
            ),
            text: text,
            verseNumber: verseNum,
            pageNumber: pageNumber,
          ));

          verseNum++;
        }
      }
    }

    return lines;
  }

  /// استخراج رقم السورة
  int? _extractSurahNumber() {
    final match = RegExp(r'surah_(\d+)').firstMatch(widget.surahId);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  /// حساب رقم الصفحة بدقة باستخدام خريطة شاملة
  /// هذه الخريطة تحتوي على رقم الصفحة الأولى لكل سورة
  int _getApproximatePageNumber(int? surahNumber, int verseNumber) {
    if (surahNumber == null) return 1;

    // خريطة دقيقة لبداية كل سورة في المصحف (مصحف المدينة)
    const surahStartPages = {
      1: 1,    // الفاتحة
      2: 2,    // البقرة
      3: 50,   // آل عمران
      4: 77,   // النساء
      5: 106,  // المائدة
      6: 128,  // الأنعام
      7: 151,  // الأعراف
      8: 177,  // الأنفال
      9: 187,  // التوبة
      10: 208, // يونس
      11: 221, // هود
      12: 235, // يوسف
      13: 249, // الرعد
      14: 255, // إبراهيم
      15: 262, // الحجر
      16: 267, // النحل
      17: 282, // الإسراء
      18: 293, // الكهف
      19: 305, // مريم
      20: 312, // طه
      21: 322, // الأنبياء
      22: 332, // الحج
      23: 342, // المؤمنون
      24: 350, // النور
      25: 359, // الفرقان
      26: 367, // الشعراء
      27: 377, // النمل
      28: 385, // القصص
      29: 396, // العنكبوت
      30: 404, // الروم
      31: 411, // لقمان
      32: 415, // السجدة
      33: 418, // الأحزاب
      34: 428, // سبأ
      35: 434, // فاطر
      36: 440, // يس
      37: 446, // الصافات
      38: 453, // ص
      39: 458, // الزمر
      40: 467, // غافر
      41: 477, // فصلت
      42: 483, // الشورى
      43: 489, // الزخرف
      44: 496, // الدخان
      45: 499, // الجاثية
      46: 502, // الأحقاف
      47: 507, // محمد
      48: 511, // الفتح
      49: 515, // الحجرات
      50: 518, // ق
      51: 520, // الذاريات
      52: 523, // الطور
      53: 526, // النجم
      54: 528, // القمر
      55: 531, // الرحمن
      56: 534, // الواقعة
      57: 537, // الحديد
      58: 542, // المجادلة
      59: 545, // الحشر
      60: 549, // الممتحنة
      61: 551, // الصف
      62: 553, // الجمعة
      63: 554, // المنافقون
      64: 556, // التغابن
      65: 558, // الطلاق
      66: 560, // التحريم
      67: 562, // الملك
      68: 564, // القلم
      69: 566, // الحاقة
      70: 568, // المعارج
      71: 570, // نوح
      72: 572, // الجن
      73: 574, // المزمل
      74: 575, // المدثر
      75: 577, // القيامة
      76: 578, // الإنسان
      77: 580, // المرسلات
      78: 582, // النبأ
      79: 583, // النازعات
      80: 585, // عبس
      81: 586, // التكوير
      82: 587, // الانفطار
      83: 587, // المطففين
      84: 589, // الانشقاق
      85: 590, // البروج
      86: 591, // الطارق
      87: 591, // الأعلى
      88: 592, // الغاشية
      89: 593, // الفجر
      90: 594, // البلد
      91: 595, // الشمس
      92: 595, // الليل
      93: 596, // الضحى
      94: 596, // الشرح
      95: 597, // التين
      96: 597, // العلق
      97: 598, // القدر
      98: 598, // البينة
      99: 599, // الزلزلة
      100: 599, // العاديات
      101: 600, // القارعة
      102: 600, // التكاثر
      103: 601, // العصر
      104: 601, // الهمزة
      105: 601, // الفيل
      106: 602, // قريش
      107: 602, // الماعون
      108: 602, // الكوثر
      109: 603, // الكافرون
      110: 603, // النصر
      111: 603, // المسد
      112: 604, // الإخلاص
      113: 604, // الفلق
      114: 604, // الناس
    };

    final startPage = surahStartPages[surahNumber] ?? 1;
    
    // عدد الآيات التقريبي لكل صفحة (متوسط)
    const avgVersesPerPage = 15.0;
    
    // حساب عدد الصفحات الإضافية بناءً على رقم الآية
    final additionalPages = (verseNumber / avgVersesPerPage).floor();
    
    // التأكد من عدم تجاوز الحد الأقصى (604 صفحات)
    final calculatedPage = startPage + additionalPages;
    return calculatedPage.clamp(1, 604);
  }

  /// تحميل إحداثيات الآيات من API
  Future<void> _loadVerseCoordinates() async {
    try {
      // جمع الصفحات الفريدة المطلوبة
      final uniquePages = _lyrics.map((l) => l.pageNumber).toSet().toList();

      for (final pageNumber in uniquePages) {
        if (_verseCoordinatesMap.containsKey(pageNumber)) continue;

        // محاولة تحميل الإحداثيات من API
        final coordinates = await _fetchVerseCoordinates(pageNumber);
        if (coordinates != null) {
          _verseCoordinatesMap[pageNumber] = coordinates;
        }
      }
    } catch (e) {
      print('⚠️ خطأ في تحميل الإحداثيات: $e');
    }
  }

  /// جلب إحداثيات الآيات من Quran.com API
  Future<List<VerseCoordinates>?> _fetchVerseCoordinates(int pageNumber) async {
    try {
      // استخدام Quran.com API للحصول على بيانات الصفحة
      // ملاحظة: هذا API تجريبي وقد يحتاج لتعديل
      final url = 'https://api.quran.com/api/v4/quran/verses/uthmani';
      
      final response = await _dio.get(url, queryParameters: {
        'page_number': pageNumber,
        'fields': 'verse_key,page_number',
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final verses = data['verses'] as List?;
        
        if (verses != null) {
          final coordinates = <VerseCoordinates>[];
          
          // حساب مواقع تقريبية للآيات
          // في الإنتاج الحقيقي، يجب استخدام بيانات word_corpus الدقيقة
          for (int i = 0; i < verses.length; i++) {
            final verse = verses[i];
            final verseKey = verse['verse_key'] as String;
            final verseNum = int.parse(verseKey.split(':')[1]);

            // حساب تقريبي للموقع (يجب استبداله ببيانات حقيقية)
            final coords = _calculateApproximatePosition(
              pageNumber,
              verseNum,
              i,
              verses.length,
            );

            coordinates.add(coords);
          }

          return coordinates;
        }
      }
    } catch (e) {
      print('⚠️ فشل في جلب الإحداثيات: $e');
    }

    //Fallback: إنشاء إحداثيات تقريبية
    return _generateFallbackCoordinates(pageNumber);
  }

  /// إنشاء إحداثيات تقريبية للآيات
  List<VerseCoordinates> _generateFallbackCoordinates(int pageNumber) {
    final coordinates = <VerseCoordinates>[];
    
    // افتراض: 15 سطر في الصفحة، ~2 آية في كل سطر
    const linesPerPage = 15;
    const lineHeight = 0.055; // 5.5% من ارتفاع الصفحة
    const lineWidth = 0.84; // 84% من عرض الصفحة
    const lineStartX = 0.08; // 8% من اليسار
    
    // تقدير عدد الآيات في الصفحة
    const estimatedVersesPerPage = 25;

    for (int i = 0; i < estimatedVersesPerPage; i++) {
      final lineIndex = (i / 2).floor() % linesPerPage;
      final verseInLine = i % 2;

      final y = 0.05 + (lineIndex * lineHeight);
      final x = lineStartX + (verseInLine == 0 ? 0.0 : lineWidth / 2);
      final width = lineWidth / 2;
      final height = lineHeight * 0.9;

      coordinates.add(VerseCoordinates(
        pageNumber: pageNumber,
        verseNumber: i + 1,
        x: x,
        y: y,
        width: width,
        height: height,
      ));
    }

    return coordinates;
  }

  /// حساب موقع تقريبي للآية
  VerseCoordinates _calculateApproximatePosition(
    int pageNumber,
    int verseNumber,
    int index,
    int totalVerses,
  ) {
    const linesPerPage = 15;
    final lineHeight = 0.055;
    final lineWidth = 0.84;
    final lineStartX = 0.08;

    final lineIndex = (index / 2).floor() % linesPerPage;
    final verseInLine = index % 2;

    final y = 0.05 + (lineIndex * lineHeight);
    final x = lineStartX + (verseInLine == 0 ? 0.0 : lineWidth / 2);
    final width = lineWidth / 2;
    final height = lineHeight * 0.9;

    return VerseCoordinates(
      pageNumber: pageNumber,
      verseNumber: verseNumber,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  /// الحصول على الآية الحالية
  int _getCurrentVerseIndex() {
    if (_lyrics.isEmpty) return -1;

    int currentIndex = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_lyrics[i].time <= widget.position) {
        currentIndex = i;
      } else {
        break;
      }
    }
    return currentIndex;
  }

  /// تحديث الصفحة الحالية
  void _updateCurrentPage() {
    if (_currentVerseIndex < 0 || _currentVerseIndex >= _lyrics.length) return;

    final currentVerse = _lyrics[_currentVerseIndex];
    final newPageNumber = currentVerse.pageNumber;

    if (newPageNumber != _currentPageNumber) {
      setState(() {
        _currentPageNumber = newPageNumber;
        _currentPageImageUrl = _getPageImageUrl(newPageNumber);
      });

      // تحميل إحداثيات الصفحة الجديدة
      if (!_verseCoordinatesMap.containsKey(newPageNumber)) {
        _fetchVerseCoordinates(newPageNumber).then((coords) {
          if (coords != null && mounted) {
            setState(() {
              _verseCoordinatesMap[newPageNumber] = coords;
            });
          }
        });
      }

      // بدء التحميل الذكي للصفحات المجاورة
      _preCacheNearbyPages(newPageNumber);
    }
  }

  /// نظام التحميل الذكي - تحميل الصفحات المجاورة مسبقاً
  Future<void> _preCacheNearbyPages(int currentPage) async {
    if (_isPreCaching) return;
    
    // التأكد من عدم إعادة تحميل نفس الصفحة
    if (currentPage == _lastCachedPage) return;
    
    _isPreCaching = true;
    _lastCachedPage = currentPage;

    try {
      // تحميل الصفحات الثلاثة التالية والثلاثة السابقة
      final pagesToCache = <int>[];
      
      // الصفحات التالية
      for (int i = 1; i <= 3; i++) {
        final nextPage = currentPage + i;
        if (nextPage <= 604) {
          pagesToCache.add(nextPage);
        }
      }
      
      // الصفحات السابقة
      for (int i = 1; i <= 2; i++) {
        final prevPage = currentPage - i;
        if (prevPage >= 1) {
          pagesToCache.add(prevPage);
        }
      }

      // تحميل الصفحات في الخلفية
      for (final pageNum in pagesToCache) {
        if (!_verseCoordinatesMap.containsKey(pageNum)) {
          // تحميل الإحداثيات
          await _fetchVerseCoordinates(pageNum);
        }
        
        // تحميل الصورة إلى الذاكرة المؤقتة
        final imageUrl = _getPageImageUrl(pageNum);
        await _preCacheImage(imageUrl);
      }

      if (mounted) {
        print('✅ تم التحميل الذكي للصفحات: ${pagesToCache.join(", ")}');
      }
    } catch (e) {
      print('⚠️ خطأ في التحميل الذكي: $e');
    } finally {
      _isPreCaching = false;
    }
  }

  /// تحميل صورة واحدة إلى الذاكرة المؤقتة
  Future<void> _preCacheImage(String imageUrl) async {
    try {
      // استخدام DefaultCacheManager لتحميل الصورة مسبقاً
      await DefaultCacheManager().getFileStream(imageUrl).first;
    } catch (e) {
      // print('⚠️ فشل في تحميل الصورة المؤقتة: $e');
    }
  }

  /// الحصول على رابط صورة الصفحة من Quran.com
  String _getPageImageUrl(int pageNumber) {
    // استخدام صور عالية الجودة من Quran.com
    return 'https://image.qurancdn.com/v3/qdc-cms/images/$pageNumber.png';
    
    // بديل: استخدام صور من kingfahadcomplex
    // return 'https://quran.ksu.edu.sa/images/page$pageNumber.png';
  }

  @override
  Widget build(BuildContext context) {
    // تحديث فهرس الآية الحالية
    final newIndex = _getCurrentVerseIndex();
    if (newIndex != _currentVerseIndex) {
      setState(() {
        _currentVerseIndex = newIndex;
      });
      _updateCurrentPage();
      _glowController.forward(from: 0.0);
    }

    // عرض مؤشر التحميل
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFB8860B),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'جاري تحميل المصحف...',
                style: TextStyle(
                  color: Color(0xFFB8860B),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // عرض رسالة الخطأ
    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Stack ملء الشاشة
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black, // إخفاء صورة القارئ تماماً
      child: Stack(
        children: [
          // طبقة صورة الصفحة (مع Caching)
          if (_currentPageImageUrl != null)
            Center(
              child: CachedNetworkImage(
                imageUrl: _currentPageImageUrl!,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFB8860B),
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
              ),
            ),

          // طبقة التظليل الذهبي مع خلفية ملونة
          if (_currentVerseIndex >= 0)
            Positioned.fill(
              child: CustomPaint(
                painter: GoldenHighlightPainter(
                  verseCoordinates: _getVerseCoordinates(),
                  currentVerseIndex: _currentVerseIndex,
                  glowAnimation: _glowAnimation,
                  verseText: _currentVerseIndex < _lyrics.length
                      ? _lyrics[_currentVerseIndex].text
                      : '',
                  backgroundColorHex: _getBackgroundColorHex(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// الحصول على إحداثيات الآية الحالية
  VerseCoordinates? _getVerseCoordinates() {
    if (_currentVerseIndex < 0 || _currentVerseIndex >= _lyrics.length) {
      return null;
    }

    final currentVerse = _lyrics[_currentVerseIndex];
    final pageCoords = _verseCoordinatesMap[_currentPageNumber];

    if (pageCoords == null) return null;

    // البحث عن إحداثيات الآية
    return pageCoords.firstWhere(
      (coord) => coord.verseNumber == currentVerse.verseNumber,
      orElse: () => pageCoords.isNotEmpty ? pageCoords.first : 
        VerseCoordinates(
          pageNumber: _currentPageNumber,
          verseNumber: currentVerse.verseNumber,
          x: 0.1,
          y: 0.5,
          width: 0.8,
          height: 0.05,
        ),
    );
  }

  /// الحصول على لون الخلفية من الإعدادات
  String _getBackgroundColorHex() {
    // Default to gold, can be customized via settings
    return '#D4AF37';
  }
}

/// راسم التظليل الذهبي الملكي
class GoldenHighlightPainter extends CustomPainter {
  final VerseCoordinates? verseCoordinates;
  final int currentVerseIndex;
  final Animation<double> glowAnimation;
  final String verseText;
  final String backgroundColorHex;

  GoldenHighlightPainter({
    required this.verseCoordinates,
    required this.currentVerseIndex,
    required this.glowAnimation,
    required this.verseText,
    this.backgroundColorHex = '#D4AF37',
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (verseCoordinates == null) return;

    final glowValue = glowAnimation.value;
    final coords = verseCoordinates!;

    // تحويل الإحداثيات النسبية إلى إحداثيات فعلية
    final rect = Rect.fromLTWH(
      coords.x * size.width,
      coords.y * size.height,
      coords.width * size.width,
      coords.height * size.height,
    );

    // الخلفية الملونة بدون تشويه - تدرج لوني ناعم
    final bgColor = _hexToColor(backgroundColorHex);
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          bgColor.withOpacity(0.15 * glowValue),
          bgColor.withOpacity(0.25 * glowValue),
          bgColor.withOpacity(0.15 * glowValue),
        ],
      ).createShader(rect);

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(8),
    );

    canvas.drawRRect(rrect, backgroundPaint);

    // التظليل الذهبي الشفاف الأساسي
    final baseHighlightPaint = Paint()
      ..color = bgColor.withOpacity(0.2 * glowValue)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, baseHighlightPaint);

    // رسم التدرج الذهبي المتألق فوق التظليل الأساسي
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          bgColor.withAlpha((60 * glowValue).round()),
          bgColor.withAlpha((100 * glowValue).round()),
          bgColor.withAlpha((60 * glowValue).round()),
        ],
      ).createShader(rect);

    canvas.drawRRect(rrect, gradientPaint);

    // تأثير اللمعة
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withAlpha((30 * glowValue).round()),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawRRect(rrect, shinePaint);

    // حدود ذهبية
    final borderPaint = Paint()
      ..color = bgColor.withAlpha((150 * glowValue).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(rrect, borderPaint);

    // ظل خارجي
    final shadowPaint = Paint()
      ..color = bgColor.withAlpha((50 * glowValue).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawRRect(rrect.inflate(2), shadowPaint);
  }

  Color _hexToColor(String hex) {
    final hexClean = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexClean', radix: 16));
  }

  @override
  bool shouldRepaint(covariant GoldenHighlightPainter oldDelegate) {
    return oldDelegate.verseCoordinates != verseCoordinates ||
        oldDelegate.glowAnimation.value != glowAnimation.value ||
        oldDelegate.backgroundColorHex != backgroundColorHex;
  }
}
