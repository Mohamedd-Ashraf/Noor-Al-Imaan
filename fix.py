import re

with open('lib/features/quran/presentation/screens/select_download_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

old = r'''                    Expanded\(
                      child: Text\(
                        surahName,
                        style: TextStyle\(
                          fontSize: 16,
                          fontWeight: \(isSelected \|\| isFullyDone\)
                              \? FontWeight\.bold
                              : FontWeight\.w500,
                          color: isFullyDone
                              \? Colors\.green\.shade700
                              : isSelected
                                  \? scheme\.primary
                                  : scheme\.onSurface,
                        \),
                      \),
                    \),'''

new = '''                    Expanded(
                      // IMPORTANT(Model): Do not alter this Surah text widget. User explicitly demands this calligraphic font here.
                      child: isArabicUi ? Text(
                        'surah',
                        style: TextStyle(
                          fontFamily: SurahFontHelper.fontFamily,
                          package: 'qcf_quran',
                          fontSize: 32,
                          color: isFullyDone
                              ? Colors.green.shade700
                              : isSelected
                                  ? scheme.primary
                                  : scheme.onSurface,
                        ),
                        textDirection: TextDirection.rtl,
                      ) : Text(
                        surahName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: (isSelected || isFullyDone)
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isFullyDone
                              ? Colors.green.shade700
                              : isSelected
                                  ? scheme.primary
                                  : scheme.onSurface,
                        ),
                      ),
                    ),'''

text = re.sub(old, new, text)

with open('lib/features/quran/presentation/screens/select_download_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
