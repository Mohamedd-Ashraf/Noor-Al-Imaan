import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../network/network_info.dart';

class AudioEdition {
  final String identifier;
  final String? name;
  final String? englishName;
  final String? language;
  final String? format;
  final String? type;

  const AudioEdition({
    required this.identifier,
    this.name,
    this.englishName,
    this.language,
    this.format,
    this.type,
  });

  /// Default (legacy) display name.
  ///
  /// Prefers `englishName` then `name`, falling back to `identifier`.
  String get displayName => displayNameForAppLanguage('en');

  /// Display name that matches the app UI language.
  ///
  /// - If app language is Arabic, prefer `name` (often Arabic) then `englishName`.
  /// - Otherwise, prefer `englishName` then `name`.
  String displayNameForAppLanguage(String appLanguageCode) {
    final isArabicUi = appLanguageCode.toLowerCase().startsWith('ar');

    String? primary;
    String? secondary;

    if (isArabicUi) {
      primary = name;
      secondary = englishName;
    } else {
      primary = englishName;
      secondary = name;
    }

    final best = (primary?.trim().isNotEmpty ?? false)
        ? primary!.trim()
        : (secondary?.trim().isNotEmpty ?? false)
            ? secondary!.trim()
            : identifier;

    if (best == identifier) return identifier;
    return '$best ($identifier)';
  }

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'name': name,
        'englishName': englishName,
        'language': language,
        'format': format,
        'type': type,
      };

  factory AudioEdition.fromJson(Map<String, dynamic> json) {
    return AudioEdition(
      identifier: (json['identifier'] as String?) ?? '',
      name: json['name'] as String?,
      englishName: json['englishName'] as String?,
      language: json['language'] as String?,
      format: json['format'] as String?,
      type: json['type'] as String?,
    );
  }
}

class AudioEditionService {
  static const _cacheKey = 'audio_editions_cache_v1';

  final SharedPreferences _prefs;
  final http.Client _client;
  final NetworkInfo _networkInfo;

  AudioEditionService(this._prefs, this._client, this._networkInfo);

  List<AudioEdition> _readCache() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(AudioEdition.fromJson)
          .where((e) => e.identifier.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeCache(List<AudioEdition> editions) async {
    final payload = jsonEncode(editions.map((e) => e.toJson()).toList());
    await _prefs.setString(_cacheKey, payload);
  }

  /// Returns the available *verse-by-verse* audio editions (reciters) from AlQuran.cloud.
  ///
  /// Uses a cache so it still shows options when offline (after one successful fetch).
  Future<List<AudioEdition>> getVerseByVerseAudioEditions() async {
    final cached = _readCache();

    if (!await _networkInfo.isConnected) {
      return cached;
    }

    // AlQuran.cloud: /edition?format=audio&type=versebyverse
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.editionEndpoint}?format=audio&type=versebyverse',
    );

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      // If request fails, fall back to cache.
      return cached;
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is! List) {
      return cached;
    }

    final editions = <AudioEdition>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final identifier = item['identifier'];
      if (identifier is! String || identifier.trim().isEmpty) continue;

      editions.add(
        AudioEdition(
          identifier: identifier,
          name: item['name'] as String?,
          englishName: item['englishName'] as String?,
          language: item['language'] as String?,
          format: item['format'] as String?,
          type: item['type'] as String?,
        ),
      );
    }

    editions.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    if (editions.isNotEmpty) {
      await _writeCache(editions);
      return editions;
    }

    return cached;
  }
}
