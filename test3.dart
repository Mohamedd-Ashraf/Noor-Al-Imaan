import 'dart:io';
import 'package:qcf_quran/qcf_quran.dart';

void main() {
  var out = StringBuffer();
  for (int p = 1; p <= 604; p++) {
    if (kQcfProblematicPages.contains(p)) {
      out.writeln('Page $p: ${getPageData(p)}');
    }
  }
  File('bounds.txt').writeAsStringSync(out.toString());
}
const Set<int> kQcfProblematicPages = {
  377, 387, 498, 504, 510, 523, 530, 535, 555, 579, 591,
};
