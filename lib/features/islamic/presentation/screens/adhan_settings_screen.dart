import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/adhan_sounds.dart';
import '../../../../core/constants/prayer_calculation_constants.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/adhan_notification_service.dart';
import '../../../../core/settings/app_settings_cubit.dart';

class AdhanSettingsScreen extends StatefulWidget {
  const AdhanSettingsScreen({super.key});

  @override
  State<AdhanSettingsScreen> createState() => _AdhanSettingsScreenState();
}

class _AdhanSettingsScreenState extends State<AdhanSettingsScreen> {
  static const MethodChannel _adhanChannel = MethodChannel('quraan/adhan_player');

  late final SettingsService _settings;
  late final AdhanNotificationService _adhanService;

  String _selectedSoundId = AdhanSounds.defaultId;
  String _selectedMethodId = 'egyptian';
  String _selectedAsrMethod = 'standard';
  bool _notificationsEnabled = true;
  bool _includeFajr = true;
  bool _methodAutoDetected = true;

  bool _isPreviewPlaying = false;
  String? _previewingId;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _settings = di.sl<SettingsService>();
    _adhanService = di.sl<AdhanNotificationService>();
    _load();
  }

  void _load() {
    setState(() {
      _selectedSoundId = _settings.getSelectedAdhanSound();
      _selectedMethodId = _settings.getPrayerCalculationMethod();
      _selectedAsrMethod = _settings.getPrayerAsrMethod();
      _notificationsEnabled = _settings.getAdhanNotificationsEnabled();
      _includeFajr = _settings.getAdhanIncludeFajr();
      _methodAutoDetected = _settings.getPrayerMethodAutoDetected();
    });
  }

  @override
  void dispose() {
    _stopPreview();
    super.dispose();
  }

  Future<void> _previewSound(String soundId) async {
    if (_isPreviewPlaying) {
      await _stopPreview();
      if (_previewingId == soundId) return;
    }

    setState(() {
      _isPreviewPlaying = true;
      _previewingId = soundId;
    });

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _adhanChannel.invokeMethod('playAdhan', {'soundName': soundId});
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _previewingId == soundId) {
            setState(() {
              _isPreviewPlaying = false;
              _previewingId = null;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Preview error: $e');
      if (mounted) {
        setState(() {
          _isPreviewPlaying = false;
          _previewingId = null;
        });
      }
    }
  }

  Future<void> _stopPreview() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _adhanChannel.invokeMethod('stopAdhan');
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isPreviewPlaying = false;
        _previewingId = null;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await _settings.setSelectedAdhanSound(_selectedSoundId);
    await _settings.setPrayerCalculationMethod(_selectedMethodId);
    await _settings.setPrayerAsrMethod(_selectedAsrMethod);
    await _settings.setAdhanIncludeFajr(_includeFajr);
    await _settings.setPrayerMethodAutoDetected(_methodAutoDetected);

    if (_notificationsEnabled) {
      await _adhanService.enableAndSchedule();
    } else {
      await _adhanService.disable();
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isAr ? 'تم الحفظ بنجاح ✓' : 'Settings saved ✓'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  bool get _isAr {
    try {
      return context
          .read<AppSettingsCubit>()
          .state
          .appLanguageCode
          .toLowerCase()
          .startsWith('ar');
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _isAr;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إعدادات الأذان والصلاة' : 'Adhan & Prayer Settings'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gradientStart,
                AppColors.gradientMid,
                AppColors.gradientEnd,
              ],
            ),
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_rounded),
              tooltip: isAr ? 'حفظ' : 'Save',
              onPressed: _save,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Notifications ──────────────────────────────────────
          _SectionHeader(title: isAr ? 'إشعارات الأذان' : 'Adhan Notifications'),
          _SettingsTile(
            leading: Icon(
              _notificationsEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: _notificationsEnabled ? AppColors.primary : Colors.grey,
            ),
            title: isAr ? 'تفعيل إشعارات الأذان' : 'Enable Adhan Notifications',
            subtitle: isAr
                ? 'سيتم تشغيل الأذان عند كل وقت صلاة'
                : 'Play Adhan at each prayer time',
            trailing: Switch.adaptive(
              value: _notificationsEnabled,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
          ),
          _SettingsTile(
            leading: Icon(
              Icons.wb_twilight_rounded,
              color: _includeFajr ? AppColors.primary : Colors.grey,
            ),
            title: isAr ? 'تضمين أذان الفجر' : 'Include Fajr Adhan',
            subtitle: isAr
                ? 'يختلف أذان الفجر — قد تريد تعطيله في الليالي'
                : 'Fajr Adhan differs — you may want to disable it at night',
            trailing: Switch.adaptive(
              value: _includeFajr,
              activeColor: AppColors.primary,
              onChanged: _notificationsEnabled
                  ? (v) => setState(() => _includeFajr = v)
                  : null,
            ),
          ),

          const SizedBox(height: 8),

          // ── Sound Selector ─────────────────────────────────────
          _SectionHeader(title: isAr ? 'صوت الأذان' : 'Adhan Sound'),
          Card(
            child: Column(
              children: AdhanSounds.all
                  .map((sound) => _SoundTile(
                        sound: sound,
                        isSelected: _selectedSoundId == sound.id,
                        isPreviewing: _previewingId == sound.id,
                        isAr: isAr,
                        onSelect: () => setState(() => _selectedSoundId = sound.id),
                        onPreview: () => _previewSound(sound.id),
                        onStop: _stopPreview,
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),

          // ── Prayer Calculation Method ──────────────────────────
          _SectionHeader(
            title: isAr ? 'طريقة حساب مواقيت الصلاة' : 'Prayer Calculation Method',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    value: _methodAutoDetected,
                    title: Text(
                      isAr
                          ? 'تحديد الطريقة تلقائياً حسب الموقع'
                          : 'Auto-detect method from location',
                      style: const TextStyle(fontSize: 14),
                    ),
                    onChanged: (v) => setState(() => _methodAutoDetected = v),
                  ),
                  const Divider(height: 0),
                  const SizedBox(height: 8),
                  Text(
                    isAr ? 'أو اختر يدوياً:' : 'Or select manually:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...PrayerCalculationConstants.calculationMethods.entries.map(
                    (entry) {
                      final id = entry.key;
                      final info = entry.value;
                      final isEgyptian = id == 'egyptian';
                      return RadioListTile<String>(
                        value: id,
                        groupValue: _selectedMethodId,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          isAr ? info.nameAr : info.nameEn,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isEgyptian
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: isEgyptian
                            ? Text(
                                isAr ? '(الافتراضي)' : '(Default)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                        onChanged: _methodAutoDetected
                            ? null
                            : (v) {
                                if (v != null) {
                                  setState(() => _selectedMethodId = v);
                                }
                              },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Asr Method ─────────────────────────────────────────
          _SectionHeader(title: isAr ? 'حساب العصر' : 'Asr Calculation'),
          Card(
            child: Column(
              children: PrayerCalculationConstants.asrMethods.entries
                  .map((entry) => RadioListTile<String>(
                        value: entry.key,
                        groupValue: _selectedAsrMethod,
                        activeColor: AppColors.primary,
                        title: Text(
                          isAr ? entry.value.nameAr : entry.value.nameEn,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          isAr
                              ? entry.value.descriptionAr
                              : entry.value.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedAsrMethod = v);
                        },
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 24),

          // ── Save Button ────────────────────────────────────────
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, color: Colors.white),
            label: Text(
              isAr ? 'حفظ الإعدادات' : 'Save Settings',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: leading,
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: trailing,
      ),
    );
  }
}

class _SoundTile extends StatelessWidget {
  final AdhanSoundInfo sound;
  final bool isSelected;
  final bool isPreviewing;
  final bool isAr;
  final VoidCallback onSelect;
  final VoidCallback onPreview;
  final VoidCallback onStop;

  const _SoundTile({
    required this.sound,
    required this.isSelected,
    required this.isPreviewing,
    required this.isAr,
    required this.onSelect,
    required this.onPreview,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Radio<String>(
        value: sound.id,
        groupValue: isSelected ? sound.id : '',
        activeColor: AppColors.primary,
        onChanged: (_) => onSelect(),
      ),
      title: Text(
        isAr ? sound.nameAr : sound.nameEn,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      trailing: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isPreviewing
              ? const Icon(Icons.stop_circle_rounded,
                  key: ValueKey('stop'), color: Colors.red)
              : const Icon(Icons.play_circle_rounded,
                  key: ValueKey('play'), color: AppColors.primary),
        ),
        tooltip: isPreviewing
            ? (isAr ? 'إيقاف' : 'Stop')
            : (isAr ? 'استماع' : 'Preview'),
        onPressed: isPreviewing ? onStop : onPreview,
      ),
      onTap: onSelect,
    );
  }
}
