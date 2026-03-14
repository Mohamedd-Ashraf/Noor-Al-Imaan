import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';

class TafsirEditionCacheStats {
	final String edition;
	final int ayahCount;
	final int bytes;

	const TafsirEditionCacheStats({
		required this.edition,
		required this.ayahCount,
		required this.bytes,
	});
}

abstract class QuranLocalTafsirDataSource {
	Future<void> cacheAyahTafsir({
		required String edition,
		required int surahNumber,
		required int ayahNumber,
		required String text,
	});

	Future<void> cacheAyahBatchForSurah({
		required String edition,
		required int surahNumber,
		required Map<int, String> ayahTexts,
	});

	Future<String> getCachedAyahTafsir({
		required String edition,
		required int surahNumber,
		required int ayahNumber,
	});

	Future<bool> hasCachedAyahTafsir({
		required String edition,
		required int surahNumber,
		required int ayahNumber,
	});

	Future<Set<int>> getCachedAyahNumbersForSurah({
		required String edition,
		required int surahNumber,
	});

	Future<int> getCachedAyahCountForEdition(String edition);
	Future<int> getCachedSizeBytesForEdition(String edition);
	Future<TafsirEditionCacheStats> getEditionStats(String edition);
	Future<void> deleteEditionCache(String edition);
}

class QuranLocalTafsirDataSourceImpl implements QuranLocalTafsirDataSource {
	static const String _cacheFolderName = 'tafsir_cache_v1';

	Future<Directory> _editionDirectory(String edition) async {
		final docs = await getApplicationDocumentsDirectory();
		final safeEdition = edition.replaceAll('.', '_').replaceAll(':', '_');
		final dir = Directory('${docs.path}/$_cacheFolderName/$safeEdition');
		if (!await dir.exists()) {
			await dir.create(recursive: true);
		}
		return dir;
	}

	Future<File> _surahFile(String edition, int surahNumber) async {
		final dir = await _editionDirectory(edition);
		return File('${dir.path}/surah_$surahNumber.json');
	}

	Future<Map<String, dynamic>> _readSurahMap(
		String edition,
		int surahNumber,
	) async {
		final file = await _surahFile(edition, surahNumber);
		if (!await file.exists()) return <String, dynamic>{};

		try {
			final raw = await file.readAsString();
			if (raw.trim().isEmpty) return <String, dynamic>{};
			final decoded = json.decode(raw);
			if (decoded is Map<String, dynamic>) {
				return decoded;
			}
			return <String, dynamic>{};
		} catch (_) {
			// Corrupted cache should not crash tafsir rendering.
			return <String, dynamic>{};
		}
	}

	@override
	Future<void> cacheAyahTafsir({
		required String edition,
		required int surahNumber,
		required int ayahNumber,
		required String text,
	}) async {
		final map = await _readSurahMap(edition, surahNumber);
		map[ayahNumber.toString()] = text;
		final file = await _surahFile(edition, surahNumber);
		await file.writeAsString(
			json.encode(map),
			flush: true,
		);
	}

	@override
	Future<void> cacheAyahBatchForSurah({
		required String edition,
		required int surahNumber,
		required Map<int, String> ayahTexts,
	}) async {
		if (ayahTexts.isEmpty) return;
		final map = await _readSurahMap(edition, surahNumber);
		ayahTexts.forEach((ayah, text) {
			map[ayah.toString()] = text;
		});
		final file = await _surahFile(edition, surahNumber);
		await file.writeAsString(
			json.encode(map),
			flush: true,
		);
	}

	@override
	Future<String> getCachedAyahTafsir({
		required String edition,
		required int surahNumber,
		required int ayahNumber,
	}) async {
		final map = await _readSurahMap(edition, surahNumber);
		final value = map[ayahNumber.toString()];
		if (value is String) return value;
		throw CacheException();
	}

	@override
	Future<bool> hasCachedAyahTafsir({
		required String edition,
		required int surahNumber,
		required int ayahNumber,
	}) async {
		final map = await _readSurahMap(edition, surahNumber);
		return map[ayahNumber.toString()] is String;
	}

	@override
	Future<Set<int>> getCachedAyahNumbersForSurah({
		required String edition,
		required int surahNumber,
	}) async {
		final map = await _readSurahMap(edition, surahNumber);
		final out = <int>{};
		map.forEach((k, v) {
			if (v is! String || v.trim().isEmpty) return;
			final n = int.tryParse(k);
			if (n != null && n > 0) out.add(n);
		});
		return out;
	}

	@override
	Future<int> getCachedAyahCountForEdition(String edition) async {
		final stats = await getEditionStats(edition);
		return stats.ayahCount;
	}

	@override
	Future<int> getCachedSizeBytesForEdition(String edition) async {
		final stats = await getEditionStats(edition);
		return stats.bytes;
	}

	@override
	Future<TafsirEditionCacheStats> getEditionStats(String edition) async {
		final dir = await _editionDirectory(edition);
		if (!await dir.exists()) {
			return TafsirEditionCacheStats(
				edition: edition,
				ayahCount: 0,
				bytes: 0,
			);
		}

		int total = 0;
		int totalBytes = 0;
		await for (final entity in dir.list(followLinks: false)) {
			if (entity is! File || !entity.path.endsWith('.json')) continue;
			try {
				totalBytes += await entity.length();
				final raw = await entity.readAsString();
				final decoded = json.decode(raw);
				if (decoded is Map<String, dynamic>) {
					total += decoded.length;
				}
			} catch (_) {
				// Ignore corrupted file and continue counting other files.
			}
		}

		return TafsirEditionCacheStats(
			edition: edition,
			ayahCount: total,
			bytes: totalBytes,
		);
	}

	@override
	Future<void> deleteEditionCache(String edition) async {
		final dir = await _editionDirectory(edition);
		if (await dir.exists()) {
			await dir.delete(recursive: true);
		}
	}
}
