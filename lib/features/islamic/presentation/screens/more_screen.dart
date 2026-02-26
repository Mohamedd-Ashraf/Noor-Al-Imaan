import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/widgets/islamic_logo.dart';
import 'adhan_settings_screen.dart';
import 'duaa_screen.dart';
import 'prayer_times_screen.dart';
import 'qiblah_screen.dart';
import '../../../quran/presentation/screens/feedback_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabicUi = context
        .watch<AppSettingsCubit>()
        .state
        .appLanguageCode
        .toLowerCase()
        .startsWith('ar');

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabicUi ? 'المزيد' : 'More'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── App logo card ──────────────────────────────────────────────
          Card(
            margin: const EdgeInsets.only(bottom: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.hardEdge,
            elevation: 2,
            child: Column(
              children: [
                // Gradient header strip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gradientStart,
                        AppColors.gradientEnd
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Text(
                    isArabicUi ? 'تطبيق القرآن الكريم' : 'Quran Application',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
                // Logo body
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 22, horizontal: 24),
                  child: Column(
                    children: [
                      IslamicLogo(size: 90, darkTheme: isDark),
                      const SizedBox(height: 12),
                      Text(
                        isArabicUi ? 'الخدمات الإسلامية' : 'Islamic Services',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Section header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.gradientStart,
                        AppColors.gradientEnd
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.grid_view_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 7),
                      Text(
                        isArabicUi
                            ? 'الخدمات الإسلامية'
                            : 'Islamic Services',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Divider(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          _NavCard(
            title: isArabicUi ? 'مواقيت الصلاة' : 'Prayer Times',
            subtitle: isArabicUi
                ? 'حسب موقعك الحالي'
                : 'Based on your current location',
            icon: Icons.schedule,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrayerTimesScreen()),
              );
            },
          ),
          _NavCard(
            title: isArabicUi ? 'إعدادات الأذان' : 'Adhan Settings',
            subtitle: isArabicUi
                ? 'صوت الأذان وإشعارات أوقات الصلاة'
                : 'Adhan sound & prayer time notifications',
            icon: Icons.volume_up_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdhanSettingsScreen()),
              );
            },
          ),
          _NavCard(
            title: isArabicUi ? 'الأدعية' : 'Duaa',
            subtitle: isArabicUi
                ? 'أدعية وأذكار إسلامية'
                : 'Islamic supplications & remembrances',
            icon: Icons.menu_book,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DuaaScreen()),
              );
            },
          ),
          _NavCard(
            title: isArabicUi ? 'اقتراحات ومشاركات' : 'Feedback & Suggestions',
            subtitle: isArabicUi
                ? 'رأيك يُحسِّن التطبيق — نسخة بيتا'
                : 'Your input improves the app — Beta',
            icon: Icons.feedback_outlined,
            badge: 'BETA',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FeedbackScreen()),
              );
            },
          ),
          _NavCard(
            title: isArabicUi ? 'القبلة' : 'Qiblah',
            subtitle: isArabicUi
                ? 'قيد التطوير — قريبا'
                : 'Coming soon — in development',
            icon: Icons.explore,
            badge: isArabicUi ? 'قريباً' : 'SOON',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QiblahScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.gradientStart,
                      AppColors.gradientEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
