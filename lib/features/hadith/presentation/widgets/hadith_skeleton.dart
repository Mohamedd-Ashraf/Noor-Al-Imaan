import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_design_system.dart';

/// Skeleton loading shimmer for hadith list items.
class HadithListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool isDark;

  const HadithListSkeleton({
    super.key,
    this.itemCount = 6,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _SkeletonCard(isDark: isDark),
        childCount: itemCount,
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = 0.3 + (_animation.value * 0.4);
        return Opacity(opacity: opacity, child: child);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar skeleton
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  _shimmerCircle(32),
                  const SizedBox(width: 10),
                  Expanded(child: _shimmerLine(height: 14, widthFactor: 0.5)),
                  _shimmerBox(width: 56, height: 20, radius: 8),
                ],
              ),
            ),
            // Text skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _shimmerLine(height: 14, widthFactor: 1.0),
                  const SizedBox(height: 8),
                  _shimmerLine(height: 14, widthFactor: 0.9),
                  const SizedBox(height: 8),
                  _shimmerLine(height: 14, widthFactor: 0.7),
                ],
              ),
            ),
            // Bottom bar skeleton
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  _shimmerCircle(14),
                  const SizedBox(width: 4),
                  Expanded(child: _shimmerLine(height: 10, widthFactor: 0.4)),
                  _shimmerCircle(14),
                  const SizedBox(width: 4),
                  _shimmerBox(width: 48, height: 10, radius: 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerLine({required double height, double widthFactor = 1.0}) {
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerEnd,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }

  Widget _shimmerCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton for the detail screen body.
class HadithDetailSkeleton extends StatefulWidget {
  final bool isDark;
  const HadithDetailSkeleton({super.key, this.isDark = false});

  @override
  State<HadithDetailSkeleton> createState() => _HadithDetailSkeletonState();
}

class _HadithDetailSkeletonState extends State<HadithDetailSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = 0.3 + (_animation.value * 0.4);
        return Opacity(opacity: opacity, child: child);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header skeleton
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDesignSystem.radiusLg),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Text lines
            for (var i = 0; i < 8; i++) ...[
              Container(
                height: 16,
                width: double.infinity,
                margin: EdgeInsets.only(
                  right: i % 3 == 0 ? 40 : 0,
                  left: i % 2 == 0 ? 20 : 0,
                ),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),
            // Explanation skeleton
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error widget with retry button.
class HadithErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isArabic;

  const HadithErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.isArabic = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'حدث خطأ' : 'An error occurred',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading-more indicator shown at the bottom of a scrollable list.
class HadithLoadingMore extends StatelessWidget {
  const HadithLoadingMore({super.key});

  @override
  Widget build(BuildContext context) {
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
}
