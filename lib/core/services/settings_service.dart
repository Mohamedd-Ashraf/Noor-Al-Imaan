import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyArabicFontSize = 'arabic_font_size';
  static const String _keyTranslationFontSize = 'translation_font_size';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyShowTranslation = 'show_translation';
  static const String _keyAppLanguage = 'app_language';
  static const String _keyUseUthmaniScript = 'use_uthmani_script';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyAdhanNotificationsEnabled = 'adhan_notifications_enabled';
  static const String _keyAdhanIncludeFajr = 'adhan_include_fajr';
  static const String _keyLastKnownLat = 'last_known_lat';
  static const String _keyLastKnownLng = 'last_known_lng';
  static const String _keyLastAdhanScheduleDateIso = 'last_adhan_schedule_date_iso';
  static const String _keyAdhanUseCustomSound = 'adhan_use_custom_sound';
  static const String _keyCachedPrayerTimes = 'cached_prayer_times';
  static const String _keyAdhanSchedulePreview = 'adhan_schedule_preview';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // Arabic Font Size
  Future<bool> setArabicFontSize(double size) async {
    return await _prefs.setDouble(_keyArabicFontSize, size);
  }

  double getArabicFontSize() {
    return _prefs.getDouble(_keyArabicFontSize) ?? 24.0;
  }

  // Translation Font Size
  Future<bool> setTranslationFontSize(double size) async {
    return await _prefs.setDouble(_keyTranslationFontSize, size);
  }

  double getTranslationFontSize() {
    return _prefs.getDouble(_keyTranslationFontSize) ?? 16.0;
  }

  // Dark Mode
  Future<bool> setDarkMode(bool enabled) async {
    return await _prefs.setBool(_keyDarkMode, enabled);
  }

  bool getDarkMode() {
    return _prefs.getBool(_keyDarkMode) ?? false;
  }

  // Show Translation
  Future<bool> setShowTranslation(bool enabled) async {
    return await _prefs.setBool(_keyShowTranslation, enabled);
  }

  bool getShowTranslation() {
    return _prefs.getBool(_keyShowTranslation) ?? false;
  }

  // App Language
  Future<bool> setAppLanguage(String languageCode) async {
    return await _prefs.setString(_keyAppLanguage, languageCode);
  }

  String getAppLanguage() {
    return _prefs.getString(_keyAppLanguage) ?? 'en';
  }

  // Use Uthmani Script
  Future<bool> setUseUthmaniScript(bool enabled) async {
    return await _prefs.setBool(_keyUseUthmaniScript, enabled);
  }

  bool getUseUthmaniScript() {
    return _prefs.getBool(_keyUseUthmaniScript) ?? true;
  }

  // Onboarding
  Future<bool> setOnboardingComplete(bool complete) async {
    return await _prefs.setBool(_keyOnboardingComplete, complete);
  }

  bool getOnboardingComplete() {
    return _prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  // Adhan notifications
  Future<bool> setAdhanNotificationsEnabled(bool enabled) async {
    return await _prefs.setBool(_keyAdhanNotificationsEnabled, enabled);
  }

  bool getAdhanNotificationsEnabled() {
    // Default ON so reminders work automatically after first install.
    return _prefs.getBool(_keyAdhanNotificationsEnabled) ?? true;
  }

  Future<bool> setAdhanIncludeFajr(bool include) async {
    return await _prefs.setBool(_keyAdhanIncludeFajr, include);
  }

  bool getAdhanIncludeFajr() {
    return _prefs.getBool(_keyAdhanIncludeFajr) ?? true;
  }

  Future<bool> setAdhanUseCustomSound(bool enabled) async {
    return await _prefs.setBool(_keyAdhanUseCustomSound, enabled);
  }

  bool getAdhanUseCustomSound() {
    return _prefs.getBool(_keyAdhanUseCustomSound) ?? false;
  }

  Future<void> setLastKnownCoordinates(double lat, double lng) async {
    await _prefs.setDouble(_keyLastKnownLat, lat);
    await _prefs.setDouble(_keyLastKnownLng, lng);
  }

  Coordinates? getLastKnownCoordinates() {
    final lat = _prefs.getDouble(_keyLastKnownLat);
    final lng = _prefs.getDouble(_keyLastKnownLng);
    if (lat == null || lng == null) return null;
    return Coordinates(lat, lng);
  }

  Future<bool> setLastAdhanScheduleDateIso(String iso) async {
    return await _prefs.setString(_keyLastAdhanScheduleDateIso, iso);
  }

  String? getLastAdhanScheduleDateIso() {
    return _prefs.getString(_keyLastAdhanScheduleDateIso);
  }

  // Prayer times cache (stores JSON for 30 days)
  Future<bool> setCachedPrayerTimes(String jsonData) async {
    return await _prefs.setString(_keyCachedPrayerTimes, jsonData);
  }

  String? getCachedPrayerTimes() {
    return _prefs.getString(_keyCachedPrayerTimes);
  }

  // Adhan schedule preview (JSON string)
  Future<bool> setAdhanSchedulePreview(String jsonData) async {
    return await _prefs.setString(_keyAdhanSchedulePreview, jsonData);
  }

  String? getAdhanSchedulePreview() {
    return _prefs.getString(_keyAdhanSchedulePreview);
  }
}
