import "dart:convert";
import "dart:io";
import "package:http/http.dart" as http;
void main() async {
  final surah = 5;
  final i = 97;
  final singleUri = Uri.parse("https://api.quran.com/api/v4/tafsirs/14/by_ayah/$surah:$i");
  final singleRes = await http.get(singleUri);
  print(singleRes.statusCode);
  print(singleRes.body.substring(0, 100));
}
