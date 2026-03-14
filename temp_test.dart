import "dart:convert";
import "dart:io";
import "package:http/http.dart" as http;
void main() async {
  final uri = Uri.parse("https://api.quran.com/api/v4/tafsirs/14/by_chapter/1?per_page=300");
  final res = await http.get(uri);
  print(res.statusCode);
  print(res.body.length);
  final decoded = json.decode(res.body) as Map<String, dynamic>;     
  final tafsirs = decoded["tafsirs"] as List<dynamic>? ?? [];
  print("tafsirs count: ${tafsirs.length}");
}
