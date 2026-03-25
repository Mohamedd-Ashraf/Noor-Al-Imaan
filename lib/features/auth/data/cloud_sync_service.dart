import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/bookmark_service.dart';
import '../../wird/data/wird_service.dart';

/// Syncs local user data (wird, bookmarks, settings) to/from Firestore.
///
/// Firestore structure:
/// ```
/// users/{uid}/
///   profile: { displayName, email, lastSyncedAt }
///   data/bookmarks: { items: [...] }
///   data/wird:      { type, startDate, targetDays, ... }
///   data/settings:  { darkMode, arabicFontSize, ... }
/// ```
class CloudSyncService {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  final BookmarkService _bookmarkService;
  final WirdService _wirdService;

  static const String _keyLastSyncTime = 'cloud_last_sync_time';

  CloudSyncService(
    this._firestore,
    this._prefs,
    this._bookmarkService,
    this._wirdService,
  );

  /// Returns the Firestore document reference for the current user.
  DocumentReference? _userDoc(User? user) {
    if (user == null || user.isAnonymous) return null;
    return _firestore.collection('users').doc(user.uid);
  }

  /// Uploads all local data to Firestore for the given user.
  Future<void> uploadAll(User user) async {
    final doc = _userDoc(user);
    if (doc == null) return;

    try {
      await Future.wait([
        _uploadProfile(doc, user),
        _uploadBookmarks(doc),
        _uploadWird(doc),
        _uploadSettings(doc),
      ]);
      await _prefs.setString(
        _keyLastSyncTime,
        DateTime.now().toIso8601String(),
      );
      debugPrint('CloudSync: uploaded all data for ${user.uid}');
    } catch (e, st) {
      debugPrint('CloudSync: upload failed: $e\n$st');
    }
  }

  /// Downloads all data from Firestore and overwrites local storage.
  Future<void> downloadAll(User user) async {
    final doc = _userDoc(user);
    if (doc == null) return;

    try {
      await Future.wait([
        _downloadBookmarks(doc),
        _downloadWird(doc),
        _downloadSettings(doc),
      ]);
      await _prefs.setString(
        _keyLastSyncTime,
        DateTime.now().toIso8601String(),
      );
      debugPrint('CloudSync: downloaded all data for ${user.uid}');
    } catch (e, st) {
      debugPrint('CloudSync: download failed: $e\n$st');
    }
  }

  /// Smart sync: uploads local data if it's newer, downloads if cloud is newer.
  /// On first sign-in, uploads local data.
  Future<void> syncAll(User user) async {
    final doc = _userDoc(user);
    if (doc == null) return;

    try {
      final profileSnap = await doc.get();
      if (!profileSnap.exists) {
        // First time: upload everything
        await uploadAll(user);
        return;
      }

      final cloudData = profileSnap.data() as Map<String, dynamic>?;
      final cloudSyncTime = cloudData?['lastSyncedAt'] as Timestamp?;
      final localSyncStr = _prefs.getString(_keyLastSyncTime);

      if (cloudSyncTime == null || localSyncStr == null) {
        // No previous sync reference, upload local
        await uploadAll(user);
        return;
      }

      final localSyncTime = DateTime.tryParse(localSyncStr);
      if (localSyncTime == null) {
        await uploadAll(user);
        return;
      }

      final cloudTime = cloudSyncTime.toDate();
      if (localSyncTime.isAfter(cloudTime)) {
        await uploadAll(user);
      } else {
        await downloadAll(user);
      }
    } catch (e, st) {
      debugPrint('CloudSync: syncAll failed: $e\n$st');
      // Fallback: upload local data
      await uploadAll(user);
    }
  }

  // ── Profile ─────────────────────────────────────────────────────────────

  Future<void> _uploadProfile(DocumentReference doc, User user) async {
    await doc.set({
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'lastSyncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Bookmarks ───────────────────────────────────────────────────────────

  Future<void> _uploadBookmarks(DocumentReference doc) async {
    final bookmarks = _bookmarkService.getBookmarks();
    await doc.collection('data').doc('bookmarks').set({
      'items': bookmarks,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _downloadBookmarks(DocumentReference doc) async {
    final snap = await doc.collection('data').doc('bookmarks').get();
    if (!snap.exists) return;

    final data = snap.data();
    if (data == null) return;

    final items = data['items'] as List<dynamic>?;
    if (items == null) return;

    // Clear local and replace
    await _bookmarkService.clearAllBookmarks();
    for (final item in items) {
      final map = Map<String, dynamic>.from(item as Map);
      await _bookmarkService.addBookmark(
        id: map['id']?.toString() ?? '',
        reference: map['reference']?.toString() ?? '',
        arabicText: map['arabicText']?.toString() ?? '',
        surahName: map['surahName']?.toString(),
        note: map['note']?.toString(),
        surahNumber: map['surahNumber'] as int?,
        ayahNumber: map['ayahNumber'] as int?,
        pageNumber: map['pageNumber'] as int?,
      );
    }
  }

  // ── Wird ────────────────────────────────────────────────────────────────

  Future<void> _uploadWird(DocumentReference doc) async {
    final plan = _wirdService.getPlan();
    final reminderTime = _wirdService.getReminderTime();

    final wirdData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (plan != null) {
      wirdData['type'] = plan.type == WirdType.ramadan ? 'ramadan' : 'regular';
      wirdData['startDate'] = plan.startDate.toIso8601String();
      wirdData['targetDays'] = plan.targetDays;
      wirdData['planMode'] =
          plan.planMode == WirdPlanMode.pages ? 'pages' : 'days';
      wirdData['pagesPerDay'] = plan.pagesPerDay;
      wirdData['completedDays'] = plan.completedDays;
      wirdData['lastReadSurah'] = _wirdService.lastReadSurah;
      wirdData['lastReadAyah'] = _wirdService.lastReadAyah;
      wirdData['makeupDay'] = _wirdService.makeupBookmarkDay;
      wirdData['makeupSurah'] = _wirdService.makeupBookmarkSurah;
      wirdData['makeupAyah'] = _wirdService.makeupBookmarkAyah;
      wirdData['notificationsEnabled'] = _wirdService.notificationsEnabled;
      wirdData['followUpIntervalHours'] = _wirdService.followUpIntervalHours;
      if (reminderTime != null) {
        wirdData['reminderHour'] = reminderTime['hour'];
        wirdData['reminderMinute'] = reminderTime['minute'];
      }
    } else {
      wirdData['type'] = null; // no plan
    }

    await doc.collection('data').doc('wird').set(wirdData);
  }

  Future<void> _downloadWird(DocumentReference doc) async {
    final snap = await doc.collection('data').doc('wird').get();
    if (!snap.exists) return;

    final data = snap.data();
    if (data == null || data['type'] == null) return;

    final typeStr = data['type'] as String;
    final type =
        typeStr == 'ramadan' ? WirdType.ramadan : WirdType.regular;
    final startDateStr = data['startDate'] as String?;
    if (startDateStr == null) return;

    final startDate = DateTime.tryParse(startDateStr);
    if (startDate == null) return;

    final targetDays = data['targetDays'] as int? ?? 30;
    final planModeStr = data['planMode'] as String? ?? 'days';
    final planMode =
        planModeStr == 'pages' ? WirdPlanMode.pages : WirdPlanMode.days;
    final pagesPerDay = data['pagesPerDay'] as int?;
    final completedDays =
        (data['completedDays'] as List<dynamic>?)?.cast<int>() ?? [];

    await _wirdService.initPlan(
      type: type,
      startDate: startDate,
      targetDays: targetDays,
      planMode: planMode,
      pagesPerDay: pagesPerDay,
      completedDays: completedDays,
      reminderHour: data['reminderHour'] as int?,
      reminderMinute: data['reminderMinute'] as int?,
    );

    // Restore bookmarks
    final lastReadSurah = data['lastReadSurah'] as int?;
    final lastReadAyah = data['lastReadAyah'] as int?;
    if (lastReadSurah != null && lastReadAyah != null) {
      await _wirdService.saveLastRead(lastReadSurah, lastReadAyah);
    }

    final makeupDay = data['makeupDay'] as int?;
    final makeupSurah = data['makeupSurah'] as int?;
    final makeupAyah = data['makeupAyah'] as int?;
    if (makeupDay != null && makeupSurah != null && makeupAyah != null) {
      await _wirdService.saveMakeupBookmark(makeupDay, makeupSurah, makeupAyah);
    }

    if (data['notificationsEnabled'] != null) {
      await _wirdService
          .setNotificationsEnabled(data['notificationsEnabled'] as bool);
    }
    if (data['followUpIntervalHours'] != null) {
      await _wirdService
          .setFollowUpIntervalHours(data['followUpIntervalHours'] as int);
    }
  }

  // ── Settings ────────────────────────────────────────────────────────────

  /// Keys that are synced to the cloud. Device-specific settings
  /// (notifications, location, audio stream) are intentionally excluded.
  static const _syncedSettingsKeys = [
    'arabic_font_size',
    'translation_font_size',
    'dark_mode',
    'show_translation',
    'app_language',
    'use_uthmani_script',
    'use_qcf_font',
    'page_flip_right_to_left',
    'diacritics_color_mode',
    'quran_edition',
    'quran_font',
    'scroll_mode',
    'word_by_word_audio',
    'mushaf_continue_tilawa',
    'mushaf_continue_scope',
    'hijri_date_offset',
  ];

  Future<void> _uploadSettings(DocumentReference doc) async {
    final settings = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    for (final key in _syncedSettingsKeys) {
      final value = _prefs.get(key);
      if (value != null) {
        settings[key] = value;
      }
    }

    await doc.collection('data').doc('settings').set(settings);
  }

  Future<void> _downloadSettings(DocumentReference doc) async {
    final snap = await doc.collection('data').doc('settings').get();
    if (!snap.exists) return;

    final data = snap.data();
    if (data == null) return;

    for (final key in _syncedSettingsKeys) {
      final value = data[key];
      if (value == null) continue;

      if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is String) {
        await _prefs.setString(key, value);
      }
    }
  }

  /// Whether this device has ever synced.
  bool get hasSynced => _prefs.containsKey(_keyLastSyncTime);

  /// Last sync timestamp.
  DateTime? get lastSyncTime {
    final str = _prefs.getString(_keyLastSyncTime);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}
