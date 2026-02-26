import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatsNewService {
  static const String _keyLastSeenVersion = 'last_seen_whats_new_version';

  /// ─── DEV FLAG ───────────────────────────────────────────────────────────
  /// Set to [true]  → screen shows on EVERY app launch (for design review).
  /// Set to [false] → screen shows only once per app version (production).
  /// ────────────────────────────────────────────────────────────────────────
  /// 
  //TODO : Remove this flag and related logic before release, to ensure users see the screen only on new versions.
  static const bool alwaysShow = false;


  final SharedPreferences _prefs;

  WhatsNewService(this._prefs);

  /// Returns true if the What's New screen should be shown.
  Future<bool> shouldShow() async {
    if (alwaysShow) return true;
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;
    final lastSeen = _prefs.getString(_keyLastSeenVersion);
    return lastSeen != currentVersion;
  }

  /// Returns the current app version string.
  Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Mark the current version as seen so the screen won't show again
  /// until the next app update. No-op when [alwaysShow] is true.
  Future<void> markAsSeen() async {
    if (alwaysShow) return;
    final info = await PackageInfo.fromPlatform();
    await _prefs.setString(_keyLastSeenVersion, info.version);
  }
}
