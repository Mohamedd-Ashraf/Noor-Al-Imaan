import "dart:convert";
import "dart:io";
import "package:http/http.dart" as http;
void main() async {
  print("checking missing");
  // Check which surahs fail to fetch all ayahs
  final counts = <int>[7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6];
  for (int surah = 1; surah <= 114; surah++){
    final expected = counts[surah - 1];
    final uri = Uri.parse("https://api.quran.com/api/v4/tafsirs/14/by_chapter/$surah?per_page=300");
    final res = await http.get(uri);
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    final tafsirs = decoded["tafsirs"] as List<dynamic>? ?? [];
    if (tafsirs.length != expected) {
      print("Surah $surah: expected $expected, got ${tafsirs.length}");
    }
  }
}
