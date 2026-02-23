import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../data/models/adhkar_category.dart';
import '../../data/models/adhkar_item.dart';
import '../cubit/adhkar_progress_cubit.dart';

class AdhkarListScreen extends StatelessWidget {
  final AdhkarCategory category;

  const AdhkarListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsCubit>().state;
    final isArabicUi =
        settings.appLanguageCode.toLowerCase().startsWith('ar');
    final showTranslation = settings.showTranslation;
    final progressState = context.watch<AdhkarProgressCubit>().state;
    final cubit = context.read<AdhkarProgressCubit>();
    final color = category.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabicUi ? category.titleAr : category.titleEn),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gradientStart,
                AppColors.gradientMid,
                AppColors.gradientEnd,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: isArabicUi ? 'إعادة تعيين الكل' : 'Reset all',
            onPressed: () => cubit.resetCategory(category.id),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: category.items.length,
        itemBuilder: (context, index) {
          final item = category.items[index];
          final count = progressState.countFor(category.id, item.id);
          final isDone = count >= item.repeatCount;

          return _AdhkarCard(
            item: item,
            count: count,
            isDone: isDone,
            isArabicUi: isArabicUi,
            showTranslation: showTranslation,
            categoryColor: color,
            index: index,
            onTap: () {
              HapticFeedback.lightImpact();
              cubit.increment(category.id, item.id, item.repeatCount);
            },
            onReset: () {
              HapticFeedback.mediumImpact();
              cubit.resetItem(category.id, item.id);
            },
          );
        },
      ),
    );
  }
}

// ─── Adhkar Card ──────────────────────────────────────────────────────────────
class _AdhkarCard extends StatelessWidget {
  final AdhkarItem item;
  final int count;
  final bool isDone;
  final bool isArabicUi;
  final bool showTranslation;
  final Color categoryColor;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onReset;

  const _AdhkarCard({
    required this.item,
    required this.count,
    required this.isDone,
    required this.isArabicUi,
    required this.showTranslation,
    required this.categoryColor,
    required this.index,
    required this.onTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDone
        ? (isDark
            ? const Color(0xFF1B3A2D)
            : const Color(0xFFE8F5EC))
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        color: cardColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDone
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.cardBorder,
            width: isDone ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Top bar with index + done badge ─────────────────────
            Container(
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: isDark ? 0.25 : 0.1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: isDark ? 0.4 : 0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: categoryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isDone)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 14,
                              color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            isArabicUi ? 'تمّ' : 'Done',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ─── Arabic text ──────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Text(
                item.arabicText,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                  fontSize: 22,
                  height: 1.9,
                  fontWeight: FontWeight.w600,
                  color: isDone
                      ? AppColors.primary
                      : (isDark
                          ? const Color(0xFFE8DCC8)
                          : AppColors.arabicText),
                ),
              ),
            ),

            // ─── Translation (shown only when setting is enabled) ────
            if (showTranslation)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Text(
                  item.translationEn,
                  textAlign: isArabicUi ? TextAlign.right : TextAlign.left,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),

            // ─── Virtue (if any) ──────────────────────────────────────
            if (item.virtue != null) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.star_rounded,
                        size: 15, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.virtue!,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFFD4AF37)
                              : AppColors.accent,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 1),

            // ─── Bottom row: reference + counter ─────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  // Reference
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_rounded,
                            size: 13,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.reference,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.8),
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Counter section
                  _CounterWidget(
                    count: count,
                    maxCount: item.repeatCount,
                    isDone: isDone,
                    categoryColor: categoryColor,
                    isArabicUi: isArabicUi,
                    onTap: onTap,
                    onReset: onReset,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Counter Widget ────────────────────────────────────────────────────────────
class _CounterWidget extends StatelessWidget {
  final int count;
  final int maxCount;
  final bool isDone;
  final Color categoryColor;
  final bool isArabicUi;
  final VoidCallback onTap;
  final VoidCallback onReset;

  const _CounterWidget({
    required this.count,
    required this.maxCount,
    required this.isDone,
    required this.categoryColor,
    required this.isArabicUi,
    required this.onTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    if (maxCount == 1) {
      // For single-repeat items, show a simple done button
      return Tooltip(
        message: isDone
            ? (isArabicUi
                ? 'اضغط لإلغاء التعليم وإعادة الذِكر'
                : 'Tap to unmark and repeat')
            : (isArabicUi
                ? 'اضغط لتعليم الذِكر كمقروء'
                : 'Tap to mark as recited'),
        preferBelow: false,
        child: GestureDetector(
          onTap: isDone ? onReset : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.success.withValues(alpha: 0.15)
                  : categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDone
                    ? AppColors.success.withValues(alpha: 0.5)
                    : categoryColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDone
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 15,
                  color: isDone ? AppColors.success : categoryColor,
                ),
                const SizedBox(width: 5),
                Text(
                  isDone
                      ? (isArabicUi ? 'تمّ' : 'Done')
                      : (isArabicUi ? 'قرأت' : 'Mark'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDone ? AppColors.success : categoryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Multi-repeat counter
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDone)
          Tooltip(
            message: isArabicUi
                ? 'اضغط لإعادة العد من الصفر'
                : 'Tap to reset counter to zero',
            preferBelow: false,
            child: GestureDetector(
              onTap: onReset,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Icon(Icons.refresh_rounded,
                    size: 14, color: AppColors.error),
              ),
            ),
          ),
        Tooltip(
          message: isDone
              ? (isArabicUi
                  ? 'اكتملت العدد — اضغط ↺ لإعادة البدء'
                  : 'Count complete — tap ↺ to restart')
              : (isArabicUi
                  ? 'اضغط لإحصاء مرة — يكتمل تلقائياً عند بلوغ العدد'
                  : 'Tap to count once — completes when target is reached'),
          preferBelow: false,
          child: GestureDetector(
            onTap: isDone ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: isDone
                    ? null
                    : LinearGradient(
                        colors: [
                          categoryColor,
                          categoryColor.withValues(alpha: 0.8),
                        ],
                      ),
                color: isDone
                    ? AppColors.success.withValues(alpha: 0.15)
                    : null,
                borderRadius: BorderRadius.circular(20),
                border: isDone
                    ? Border.all(
                        color: AppColors.success.withValues(alpha: 0.5))
                    : null,
                boxShadow: isDone
                    ? null
                    : [
                        BoxShadow(
                          color: categoryColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isDone)
                    const Icon(Icons.add_rounded,
                        size: 14, color: Colors.white),
                  if (!isDone) const SizedBox(width: 4),
                  Text(
                    isDone
                        ? '✓ $maxCount'
                        : '$count / $maxCount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDone ? AppColors.success : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
