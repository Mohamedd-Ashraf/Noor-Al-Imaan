import 'package:flutter/material.dart';

import '../../../../core/constants/quran_structure.dart';
import '../../../../core/constants/surah_names.dart';

class SelectDownloadScreen extends StatefulWidget {
  const SelectDownloadScreen({super.key});

  @override
  State<SelectDownloadScreen> createState() => _SelectDownloadScreenState();
}

class _SelectDownloadScreenState extends State<SelectDownloadScreen> {
  int _selectedTab = 0; // 0: Juz, 1: Popular, 2: Custom
  final Set<int> _selectedJuz = {};
  final Set<int> _selectedSurahs = {};
  String? _selectedPopularSection;

  @override
  Widget build(BuildContext context) {
    final isArabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabicUi ? 'اختر ما ترغب بتحميله' : 'Select Download'),
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            padding: const EdgeInsets.all(8),
            color: scheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(
                    index: 0,
                    label: isArabicUi ? 'الأجزاء' : 'Juz',
                    icon: Icons.menu_book,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTab(
                    index: 1,
                    label: isArabicUi ? 'مشهورة' : 'Popular',
                    icon: Icons.star,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTab(
                    index: 2,
                    label: isArabicUi ? 'مخصص' : 'Custom',
                    icon: Icons.tune,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _selectedTab == 0
                ? _buildJuzSelector(isArabicUi)
                : _selectedTab == 1
                    ? _buildPopularSelector(isArabicUi)
                    : _buildCustomSelector(isArabicUi),
          ),

          // Bottom action bar
          _buildBottomBar(context, isArabicUi),
        ],
      ),
    );
  }

  Widget _buildTab({required int index, required String label, required IconData icon}) {
    final isSelected = _selectedTab == index;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJuzSelector(bool isArabicUi) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        final isSelected = _selectedJuz.contains(juzNumber);

        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedJuz.remove(juzNumber);
              } else {
                _selectedJuz.add(juzNumber);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? scheme.primary : scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? scheme.primary : scheme.outline.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  juzNumber.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? scheme.onPrimary : scheme.onSurface,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabicUi ? 'جزء' : 'Juz',
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopularSelector(bool isArabicUi) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: QuranStructure.popularSections.length,
      itemBuilder: (context, index) {
        final section = QuranStructure.popularSections[index];
        final name = isArabicUi ? section['nameAr'] : section['nameEn'];
        final surahs = List<int>.from(section['surahs']);
        final isSelected = _selectedPopularSection == name;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedPopularSection = null;
                } else {
                  _selectedPopularSection = name;
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${surahs.length} ${isArabicUi ? 'سورة' : 'Surahs'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomSelector(bool isArabicUi) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 114,
      itemBuilder: (context, index) {
        final surahNumber = index + 1;
        final isSelected = _selectedSurahs.contains(surahNumber);
        final surahInfo = SurahNames.surahs[index];
        final surahName = isArabicUi ? surahInfo['arabic']! : surahInfo['english']!;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected
              ? scheme.primary.withValues(alpha: isDark ? 0.22 : 0.10)
              : scheme.surface,
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: 0.4),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CheckboxListTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    surahNumber.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    surahName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            value: isSelected,
            activeColor: scheme.primary,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedSurahs.add(surahNumber);
                } else {
                  _selectedSurahs.remove(surahNumber);
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isArabicUi) {
    final selectedCount = _getSelectedSurahs().length;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.16 : 0.10),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabicUi ? 'تم الاختيار:' : 'Selected:',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$selectedCount ${isArabicUi ? 'سورة' : 'Surahs'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: selectedCount > 0
                ? () {
                    Navigator.pop(context, _getSelectedSurahs());
                  }
                : null,
            icon: const Icon(Icons.download),
            label: Text(isArabicUi ? 'تحميل' : 'Download'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  List<int> _getSelectedSurahs() {
    if (_selectedTab == 0) {
      // Juz tab
      return QuranStructure.getSurahsForMultipleJuz(_selectedJuz.toList()).toList()..sort();
    } else if (_selectedTab == 1) {
      // Popular tab
      if (_selectedPopularSection != null) {
        return QuranStructure.getSurahsForSection(_selectedPopularSection!);
      }
      return [];
    } else {
      // Custom tab
      return _selectedSurahs.toList()..sort();
    }
  }
}
