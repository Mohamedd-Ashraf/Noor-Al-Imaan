import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:qcf_quran/qcf_quran.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/tajweed_parser.dart';
import '../widgets/app_qcf_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NurAyahTestScreen
// عرض سورة النور (٢٤) الآية ٣٥ بخمس طرق مختلفة
// الطريقة المثلى: QCF + تجويد كلمة بكلمة (مثل quran.com تماماً)
// ─────────────────────────────────────────────────────────────────────────────
//
//  الصفحة في المصحف الشريف (رواية حفص): 354
//  مفتاح الآية: 24:35
//
// ─────────────────────────────────────────────────────────────────────────────

const int _kSurah = 24;
const int _kAyah = 35;
const int _kPage = 354; // صفحة الآية في المصحف (حفص عن عاصم)
const String _kPageFont = 'QCF_P$_kPage'; // QCF_P354

class NurAyahTestScreen extends StatefulWidget {
  const NurAyahTestScreen({super.key});

  @override
  State<NurAyahTestScreen> createState() => _NurAyahTestScreenState();
}

class _NurAyahTestScreenState extends State<NurAyahTestScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── data holders ──────────────────────────────────────────────────────────
  // Synchronous — available immediately from local qcf_quran package (no API)
  final String _uthmaniText = getVerse(_kSurah, _kAyah, verseEndSymbol: false);
  final String _qcfGlyphText =
      getVerseQCF(_kSurah, _kAyah, verseEndSymbol: false);

  // Asynchronous — fetched from alquran.cloud tajweed API
  String? _tajweedRaw;
  List<TajweedRule?> _wordRules = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 5 tabs: ①QCF+Tajweed ②QCF-clean ③Uthmani ④Tajweed-colored ⑤Page-full
    _tabController = TabController(length: 5, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── fetch only tajweed data (everything else comes from the local package) ──
  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tajweedRaw = await _fetchTajweed();
      if (mounted) {
        setState(() {
          _tajweedRaw = tajweedRaw;
          _wordRules = _extractWordRules(tajweedRaw);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<String> _fetchTajweed() async {
    final url = Uri.parse(
      'https://api.alquran.cloud/v1/ayah/$_kSurah:$_kAyah/quran-tajweed',
    );
    final r = await http
        .get(url, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return (data['data'] as Map<String, dynamic>)['text'] as String;
    }
    throw Exception('AlQuran.cloud API: ${r.statusCode}');
  }

  // ── Word-level tajweed extraction ─────────────────────────────────────────
  /// Parses tajweed bracket text and returns ONE dominant [TajweedRule] per word.
  /// Words are separated by Arabic space U+0020 or ZWNJ U+200C.
  static List<TajweedRule?> _extractWordRules(String tajweedRaw) {
    final segments = parseTajweedText(tajweedRaw);
    final wordRules = <TajweedRule?>[];

    // Priority map: lower number = higher prominence (used to pick dominant rule)
    const priority = {
      TajweedRule.ghunnah: 1,
      TajweedRule.ikhfa: 2,
      TajweedRule.ikhfaShafawi: 3,
      TajweedRule.iqlab: 4,
      TajweedRule.idghamWithGhunnah: 5,
      TajweedRule.idghamWithoutGhunnah: 6,
      TajweedRule.idghamShafawi: 7,
      TajweedRule.idghamMutajanisayn: 8,
      TajweedRule.idghamMutaqaribayn: 9,
      TajweedRule.qalqala: 10,
      TajweedRule.maddaNecessary: 11,
      TajweedRule.maddaObligatory: 12,
      TajweedRule.maddaPermissible: 13,
      TajweedRule.maddaNormal: 14,
      TajweedRule.hamzaWasl: 20,
      TajweedRule.laamShamsiyyah: 21,
      TajweedRule.silent: 22,
    };

    TajweedRule? currentBest;
    int currentBestPriority = 999;
    bool inWord = false;

    void saveWord() {
      if (inWord) {
        wordRules.add(currentBest);
        currentBest = null;
        currentBestPriority = 999;
        inWord = false;
      }
    }

    for (final seg in segments) {
      if (seg.isPlain) {
        for (final ch in seg.text.runes) {
          final c = String.fromCharCode(ch);
          if (c == ' ' || c == '\u200c' || c == '\u200b') {
            saveWord();
          } else if (c != '۞' && c != '\u06dd') {
            // Regular Arabic character
            inWord = true;
          }
        }
      } else {
        inWord = true;
        if (seg.rule != null) {
          final p = priority[seg.rule!] ?? 99;
          if (p < currentBestPriority) {
            currentBest = seg.rule;
            currentBestPriority = p;
          }
        }
      }
    }
    saveWord(); // Flush last word

    return wordRules;
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF0E1A12) : const Color(0xFFFFF9ED);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'سورة النور ٣٥ — مقارنة طرق العرض',
          style: GoogleFonts.amiriQuran(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة التحميل',
            onPressed: _fetchData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(
              text: '⭐ QCF + تجويد',
              icon: Icon(Icons.auto_awesome, size: 13,
                  color: Color(0xFFFFD700)),
            ),
            Tab(
              text: '② QCF نظيف',
              icon: Icon(Icons.menu_book, size: 13),
            ),
            Tab(
              text: '③ عثماني',
              icon: Icon(Icons.text_fields, size: 13),
            ),
            Tab(
              text: '④ تجويد ملوّن',
              icon: Icon(Icons.palette, size: 13),
            ),
            Tab(
              text: '⑤ صفحة كاملة',
              icon: Icon(Icons.import_contacts, size: 13),
            ),
          ],
        ),
      ),
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMethod0_QcfTajweed(isDark, bgColor),
                    _buildMethod1_QCF(isDark, bgColor),
                    _buildMethod2_Uthmani(isDark, bgColor),
                    _buildMethod3_Tajweed(isDark, bgColor),
                    _buildMethod5_FullPage(isDark, bgColor),
                  ],
                ),
    );
  }

  Widget _buildLoading() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل الآية الكريمة…',
              style: GoogleFonts.amiri(fontSize: 16, color: AppColors.primary),
            ),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'تعذّر الاتصال بالإنترنت',
                style: GoogleFonts.amiri(
                    fontSize: 18,
                    color: AppColors.error,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_error ?? '', textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('إعادة المحاولة',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // الطريقة ⭐ — QCF + Word-level Tajweed  [الأفضل — مثل quran.com]
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMethod0_QcfTajweed(bool isDark, Color bgColor) {
    final colorMap = isDark ? kTajweedColorsDark : kTajweedColorsLight;
    final defaultColor =
        isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);

    // 1) Build per-glyph color list.
    //    _qcfGlyphText has \n between mushaf lines; each non-\n char = 1 word glyph.
    //    Glyph 0 = ۞ rub-el-hizb marker → dimmed.
    //    Glyphs 1..N → _wordRules[0..N-1].
    final glyphColors = _buildQcfGlyphColors(colorMap, defaultColor);

    // 2) Split into mushaf lines at \n and build colored TextSpan per line.
    final glyphLines = _qcfGlyphText.split('\n');
    int glyphCursor = 0;

    final lineWidgets = <Widget>[];
    for (final line in glyphLines) {
      if (line.isEmpty) continue;
      final lineSpans = <InlineSpan>[];
      for (int ci = 0; ci < line.length; ci++) {
        final glyph = line[ci];
        final Color color = glyphCursor < glyphColors.length
            ? glyphColors[glyphCursor]
            : defaultColor;
        lineSpans.add(TextSpan(
          text: glyph,
          style: TextStyle(
            fontFamily: _kPageFont,
            package: 'qcf_quran',
            fontSize: 34,
            color: color,
            height: 2.1,
          ),
        ));
        glyphCursor++;
      }
      lineWidgets.add(
        Text.rich(
          TextSpan(children: lineSpans),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          locale: const Locale('ar'),
          textScaler: TextScaler.noScaling,
        ),
      );
    }

    // 3) Collect unique rules for the legend.
    final rulesUsed = _wordRules
        .where((r) => r != null)
        .cast<TajweedRule>()
        .toSet()
        .toList()
      ..sort((a, b) =>
          kLegendRules.indexOf(a).compareTo(kLegendRules.indexOf(b)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Badge ─────────────────────────────────────────────────────────
          _MethodBadge(
            number: '⭐',
            title: 'QCF + تجويد كلمة بكلمة (الأفضل)',
            subtitle:
                'رسم المصحف الحقيقي (QCF_P354) + ألوان التجويد كلمةً بكلمة\n'
                'نفس الطريقة التي يستخدمها تطبيق quran.com والموقع',
            icon: Icons.auto_awesome,
            color: const Color(0xFFD4AF37),
            isRecommended: true,
          ),
          const SizedBox(height: 16),

          // ── QCF + Tajweed Render ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A2820)
                  : const Color(0xFFFFFAF0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 20),
            child: Column(
              children: [
                Text(
                  'آيةُ النُّور',
                  style: GoogleFonts.amiriQuran(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'سورة النور (٢٤) — الآية (٣٥)',
                  style: GoogleFonts.amiri(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Divider(height: 22),
                // ── Per-mushaf-line QCF rendering with tajweed colors ─────
                ...lineWidgets,
                const SizedBox(height: 14),
                // Verse number ornament
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.secondary, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '٣٥',
                    style: GoogleFonts.amiriQuran(
                      fontSize: 14,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Legend ────────────────────────────────────────────────────────
          if (rulesUsed.isNotEmpty) ...[
            Text(
              'أحكام التجويد في هذه الآية',
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: rulesUsed.map((rule) {
                final color = colorMap[rule] ?? Colors.grey;
                final name = kTajweedRuleNamesAr[rule] ?? '';
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: color.withValues(alpha: 0.65), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: GoogleFonts.amiri(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : Colors.black87),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // ── Info ──────────────────────────────────────────────────────────
          _InfoCard(
            title: 'لماذا هذه الطريقة هي الأفضل؟',
            lines: const [
              '• رسم 100% مطابق للمصحف المطبوع — خط QCF الحجري الشريف',
              '• كل كلمة ملوّنة بحكمها التجويدي الصحيح',
              '• نفس الطريقة التي يعتمدها quran.com وتطبيقاته',
              '• رموز QCF من package:qcf_quran — تعمل 100% بدون إنترنت',
              '• أحكام التجويد من api.alquran.cloud المحترم',
            ],
            icon: Icons.check_circle_outline,
            color: const Color(0xFFD4AF37),
          ),
          const SizedBox(height: 12),

          _TechCard(
            title: 'كيف يعمل؟',
            content:
                '1. getVerseQCF(24,35) → رموز QCF المصحفية الصحيحة\n'
                '2. api.alquran.cloud → نص التجويد بالأقواس\n'
                '3. parseTajweedText() → القاعدة التجويدية لكل كلمة\n'
                '4. QCF_P354 font + TextSpan ملوّن لكل رمز/كلمة',
          ),
        ],
      ),
    );
  }

  /// Builds a flat list of colors, one per non-newline glyph in [_qcfGlyphText].
  ///
  /// The first non-newline character in the QCF verse string is always the
  /// ۞ rub-el-hizb marker, which is given a dimmed version of [defaultColor].
  /// Subsequent glyphs are paired with [_wordRules] (index 0 = first word).
  List<Color> _buildQcfGlyphColors(
    Map<TajweedRule, Color> colorMap,
    Color defaultColor,
  ) {
    final result = <Color>[];
    int glyphCount = 0;
    for (int i = 0; i < _qcfGlyphText.length; i++) {
      if (_qcfGlyphText[i] == '\n') continue; // line-delimiter, not a glyph
      if (glyphCount == 0) {
        // First glyph = ۞ marker: use dimmed text color
        result.add(defaultColor.withValues(alpha: 0.55));
      } else {
        final ruleIdx = glyphCount - 1;
        final rule =
            ruleIdx < _wordRules.length ? _wordRules[ruleIdx] : null;
        result.add(
          rule != null ? (colorMap[rule] ?? defaultColor) : defaultColor,
        );
      }
      glyphCount++;
    }
    return result;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // الطريقة ② — QCF Glyph Page Fonts  (نظيف بدون ألوان)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMethod1_QCF(bool isDark, Color bgColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MethodBadge(
            number: '②',
            title: 'QCF خطوط المصحف النظيفة (للقراءة)',
            subtitle:
                'رسم المصحف بخطوط QCF الحجرية الشريفة — بدون ألوان تجويد\n'
                'مثالي للقراءة الهادئة والمراجعة',
            icon: Icons.menu_book,
            color: const Color(0xFF0D5E3A),
          ),
          const SizedBox(height: 16),

          // ── QCF Page Display ─────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0E1A12) : const Color(0xFFFFF9ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              height: 550,
              child: AppQcfPage(
                pageNumber: _kPage,
                sp: 1.0,
                h: 1.0,
                theme: QcfThemeData(
                  verseTextColor: isDark
                      ? const Color(0xFFE8E8E8)
                      : const Color(0xFF1A1A1A),
                  pageBackgroundColor: Colors.transparent,
                  verseHeight: 2.2,
                  showHeader: true,
                  showBasmala: true,
                ),
                verseBackgroundColor: (surah, verse) {
                  if (surah == _kSurah && verse == _kAyah) {
                    return const Color(0xFFD4AF37).withValues(alpha: 0.25);
                  }
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          _InfoCard(
            title: 'لماذا هي الأفضل؟',
            lines: const [
              '• الرسم 100% مطابق للمصحف المطبوع (رواية حفص)',
              '• كل صفحة لها خط مستقل → دقة مثالية في توزيع الكلمات',
              '• تعمل Offline بدون إنترنت بعد تحميل الخطوط',
              '• تدعم تمييز الآيات والكلمات بالألوان',
              '• المرجع: مجمع الملك فهد / مجمع قرآن كمبلكس',
            ],
            icon: Icons.check_circle_outline,
            color: const Color(0xFF26A65B),
          ),

          const SizedBox(height: 12),
          _TechCard(
            title: 'التقنية',
            content:
                'package: qcf_quran\nFont: QCF_P354 (صفحة $_kPage)\n'
                'الخط: Glyph-based — كل رمز = صورة حرف من المصحف\n'
                'المصدر: fonts مضمّنة في الـ package',
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // الطريقة ② — Unicode Uthmani Font (QPC Hafs)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMethod2_Uthmani(bool isDark, Color bgColor) {
    final textColor =
        isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MethodBadge(
            number: '②',
            title: 'خط عثماني يونيكود (UthmanicHafs)',
            subtitle:
                'نص عثماني Unicode يُعرض بخط UthmanicHafs1Ver18\n'
                'يناسب عرض آية بآية لكن التخطيط لا يطابق المصحف المطبوع',
            icon: Icons.text_fields,
            color: const Color(0xFF1976D2),
          ),
          const SizedBox(height: 16),

          // ── Uthmani Text Display ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2820) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1976D2).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Surah header
                Text(
                  'سورة النور',
                  style: GoogleFonts.amiriQuran(
                    fontSize: 20,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الآية ٣٥',
                  style: GoogleFonts.amiri(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Divider(height: 24),
                // Ayah text
                Text(
                  _uthmaniText,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs1Ver18',
                    fontSize: 28,
                    height: 2.5,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                // Verse number ornament
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.secondary, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '٣٥',
                    style: GoogleFonts.amiriQuran(
                      fontSize: 14,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _InfoCard(
            title: 'المزايا والقيود',
            lines: const [
              '✓ خفيف الحجم — خط واحد لكل القرآن',
              '✓ يدعم تعدد الأحجام بمرونة',
              '✓ مناسب لعرض آية بآية',
              '✗ التخطيط لا يطابق صفحات المصحف',
              '✗ بعض الرموز قد تختلف عن الطبعة المدنية',
            ],
            icon: Icons.info_outline,
            color: const Color(0xFF1976D2),
          ),

          const SizedBox(height: 12),
          _TechCard(
            title: 'التقنية',
            content:
                'Font: UthmanicHafs1Ver18.ttf (assets/fonts/)\n'
                'النص: text_uthmani من Quran.com API v4\n'
                'المصدر: api.quran.com/api/v4/verses/by_key/24:35\n'
                'العرض: Text widget عادي مع RTL',
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // الطريقة ③ — Tajweed Colored (alquran.cloud)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMethod3_Tajweed(bool isDark, Color bgColor) {
    final segments = _tajweedRaw != null
        ? parseTajweedText(_tajweedRaw!)
        : <TajweedSegment>[];
    final colorMap =
        isDark ? kTajweedColorsDark : kTajweedColorsLight;
    final textColor =
        isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);

    // collect unique rules present in this ayah
    final rulesUsed = segments
        .where((s) => s.rule != null)
        .map((s) => s.rule!)
        .toSet()
        .toList()
      ..sort((a, b) =>
          (kLegendRules.indexOf(a)).compareTo(kLegendRules.indexOf(b)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MethodBadge(
            number: '③',
            title: 'النص بألوان التجويد',
            subtitle:
                'كل حكم تجويدي بلون مختلف — مناسب للتعليم والمراجعة\n'
                'البيانات من alquran.cloud (tajweed edition)',
            icon: Icons.palette,
            color: const Color(0xFF9400A8),
          ),
          const SizedBox(height: 16),

          // ── Colored Tajweed Display ───────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2820) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF9400A8).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'سورة النور — آية النور',
                  style: GoogleFonts.amiriQuran(
                    fontSize: 18,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 20),
                Text.rich(
                  TextSpan(
                    children: segments.map((seg) {
                      final color = seg.rule != null
                          ? colorMap[seg.rule!]
                          : textColor;
                      return TextSpan(
                        text: seg.text,
                        style: TextStyle(
                          fontFamily: 'UthmanicHafs1Ver18',
                          fontSize: 26,
                          height: 2.6,
                          color: color,
                        ),
                      );
                    }).toList(),
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  locale: const Locale('ar'),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.secondary, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '٣٥',
                    style: GoogleFonts.amiriQuran(
                      fontSize: 14,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Legend of rules found in this ayah ───────────────────────────
          if (rulesUsed.isNotEmpty) ...[
            Text(
              'أحكام التجويد في هذه الآية',
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: rulesUsed.map((rule) {
                final color = colorMap[rule] ?? Colors.grey;
                final name = kTajweedRuleNamesAr[rule] ?? '';
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: color.withValues(alpha: 0.6), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: GoogleFonts.amiri(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          _InfoCard(
            title: 'المزايا والقيود',
            lines: const [
              '✓ مرئي ومفيد للمتعلمين والمراجعين',
              '✓ يُبيّن الأحكام التجويدية بوضوح',
              '✓ مناسب للمساعدة في التلاوة الصحيحة',
              '✗ يتطلب إنترنت لجلب البيانات',
              '✗ الخط لا يطابق رسم المصحف المطبوع تماماً',
            ],
            icon: Icons.school_outlined,
            color: const Color(0xFF9400A8),
          ),

          const SizedBox(height: 12),
          _TechCard(
            title: 'التقنية',
            content:
                'API: api.alquran.cloud/v1/ayah/24:35/quran-tajweed\n'
                'Parser: parseTajweedText() → TajweedSegment[]\n'
                'Font: UthmanicHafs1Ver18.ttf + ألوان من kTajweedColorsLight\n'
                'عدد الأحكام المدعومة: 17 حكم تجويدي',
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // الطريقة ⑤ — Full QCF Page View (بديل عن صورة CDN المنقطعة)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMethod5_FullPage(bool isDark, Color bgColor) {
    final textColor =
        isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MethodBadge(
            number: '⑤',
            title: 'الصفحة كاملة — عرض محلي',
            subtitle:
                'عرض صفحة المصحف ٣٥٤ كاملاً بالخطوط المحلية QCF\n'
                'ملاحظة: CDNs الصور الخارجية (cdn.islamic.network وغيرها) أوقفت خدمتها',
            icon: Icons.import_contacts,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),

          // CDN notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.5), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'جميع CDNs الإنترنت لصور صفحات المصحف (cdn.islamic.network، '
                    'images.quran.com، cdn.alquran.cloud) أعادت 404. '
                    'البديل الموثوق: الخطوط المحلية QCF المضمّنة في التطبيق.',
                    style: GoogleFonts.amiri(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                        height: 1.6),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Full QCF page
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0E1A12)
                  : const Color(0xFFFFF9ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.menu_book,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'صفحة $_kPage — رواية حفص عن عاصم',
                        style: GoogleFonts.amiri(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SizedBox(
                  height: 560,
                  child: AppQcfPage(
                    pageNumber: _kPage,
                    sp: 1.0,
                    h: 1.0,
                    theme: QcfThemeData(
                      verseTextColor: textColor,
                      pageBackgroundColor: Colors.transparent,
                      verseHeight: 2.2,
                      showHeader: true,
                      showBasmala: true,
                    ),
                    // Highlight our verse
                    verseBackgroundColor: (surah, verse) {
                      if (surah == _kSurah && verse == _kAyah) {
                        return const Color(0xFFD4AF37)
                            .withValues(alpha: 0.22);
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _InfoCard(
            title: 'لماذا الخطوط المحلية أفضل من صور CDN؟',
            lines: const [
              '✓ تعمل بالكامل دون إنترنت',
              '✓ لا تتأثر بتوقف خدمات CDN الخارجية',
              '✓ حجم أصغر بكثير من صور PNG (الخطوط مضمّنة في الـ package)',
              '✓ دقة لا نهائية على أي حجم شاشة (vector glyphs)',
              '✓ تدعم التفاعل، التمييز، والتلوين',
              '✗ تحتاج دعم خاص لكل صفحة (QCF_P001..QCF_P604)',
            ],
            icon: Icons.check_circle_outline,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MethodBadge extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isRecommended;

  const _MethodBadge({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    if (isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'الأفضل',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.lines,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black87,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _TechCard extends StatelessWidget {
  final String title;
  final String content;

  const _TechCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code, size: 16, color: Colors.blueGrey),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.7,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
