void main() {
  final page3Verses = [
    {'s': 2, 'v': 6,  'qcf': 'ﱁﱂﱃﱄﱅﱆﱇﱈﱉ\nﱊﱋﱌ'},
    {'s': 2, 'v': 7,  'qcf': 'ﱍﱎﱏﱐﱑﱒﱓﱔ\nﱕﱖﱗﱘﱙﱚﱛ'},
    {'s': 2, 'v': 8,  'qcf': 'ﱜﱝ\nﱞﱟﱠﱡﱢﱣﱤﱥﱦﱧ'},
    {'s': 2, 'v': 9,  'qcf': '\nﱨﱩﱪﱫﱬﱭﱮﱯ\nﱰﱱﱲ'},
    {'s': 2, 'v': 10, 'qcf': 'ﱳﱴﱵﱶﱷﱸﱹ\nﱺﱻﱼﱽﱾﱿﲀ'},
    {'s': 2, 'v': 11, 'qcf': 'ﲁﲂﲃ\nﲄﲅﲆﲇﲈﲉﲊﲋﲌ'},
    {'s': 2, 'v': 12, 'qcf': 'ﲍﲎ\nﲏﲐﲑﲒﲓﲔ'},
    {'s': 2, 'v': 13, 'qcf': 'ﲕﲖﲗ\nﲘﲙﲚﲛﲜﲝﲞﲟﲠﲡ\nﲢﲣﲤﲥﲦﲧﲨﲩ'},
    {'s': 2, 'v': 14, 'qcf': 'ﲪﲫ\nﲬﲭﲮﲯﲰﲱﲲﲳﲴﲵ\nﲶﲷﲸﲹﲺ'},
    {'s': 2, 'v': 15, 'qcf': 'ﲻﲼﲽﲾ\nﲿﳀﳁﳂ'},
    {'s': 2, 'v': 16, 'qcf': 'ﳃﳄﳅﳆ\nﳇﳈﳉﳊﳋﳌﳍﳎ'},
  ];

  // Also check the content (Arabic text) for waqf signs
  final page3Content = [
    {'s': 2, 'v': 7,  'content': 'خَتَمَ ٱللَّهُ عَلَىٰ قُلُوبِهِمۡ وَعَلَىٰ سَمۡعِهِمۡۖ وَعَلَىٰٓ أَبۡصَٰرِهِمۡ غِشَٰوَةٞۖ وَلَهُمۡ عَذَابٌ عَظِيمٞ'},
    {'s': 2, 'v': 10, 'content': 'فِي قُلُوبِهِم مَّرَضٞ فَزَادَهُمُ ٱللَّهُ مَرَضٗاۖ وَلَهُمۡ عَذَابٌ أَلِيمُۢ بِمَا كَانُواْ يَكۡذِبُونَ'},
    {'s': 2, 'v': 13, 'content': 'وَإِذَا قِيلَ لَهُمۡ ءَامِنُواْ كَمَآ ءَامَنَ ٱلنَّاسُ قَالُوٓاْ أَنُؤۡمِنُ كَمَآ ءَامَنَ ٱلسُّفَهَآءُۗ أَلَآ إِنَّهُمۡ هُمُ ٱلسُّفَهَآءُ وَلَٰكِن لَّا يَعۡلَمُونَ'},
  ];

  print('=== QCF Glyph Analysis for Page 3 ===\n');

  for (final v in page3Verses) {
    final qcf = v['qcf'] as String;
    final glyphs = qcf.runes.toList();
    final nonNewline = glyphs.where((c) => c != 0x0A).toList();
    
    print('--- Verse ${v['s']}:${v['v']} ---');
    print('Total runes: ${glyphs.length}, glyphs (excl newlines): ${nonNewline.length}');
    print('Codepoints:');
    for (int i = 0; i < glyphs.length; i++) {
      final cp = glyphs[i];
      if (cp == 0x0A) {
        print('  [$i] U+000A <newline>');
      } else {
        print('  [$i] U+${cp.toRadixString(16).toUpperCase().padLeft(4, '0')} ${String.fromCharCode(cp)}');
      }
    }
    
    // Check: last non-newline glyph is the verse-end symbol
    final lastGlyph = nonNewline.last;
    print('Last glyph (verse-end): U+${lastGlyph.toRadixString(16).toUpperCase().padLeft(4, '0')}');
    print('');
  }

  // Check for waqf signs in Arabic content
  print('\n=== Waqf Sign Analysis ===\n');
  
  // Common waqf sign Unicode codepoints
  final waqfSigns = {
    0x06D6: 'ARABIC SMALL HIGH LIGATURE SAD WITH LAM WITH ALEF MAKSURA (صلى)',
    0x06D7: 'ARABIC SMALL HIGH LIGATURE QAF WITH LAM WITH ALEF MAKSURA (قلى)',
    0x06D8: 'ARABIC SMALL HIGH MEEM INITIAL FORM',
    0x06D9: 'ARABIC SMALL HIGH LAM ALEF',
    0x06DA: 'ARABIC SMALL HIGH JEEM',
    0x06DB: 'ARABIC SMALL HIGH THREE DOTS',
    0x06DC: 'ARABIC SMALL HIGH SEEN',
    0x06DD: 'ARABIC END OF AYAH',
    0x06DE: 'ARABIC START OF RUB EL HIZB',
    0x06DF: 'ARABIC SMALL HIGH ROUNDED ZERO',
    0x06E0: 'ARABIC SMALL HIGH UPRIGHT RECTANGULAR ZERO',
    0x06E1: 'ARABIC SMALL HIGH DOTLESS HEAD OF KHAH',
    0x06E2: 'ARABIC SMALL HIGH MEEM ISOLATED FORM',
    0x06E3: 'ARABIC SMALL LOW SEEN',
    0x06E4: 'ARABIC SMALL HIGH MADDA',
    0x06E5: 'ARABIC SMALL WAW',
    0x06E6: 'ARABIC SMALL YEH',
    0x06E7: 'ARABIC SMALL HIGH YEH',
    0x06E8: 'ARABIC SMALL HIGH NOON',
    0x06E9: 'ARABIC PLACE OF SAJDAH',
    0x06EA: 'ARABIC EMPTY CENTRE LOW STOP',
    0x06EB: 'ARABIC EMPTY CENTRE HIGH STOP',
    0x06EC: 'ARABIC ROUNDED HIGH STOP WITH FILLED CENTRE',
    0x06ED: 'ARABIC SMALL LOW MEEM',
  };

  // Also check for these common waqf signs used in Uthmanic text
  final waqfChars = [0x06D6, 0x06D7, 0x06D8, 0x06D9, 0x06DA, 0x06DB, 0x06DC, 0x06DD, 0x06DE, 0x0615, 0x0616, 0x0617];

  for (final v in page3Content) {
    final content = v['content'] as String;
    print('Verse ${v['s']}:${v['v']}:');
    for (final rune in content.runes) {
      if (rune >= 0x06D6 && rune <= 0x06ED) {
        print('  Found U+${rune.toRadixString(16).toUpperCase()} ${waqfSigns[rune] ?? "unknown"} at position');
      }
      // Also check for ۗ (U+06D7) and ۖ (U+06D6) which are waqf marks
    }
    print('');
  }

  // Key question: in QCF mode, each glyph in the PUA range is a WORD-level ligature.
  // The QCF font has per-page fonts (QCF_P001 through QCF_P604).
  // Each glyph in the Private Use Area maps to a pre-rendered word shape in that page's font.
  // Waqf signs in the content text are part of the Arabic word they attach to.
  // But in QCF, they may be separate glyphs or merged into word glyphs.

  print('\n=== Glyph count per line for page 3 ===\n');
  for (final v in page3Verses) {
    final qcf = v['qcf'] as String;
    final lines = qcf.split('\n');
    print('Verse ${v['s']}:${v['v']}:');
    for (int l = 0; l < lines.length; l++) {
      final line = lines[l];
      print('  Line $l: ${line.runes.length} glyphs');
    }
  }
}
