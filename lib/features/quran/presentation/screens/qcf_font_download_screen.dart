import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/qcf_font_download_service.dart';

/// Full‑screen widget shown on first launch (or when fonts are incomplete) to
/// let the user download the remaining 538 QCF tajweed font files.
///
/// Call [QcfFontDownloadScreen.showIfNeeded] to push this screen only when the
/// download is actually required.
class QcfFontDownloadScreen extends StatefulWidget {
  /// Called when the user taps "لاحقاً" (skip) or when the download completes.
  final VoidCallback onDone;

  const QcfFontDownloadScreen({super.key, required this.onDone});

  // ── Static helper ──────────────────────────────────────────────────────────

  /// Pushes [QcfFontDownloadScreen] only when fonts are not fully downloaded.
  /// Otherwise calls [onDone] immediately.
  static Future<void> showIfNeeded(
    BuildContext context, {
    required VoidCallback onDone,
  }) async {
    final complete = await QcfFontDownloadService.isFullyDownloaded();
    if (complete) {
      onDone();
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => QcfFontDownloadScreen(onDone: onDone),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<QcfFontDownloadScreen> createState() => _QcfFontDownloadScreenState();
}

enum _DownloadState { idle, downloading, done, error }

class _QcfFontDownloadScreenState extends State<QcfFontDownloadScreen> {
  _DownloadState _state = _DownloadState.idle;
  double _progress = 0.0;
  int _pendingCount = 0;
  int _doneCount = 0;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    final count = await QcfFontDownloadService.pendingDownloadCount();
    if (mounted) setState(() => _pendingCount = count);
  }

  Future<void> _startDownload() async {
    if (_state == _DownloadState.downloading) return;
    _cancelToken = CancelToken();
    setState(() {
      _state = _DownloadState.downloading;
      _progress = 0.0;
      _doneCount = 0;
    });

    final success = await QcfFontDownloadService.downloadAll(
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
      onPageDone: (_) {
        if (mounted) setState(() => _doneCount++);
      },
      cancelToken: _cancelToken,
    );

    if (!mounted) return;
    if (success) {
      setState(() {
        _state = _DownloadState.done;
        _progress = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      widget.onDone();
    } else {
      setState(() => _state = _DownloadState.error);
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1B5E20);
    const lightGreen = Color(0xFF4CAF50);
    const bgColor = Color(0xFFF5FFF5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Quran icon ──────────────────────────────────────────────
                const Icon(Icons.menu_book_rounded,
                    size: 72, color: green),
                const SizedBox(height: 16),

                // ── Title ───────────────────────────────────────────────────
                Text(
                  'خطوط المصحف الشريف',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.arefRuqaa(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Description ─────────────────────────────────────────────
                Text(
                  'لعرض المصحف بخط القرآن الكريم (المصحف المدني)، '
                  'يحتاج التطبيق إلى تحميل ملفات الخطوط مرة واحدة فقط.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 8),

                // ── Size notice ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: lightGreen, width: 1),
                  ),
                  child: Text(
                    'الحجم التقريبي: ~58 ميجابايت\n'
                    'يُنصح بالتحميل على شبكة Wi‑Fi',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: green, height: 1.5),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Progress area ────────────────────────────────────────────
                if (_state == _DownloadState.downloading ||
                    _state == _DownloadState.done) ...[
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: const Color(0xFFD0E8D0),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(lightGreen),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _state == _DownloadState.done
                        ? 'تم التحميل بنجاح ✓'
                        : '$_doneCount / $_pendingCount صفحة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: _state == _DownloadState.done
                          ? lightGreen
                          : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_state == _DownloadState.error) ...[
                  const Icon(Icons.wifi_off_rounded,
                      size: 40, color: Colors.redAccent),
                  const SizedBox(height: 8),
                  const Text(
                    'فشل التحميل — تحقق من الاتصال بالإنترنت ثم حاول مجدداً',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                ],

                const Spacer(),

                // ── Download button ──────────────────────────────────────────
                if (_state != _DownloadState.done)
                  ElevatedButton.icon(
                    onPressed: _state == _DownloadState.downloading
                        ? null
                        : _startDownload,
                    icon: _state == _DownloadState.downloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(
                      _state == _DownloadState.error
                          ? 'إعادة المحاولة'
                          : 'تحميل القرآن الكريم كاملاً',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // ── Skip button ──────────────────────────────────────────────
                if (_state != _DownloadState.done &&
                    _state != _DownloadState.downloading)
                  TextButton(
                    onPressed: widget.onDone,
                    child: const Text(
                      'لاحقاً — استخدام العرض المبسّط',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
