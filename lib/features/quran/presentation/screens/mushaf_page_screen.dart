import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/utils/arabic_text_style_helper.dart';

// ─── Data model ───────────────────────────────────────────────────────────────
class _Verse {
  final String verseKey;
  final int    surah;
  final int    ayah;
  final String text;

  const _Verse({
    required this.verseKey,
    required this.surah,
    required this.ayah,
    required this.text,
  });
}

// ─── Network ──────────────────────────────────────────────────────────────────
Future<List<_Verse>> _fetchPage(int page) async {
  final uri = Uri.parse(
    'https://api.quran.com/api/v4/verses/by_page/$page'
    '?fields=text_uthmani&per_page=50',
  );
  final res = await http.get(uri, headers: const {'Accept': 'application/json'});
  if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

  final data  = jsonDecode(res.body) as Map<String, dynamic>;
  final vList = data['verses'] as List;

  return vList.map((v) {
    final key  = v['verse_key'] as String;
    final sp   = key.split(':');
    return _Verse(
      verseKey: key,
      surah:    int.parse(sp[0]),
      ayah:     int.parse(sp[1]),
      text:     (v['text_uthmani'] as String?) ?? '',
    );
  }).toList();
}

// ─── Main screen ──────────────────────────────────────────────────────────────
class MushafPageScreen extends StatefulWidget {
  final int initialPage;
  const MushafPageScreen({super.key, this.initialPage = 1});

  @override
  State<MushafPageScreen> createState() => _MushafPageScreenState();
}

class _MushafPageScreenState extends State<MushafPageScreen> {
  late final PageController _pageCtrl;
  int _currentPage = 1;

  final Map<int, List<_Verse>> _cache   = {};
  final Map<int, bool>         _loading = {};
  final Map<int, Object?>      _errors  = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageCtrl    = PageController(initialPage: widget.initialPage - 1);
    _load(_currentPage);
    if (_currentPage < 604) _load(_currentPage + 1);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(int page) async {
    if (_cache.containsKey(page) || _loading[page] == true) return;
    if (mounted) setState(() => _loading[page] = true);
    try {
      final verses = await _fetchPage(page);
      if (mounted) setState(() => _cache[page] = verses);
    } catch (e) {
      if (mounted) setState(() => _errors[page] = e);
    } finally {
      if (mounted) setState(() => _loading.remove(page));
    }
  }

  void _onPageChanged(int idx) {
    setState(() => _currentPage = idx + 1);
    _load(_currentPage);
    if (_currentPage < 604) _load(_currentPage + 1);
  }

  void _showGoToPage() async {
    final ctrl = TextEditingController();
    final page = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الانتقال إلى صفحة',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller:   ctrl,
          keyboardType: TextInputType.number,
          decoration:   const InputDecoration(
            hintText: '1 – 604', border: OutlineInputBorder()),
          autofocus: true,
          onSubmitted: (v) {
            final n = int.tryParse(v);
            if (n != null && n >= 1 && n <= 604) Navigator.pop(ctx, n);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text);
              if (n != null && n >= 1 && n <= 604) Navigator.pop(ctx, n);
            },
            child: const Text('انتقال'),
          ),
        ],
      ),
    );
    if (page != null && mounted) _pageCtrl.jumpToPage(page - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E4),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: Text('الصفحة $_currentPage  من  ٦٠٤',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon:     const Icon(Icons.search_rounded),
            tooltip:  'انتقل إلى صفحة',
            onPressed: _showGoToPage,
          ),
        ],
      ),
      body: PageView.builder(
        controller:    _pageCtrl,
        itemCount:     604,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, idx) {
          final page = idx + 1;
          return _MushafPage(
            page:      page,
            verses:    _cache[page],
            isLoading: _loading[page] == true,
            error:     _errors[page],
            onRetry:   () => _load(page),
          );
        },
      ),
    );
  }
}

// ─── Single page layout ───────────────────────────────────────────────────────
class _MushafPage extends StatelessWidget {
  final int           page;
  final List<_Verse>? verses;
  final bool          isLoading;
  final Object?       error;
  final VoidCallback  onRetry;

  const _MushafPage({
    required this.page,
    required this.verses,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || (verses == null && error == null)) {
      return Container(
        color: const Color(0xFFF5F0E4),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 3),
              const SizedBox(height: 14),
              Text('جارٍ تحميل الصفحة $page…',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (error != null || verses == null || verses!.isEmpty) {
      return Container(
        color: const Color(0xFFF5F0E4),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('تعذّر تحميل الصفحة',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextButton.icon(
                icon:  const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F0E4),
      child: Column(
        children: [
          _PageBorder(isTop: true),
          _PageHeader(verses: verses!, page: page),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _PageText(verses: verses!),
            ),
          ),
          _PageFooter(page: page),
          _PageBorder(isTop: false),
        ],
      ),
    );
  }
}

// ─── Continuous page text ─────────────────────────────────────────────────────
class _PageText extends StatelessWidget {
  final List<_Verse> verses;
  const _PageText({required this.verses});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, settings) {
        final isDark      = settings.darkMode;
        final fontSize    = settings.arabicFontSize;
        final quranFont   = settings.quranFont;
        final textColor   = isDark
            ? const Color(0xFFE8E8E8)   // فاتح في الدارك موود
            : const Color(0xFF1A1A1A);  // أسود في اللايت موود

        final textStyle = ArabicTextStyleHelper.quranFontStyle(
          fontKey:    quranFont,
          fontSize:   fontSize,
          fontWeight: FontWeight.w500,
          color:      textColor,
          height:     2.2,
        );

        final spans = <InlineSpan>[];
        for (final v in verses) {
          spans.add(TextSpan(text: '${v.text} ', style: textStyle));
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _AyahMarker(number: v.ayah, isDark: isDark),
            ),
          ));
          spans.add(TextSpan(text: ' ', style: textStyle));
        }

        return Text.rich(
          TextSpan(children: spans),
          textDirection: TextDirection.rtl,
          textAlign:     TextAlign.justify,
        );
      },
    );
  }
}

// ─── Ayah number marker (same visual as mushaf_page_view) ────────────────────
class _AyahMarker extends StatelessWidget {
  final int  number;
  final bool isDark;
  const _AyahMarker({required this.number, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const frameSize    = 28.0;
    final baseFontSize = number > 99 ? 8.0 : (number > 9 ? 10.0 : 12.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/logo/files/transparent/frame.png',
          width:  frameSize,
          height: frameSize,
          color:  isDark ? Colors.white.withValues(alpha: 0.85) : null,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _toArabicNum(number),
            textAlign: TextAlign.center,
            style: GoogleFonts.amiriQuran(
              fontSize:   baseFontSize,
              fontWeight: FontWeight.w800,
              color:      isDark ? Colors.white : AppColors.primary,
              height:     1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Page header ──────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final List<_Verse> verses;
  final int          page;
  const _PageHeader({required this.verses, required this.page});

  String _surahName() {
    if (verses.isEmpty) return '';
    final n = verses.first.surah;
    return n < _kSurahNames.length ? _kSurahNames[n] : '';
  }

  int _juz() => ((page - 1) ~/ 20) + 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.fromLTRB(12, 4, 12, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border:       Border.all(color: const Color(0xFFBB9860), width: 0.8),
        borderRadius: BorderRadius.circular(4),
        color:        const Color(0xFFF5F0E4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('الجزء ${_toArabicNum(_juz())}',
            style: GoogleFonts.amiriQuran(
              fontSize: 13, color: const Color(0xFF6B4B0F),
              fontWeight: FontWeight.bold)),
          Text('سُورَةُ ${_surahName()}',
            style: GoogleFonts.amiriQuran(
              fontSize: 13, color: const Color(0xFF6B4B0F),
              fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Page footer ──────────────────────────────────────────────────────────────
class _PageFooter extends StatelessWidget {
  final int page;
  const _PageFooter({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(_toArabicNum(page),
        style: GoogleFonts.amiriQuran(
          fontSize:   16,
          color:      const Color(0xFF6B4B0F),
          fontWeight: FontWeight.bold)),
    );
  }
}

// ─── Decorative border ────────────────────────────────────────────────────────
class _PageBorder extends StatelessWidget {
  final bool isTop;
  const _PageBorder({required this.isTop});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          top:    BorderSide(color: const Color(0xFFBB9860), width: isTop ? 2.5 : 1),
          bottom: BorderSide(color: const Color(0xFFBB9860), width: isTop ? 1 : 2.5),
          left:   const BorderSide(color: Color(0xFFBB9860), width: 1),
          right:  const BorderSide(color: Color(0xFFBB9860), width: 1),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
String _toArabicNum(int n) {
  const d = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
  return n.toString().split('').map((c) => d[int.parse(c)]).join();
}

const _kSurahNames = [
  '',
  'الفاتحة','البقرة','آل عمران','النساء','المائدة',
  'الأنعام','الأعراف','الأنفال','التوبة','يونس',
  'هود','يوسف','الرعد','إبراهيم','الحجر',
  'النحل','الإسراء','الكهف','مريم','طه',
  'الأنبياء','الحج','المؤمنون','النور','الفرقان',
  'الشعراء','النمل','القصص','العنكبوت','الروم',
  'لقمان','السجدة','الأحزاب','سبأ','فاطر',
  'يس','الصافات','ص','الزمر','غافر',
  'فصلت','الشورى','الزخرف','الدخان','الجاثية',
  'الأحقاف','محمد','الفتح','الحجرات','ق',
  'الذاريات','الطور','النجم','القمر','الرحمن',
  'الواقعة','الحديد','المجادلة','الحشر','الممتحنة',
  'الصف','الجمعة','المنافقون','التغابن','الطلاق',
  'التحريم','الملك','القلم','الحاقة','المعارج',
  'نوح','الجن','المزمل','المدثر','القيامة',
  'الإنسان','المرسلات','النبأ','النازعات','عبس',
  'التكوير','الانفطار','المطففين','الانشقاق','البروج',
  'الطارق','الأعلى','الغاشية','الفجر','البلد',
  'الشمس','الليل','الضحى','الشرح','التين',
  'العلق','القدر','البينة','الزلزلة','العاديات',
  'القارعة','التكاثر','العصر','الهمزة','الفيل',
  'قريش','الماعون','الكوثر','الكافرون','النصر',
  'المسد','الإخلاص','الفلق','الناس',
];
