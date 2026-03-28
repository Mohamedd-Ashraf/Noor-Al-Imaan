import 'hadith_item.dart';
import 'hadith_list_item.dart';

/// A section (chapter) metadata from fawazahmed0/hadith-api.
class RemoteSection {
  final int sectionNumber;
  final String name;
  final int hadithFirst;
  final int hadithLast;

  const RemoteSection({
    required this.sectionNumber,
    required this.name,
    required this.hadithFirst,
    required this.hadithLast,
  });

  int get count => (hadithLast - hadithFirst + 1).clamp(0, 9999);

  /// Parse from the API metadata response.
  /// [sections] = { "1": "Revelation", "2": "Faith", ... }
  /// [sectionDetail] = { "1": { "hadithnumber_first": 1, "hadithnumber_last": 7 } ... }
  static List<RemoteSection> fromMetadata(
    Map<String, dynamic> sections,
    Map<String, dynamic> sectionDetail,
  ) {
    final result = <RemoteSection>[];
    for (final kv in sections.entries) {
      final detail = sectionDetail[kv.key] as Map<String, dynamic>?;
      if (detail == null) continue;
      final num = int.tryParse(kv.key);
      if (num == null) continue;
      result.add(
        RemoteSection(
          sectionNumber: num,
          name: kv.value as String? ?? '',
          hadithFirst: (detail['hadithnumber_first'] as int?) ?? 0,
          hadithLast: (detail['hadithnumber_last'] as int?) ?? 0,
        ),
      );
    }
    result.sort((a, b) => a.sectionNumber.compareTo(b.sectionNumber));
    return result;
  }
}

/// A single hadith entry from fawazahmed0/hadith-api.
class RemoteHadith {
  final int hadithNumber;
  final int arabicNumber;
  final String text;
  final List<String> grades;
  final int referenceBook;
  final int referenceHadith;

  const RemoteHadith({
    required this.hadithNumber,
    required this.arabicNumber,
    required this.text,
    required this.grades,
    required this.referenceBook,
    required this.referenceHadith,
  });

  factory RemoteHadith.fromJson(Map<String, dynamic> json) {
    final ref = json['reference'] as Map<String, dynamic>? ?? {};
    final rawGrades = json['grades'] as List<dynamic>? ?? [];
    return RemoteHadith(
      hadithNumber: (json['hadithnumber'] as int?) ?? 0,
      arabicNumber: (json['arabicnumber'] as int?) ?? 0,
      text: (json['text'] as String?) ?? '',
      grades: rawGrades
          .map((g) => (g as Map<String, dynamic>)['grade']?.toString() ?? '')
          .where((g) => g.isNotEmpty)
          .toList(),
      referenceBook: (ref['book'] as int?) ?? 0,
      referenceHadith: (ref['hadith'] as int?) ?? 0,
    );
  }

  /// Stable unique ID: "{book}_{sectionNumber}_{hadithNumber}".
  String stableId(String book, int sectionNumber) =>
      '${book}_${sectionNumber}_$hadithNumber';

  /// Attempts to split the raw text into sanad (chain) and matn (content).
  /// Uses the same comprehensive strategy as the Firestore datasource.
  /// Returns (sanad, matn).
  static (String, String) _splitSanadMatn(String raw) {
    if (raw.isEmpty) return ('', '');
    final total = raw.length;

    String stripTrailing(String s) =>
        s.replaceAll(RegExp(r'["\u201c\u201d\s.\u200f\u060c]+$'), '').trim();

    // Strategy A: رضى/رضي الله – FIRST occurrence
    for (final rida in ['رضى الله', 'رضي الله']) {
      final ridx = raw.indexOf(rida);
      if (ridx < 20) continue;
      final afterRida = raw.substring(ridx);
      for (final suffix in ['عنهما', 'عنهم', 'عنها', 'عنه']) {
        final sidx = afterRida.indexOf(suffix);
        if (sidx < 0) continue;
        var end = sidx + suffix.length;
        while (end < afterRida.length &&
            ' ـ\t،,'.contains(afterRida[end])) {
          end++;
        }
        final contentStart = ridx + end;
        final m = stripTrailing(raw.substring(contentStart).trim());
        if (m.length >= 10 && m.length >= total * 0.20) {
          return (raw.substring(0, contentStart).trim(), m);
        }
        break;
      }
    }

    // Strategy B: Prophet ﷺ marker (first occurrence)
    const sallaMarkers = [
      'صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ',
      'صلى الله عليه وسلم',
    ];
    int firstSalla = -1;
    int firstSallaLen = 0;
    for (final sm in sallaMarkers) {
      final idx = raw.indexOf(sm);
      if (idx > 20 && (firstSalla < 0 || idx < firstSalla)) {
        firstSalla = idx;
        firstSallaLen = sm.length;
      }
    }
    if (firstSalla > 20) {
      var after = raw
          .substring(firstSalla + firstSallaLen)
          .replaceFirst(RegExp(r'^[\s،,.]+'), '');
      for (final verb in ['قَالَ ', 'قَالَتْ ', 'أَنَّهُ ', 'قال ', 'يقول ']) {
        if (after.startsWith(verb)) {
          after = after.substring(verb.length);
          break;
        }
      }
      final m = stripTrailing(after.trim());
      if (m.length >= 20 && m.length >= total * 0.20) {
        return (raw.substring(0, firstSalla + firstSallaLen).trim(), m);
      }
    }

    // Strategy C: Quote mark in first 60 % of text
    final q = raw.indexOf('"');
    if (q > 30 && q < total * 0.60) {
      final m = stripTrailing(raw.substring(q + 1).trim());
      if (m.length >= 20) return (raw.substring(0, q).trim(), m);
    }

    // Fallback: whole text is matn
    return ('', raw.trim());
  }

  /// Convert to a full [HadithItem].
  HadithItem toHadithItem({
    required String book,
    required int sectionNumber,
    required String bookNameAr,
    required String sectionNameAr,
    required int sortOrder,
  }) {
    final (sanad, matn) = _splitSanadMatn(text);
    final id = stableId(book, sectionNumber);
    final gradeLabel = grades.isNotEmpty ? grades.first : '';
    return HadithItem(
      id: id,
      arabicText: matn.isNotEmpty ? matn : text,
      reference: '$bookNameAr حديث $hadithNumber',
      bookReference: '$bookNameAr: $sectionNameAr، حديث $hadithNumber',
      sanad: sanad,
      narrator: '',
      grade: _parseGrade(gradeLabel),
      gradedBy: gradeLabel,
      topicAr: sectionNameAr,
      topicEn: '',
      explanation: null,
      categoryId: book,
      sortOrder: sortOrder,
      isOffline: false,
    );
  }

  /// Convert to a lightweight [HadithListItem].
  HadithListItem toHadithListItem({
    required String book,
    required int sectionNumber,
    required String bookNameAr,
    required String sectionNameAr,
    required int sortOrder,
  }) {
    final (_, matn) = _splitSanadMatn(text);
    final displayText = matn.isNotEmpty ? matn : text;
    final preview = displayText.length > 150
        ? displayText.substring(0, 150)
        : displayText;
    final id = stableId(book, sectionNumber);
    final gradeLabel = grades.isNotEmpty ? grades.first : '';
    return HadithListItem(
      id: id,
      categoryId: book,
      arabicPreview: preview,
      topicAr: sectionNameAr,
      topicEn: '',
      narrator: '',
      reference: '$bookNameAr $hadithNumber',
      grade: _parseGrade(gradeLabel),
      sortOrder: sortOrder,
      isOffline: false,
    );
  }

  static HadithGrade _parseGrade(String label) {
    if (label.contains('صحيح') || label.toLowerCase().contains('sahih')) {
      return HadithGrade.sahih;
    }
    if (label.contains('حسن') || label.toLowerCase().contains('hasan')) {
      return HadithGrade.hasan;
    }
    return HadithGrade.sahih;
  }

  /// Parse a list of hadiths from an API section response JSON.
  static List<RemoteHadith> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((e) => RemoteHadith.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
