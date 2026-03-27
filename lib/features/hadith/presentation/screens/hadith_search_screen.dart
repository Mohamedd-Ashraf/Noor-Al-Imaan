import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../data/models/hadith_category_info.dart';
import '../../data/models/hadith_item.dart';
import '../../data/models/hadith_list_item.dart';
import '../../data/repositories/hadith_repository.dart';
import 'hadith_detail_screen.dart';

class HadithSearchScreen extends StatefulWidget {
  const HadithSearchScreen({super.key});

  @override
  State<HadithSearchScreen> createState() => _HadithSearchScreenState();
}

class _HadithSearchScreenState extends State<HadithSearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scrollController = ScrollController();
  List<HadithListItem> _results = [];
  bool _searched = false;
  bool _isLoading = false;
  bool _hasMore = true;
  int _totalCount = 0;
  Timer? _debounce;

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTotalCount();
  }

  Future<void> _loadTotalCount() async {
    final repo = context.read<HadithRepository>();
    final count = await repo.getTotalCount();
    if (mounted) setState(() => _totalCount = count);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= (maxScroll - 200) && _hasMore && !_isLoading) {
      _loadMoreResults();
    }
  }

  void _search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(query);
    });
  }

  Future<void> _executeSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _hasMore = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searched = true;
    });

    final repo = context.read<HadithRepository>();
    final results = await repo.searchHadiths(
      query: q,
      limit: _pageSize,
      offset: 0,
    );

    if (mounted) {
      setState(() {
        _results = results;
        _hasMore = results.length >= _pageSize;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreResults() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    final repo = context.read<HadithRepository>();
    final results = await repo.searchHadiths(
      query: _controller.text.trim(),
      limit: _pageSize,
      offset: _results.length,
    );

    if (mounted) {
      setState(() {
        _results = [..._results, ...results];
        _hasMore = results.length >= _pageSize;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context
        .watch<AppSettingsCubit>()
        .state
        .appLanguageCode
        .toLowerCase()
        .startsWith('ar');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0E1B14)
            : const Color(0xFFF3F7F4),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(left: 4, right: 12),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: isArabic
                    ? 'ابحث في الأحاديث الشريفة...'
                    : 'Search hadiths...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: _search,
              onSubmitted: _search,
            ),
          ),
          actions: [
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_rounded),
                tooltip: isArabic ? 'مسح' : 'Clear',
                onPressed: () {
                  _controller.clear();
                  _search('');
                  _focus.requestFocus();
                },
              ),
          ],
        ),
        body: _buildBody(isArabic, isDark),
      ),
    );
  }

  Widget _buildBody(bool isArabic, bool isDark) {
    if (!_searched) {
      return _EmptyState(
        icon: Icons.search_rounded,
        message: isArabic
            ? 'ابحث في أكثر من $_totalCount حديث شريف'
            : 'Search across more than $_totalCount hadiths',
        isDark: isDark,
      );
    }
    if (_results.isEmpty && !_isLoading) {
      return _EmptyState(
        icon: Icons.sentiment_dissatisfied_rounded,
        message: isArabic ? 'لا نتائج — جرّب كلمة أخرى' : 'No results found',
        isDark: isDark,
      );
    }

    return Column(
      children: [
        _ResultsHeader(
          count: _results.length,
          isArabic: isArabic,
          isDark: isDark,
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: _results.length + (_isLoading && _hasMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i >= _results.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return _SearchResultCard(
                item: _results[i],
                isArabic: isArabic,
                isDark: isDark,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Results header
// ─────────────────────────────────────────────────────────
class _ResultsHeader extends StatelessWidget {
  final int count;
  final bool isArabic;
  final bool isDark;

  const _ResultsHeader({
    required this.count,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF152019) : const Color(0xFFE8F5EC),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            isArabic ? 'وُجد $count حديث' : '$count results found',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Search result card — now uses HadithListItem directly
// ─────────────────────────────────────────────────────────
class _SearchResultCard extends StatelessWidget {
  final HadithListItem item;
  final bool isArabic;
  final bool isDark;

  const _SearchResultCard({
    required this.item,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final catInfo = HadithCategoryInfo.findById(item.categoryId);
    final categoryColor = catInfo?.color ?? AppColors.primary;
    final categoryLabel = isArabic
        ? (catInfo?.titleAr ?? item.categoryId)
        : (catInfo?.titleEn ?? item.categoryId);
    final gradeColor = _gradeColor(item.grade);
    final gradeLabel = _gradeLabel(item.grade, isArabic);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? const Color(0xFF1A2D22) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HadithDetailScreen(
              hadithId: item.id,
              categoryId: item.categoryId,
              categoryTitle: categoryLabel,
              sortOrder: item.sortOrder,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category chip + grade badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      categoryLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: gradeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      gradeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: gradeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Arabic text preview
              Text(
                item.arabicPreview.length >= 150
                    ? '${item.arabicPreview}...'
                    : item.arabicPreview,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 15,
                  height: 1.7,
                  color: isDark ? Colors.white : const Color(0xFF1A2D22),
                ),
              ),
              const SizedBox(height: 8),
              // Topic + narrator
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.narrator,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.book_outlined,
                    size: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.reference.split('،').first,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _gradeColor(HadithGrade g) {
    switch (g) {
      case HadithGrade.muttafaqAlayh:
        return const Color(0xFF1B5E20);
      case HadithGrade.sahih:
        return const Color(0xFF2E7D32);
      case HadithGrade.hasan:
        return const Color(0xFFE65100);
    }
  }

  String _gradeLabel(HadithGrade g, bool ar) {
    switch (g) {
      case HadithGrade.muttafaqAlayh:
        return ar ? 'متفق عليه' : 'Agreed Upon';
      case HadithGrade.sahih:
        return ar ? 'صحيح' : 'Sahih';
      case HadithGrade.hasan:
        return ar ? 'حسن' : 'Hasan';
    }
  }
}

// ─────────────────────────────────────────────────────────
//  Empty / initial state
// ─────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isDark;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark
                ? Colors.white24
                : AppColors.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
