void main() {
  // Compare QCF glyph count with Arabic word count for page 3 verses
  // to see how waqf signs map to glyphs
  
  final verses = [
    {
      's': 2, 'v': 6,
      'content': 'إِنَّ ٱلَّذِينَ كَفَرُواْ سَوَآءٌ عَلَيۡهِمۡ ءَأَنذَرۡتَهُمۡ أَمۡ لَمۡ تُنذِرۡهُمۡ لَا يُؤۡمِنُونَ',
      'qcf': 'ﱁﱂﱃﱄﱅﱆﱇﱈﱉ\nﱊﱋﱌ',
    },
    {
      's': 2, 'v': 7,
      'content': 'خَتَمَ ٱللَّهُ عَلَىٰ قُلُوبِهِمۡ وَعَلَىٰ سَمۡعِهِمۡۖ وَعَلَىٰٓ أَبۡصَٰرِهِمۡ غِشَٰوَةٞۖ وَلَهُمۡ عَذَابٌ عَظِيمٞ',
      'qcf': 'ﱍﱎﱏﱐﱑﱒﱓﱔ\nﱕﱖﱗﱘﱙﱚﱛ',
      'note': 'Has waqf ۖ (U+06D6) after سَمۡعِهِمۡۖ and غِشَٰوَةٞۖ',
    },
    {
      's': 2, 'v': 10,
      'content': 'فِي قُلُوبِهِم مَّرَضٞ فَزَادَهُمُ ٱللَّهُ مَرَضٗاۖ وَلَهُمۡ عَذَابٌ أَلِيمُۢ بِمَا كَانُواْ يَكۡذِبُونَ',
      'qcf': 'ﱳﱴﱵﱶﱷﱸﱹ\nﱺﱻﱼﱽﱾﱿﲀ',
      'note': 'Has waqf ۖ (U+06D6) after مَرَضٗاۖ',
    },
    {
      's': 2, 'v': 13,
      'content': 'وَإِذَا قِيلَ لَهُمۡ ءَامِنُواْ كَمَآ ءَامَنَ ٱلنَّاسُ قَالُوٓاْ أَنُؤۡمِنُ كَمَآ ءَامَنَ ٱلسُّفَهَآءُۗ أَلَآ إِنَّهُمۡ هُمُ ٱلسُّفَهَآءُ وَلَٰكِن لَّا يَعۡلَمُونَ',
      'qcf': 'ﲕﲖﲗ\nﲘﲙﲚﲛﲜﲝﲞﲟﲠﲡ\nﲢﲣﲤﲥﲦﲧﲨﲩ',
      'note': 'Has waqf ۗ (U+06D7 = qly) after ٱلسُّفَهَآءُۗ',
    },
  ];

  for (final v in verses) {
    final content = v['content'] as String;
    final qcf = v['qcf'] as String;
    
    // Split content by spaces to get words
    final words = content.split(' ');
    
    // Count QCF glyphs (excluding newlines and the verse-end symbol)
    final allGlyphs = qcf.runes.where((c) => c != 0x0A).toList();
    final verseGlyphs = allGlyphs.sublist(0, allGlyphs.length - 1); // minus verse-end
    
    print('=== Verse ${v['s']}:${v['v']} ===');
    print('Arabic words: ${words.length}');
    print('QCF glyphs (excl verse-end): ${verseGlyphs.length}');
    print('QCF total glyphs (incl verse-end): ${allGlyphs.length}');
    if (v.containsKey('note')) print('Note: ${v['note']}');
    
    print('Words: ${words.join(" | ")}');
    
    // Check if glyph count matches word count
    if (verseGlyphs.length == words.length) {
      print('>> MATCH: 1 glyph per word (waqf signs merged into word glyphs)');
    } else if (verseGlyphs.length > words.length) {
      print('>> MORE GLYPHS than words (${verseGlyphs.length - words.length} extra) — possible separate waqf glyphs');
    } else {
      print('>> FEWER GLYPHS than words (some words merged into single glyph)');
    }
    print('');
  }
  
  // More detailed: verse 2:7 has ۖ waqf signs
  print('\n=== Detailed word-to-glyph for 2:7 ===');
  final v7content = 'خَتَمَ ٱللَّهُ عَلَىٰ قُلُوبِهِمۡ وَعَلَىٰ سَمۡعِهِمۡۖ وَعَلَىٰٓ أَبۡصَٰرِهِمۡ غِشَٰوَةٞۖ وَلَهُمۡ عَذَابٌ عَظِيمٞ';
  final v7words = v7content.split(' ');
  final v7qcf = 'ﱍﱎﱏﱐﱑﱒﱓﱔ\nﱕﱖﱗﱘﱙﱚﱛ';
  final v7glyphs = v7qcf.runes.where((c) => c != 0x0A).toList();
  
  print('Words (${v7words.length}):');
  for (int i = 0; i < v7words.length; i++) {
    final word = v7words[i];
    // Check if word contains waqf
    final hasWaqf = word.runes.any((r) => r >= 0x06D6 && r <= 0x06DA);
    print('  [$i] "$word" ${hasWaqf ? "** HAS WAQF **" : ""}');
  }
  print('Glyphs (${v7glyphs.length}):');
  for (int i = 0; i < v7glyphs.length; i++) {
    print('  [$i] U+${v7glyphs[i].toRadixString(16).toUpperCase().padLeft(4, '0')}');
  }
  
  // Verse 2:13 has ۗ (qly waqf) after ٱلسُّفَهَآءُۗ
  print('\n=== Detailed word-to-glyph for 2:13 ===');
  final v13content = 'وَإِذَا قِيلَ لَهُمۡ ءَامِنُواْ كَمَآ ءَامَنَ ٱلنَّاسُ قَالُوٓاْ أَنُؤۡمِنُ كَمَآ ءَامَنَ ٱلسُّفَهَآءُۗ أَلَآ إِنَّهُمۡ هُمُ ٱلسُّفَهَآءُ وَلَٰكِن لَّا يَعۡلَمُونَ';
  final v13words = v13content.split(' ');
  final v13qcf = 'ﲕﲖﲗ\nﲘﲙﲚﲛﲜﲝﲞﲟﲠﲡ\nﲢﲣﲤﲥﲦﲧﲨﲩ';
  final v13glyphs = v13qcf.runes.where((c) => c != 0x0A).toList();
  
  print('Words (${v13words.length}):');
  for (int i = 0; i < v13words.length; i++) {
    final word = v13words[i];
    final hasWaqf = word.runes.any((r) => r >= 0x06D6 && r <= 0x06DA);
    print('  [$i] "$word" ${hasWaqf ? "** HAS WAQF **" : ""}');
  }
  print('Glyphs (${v13glyphs.length}):');
  for (int i = 0; i < v13glyphs.length; i++) {
    print('  [$i] U+${v13glyphs[i].toRadixString(16).toUpperCase().padLeft(4, '0')}');
  }
}
