import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/widgets/islamic_logo.dart';
import 'duaa_screen.dart';
import 'prayer_times_screen.dart';
import 'qiblah_screen.dart';

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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                IslamicLogo(size: 100, darkTheme: isDark),
                const SizedBox(height: 12),
                Text(
                  isArabicUi ? 'تطبيق القرآن الكريم' : 'Quran Application',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: 16),
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
            title: isArabicUi ? 'القبلة' : 'Qiblah',
            subtitle: isArabicUi
                ? 'اتجاه القبلة من موقعك'
                : 'Qiblah bearing from your location',
            icon: Icons.explore,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QiblahScreen()),
              );
            },
          ),
          _NavCard(
            title: isArabicUi ? 'الأدعية' : 'Duaa',
            subtitle: isArabicUi
                ? 'صفحة أدعية (ستضيفها لاحقاً)'
                : 'Duaa page (you will add content later)',
            icon: Icons.menu_book,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DuaaScreen()),
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

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
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
