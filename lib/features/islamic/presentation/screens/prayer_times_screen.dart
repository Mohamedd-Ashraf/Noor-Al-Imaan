import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/prayer_calculation_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/prayer_times_cache_service.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'adhan_settings_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final LocationService _location = const LocationService();

  bool _loading = true;
  String? _error;

  PrayerTimes? _prayerTimes;
  Coordinates? _coordinates;
  String _calcMethodId = 'egyptian';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _prayerTimes = null;
      _coordinates = null;
    });

    final permission = await _location.ensurePermission();
    if (!mounted) return;

    if (permission != LocationPermissionState.granted) {
      setState(() {
        _loading = false;
        _error = _permissionError(permission);
      });
      return;
    }

    try {
      final pos = await _location.getPosition();
      final coords = Coordinates(pos.latitude, pos.longitude);
      final settings = di.sl<SettingsService>();

      // Save location to local storage for future use
      await settings.setLastKnownCoordinates(pos.latitude, pos.longitude);

      // Cache prayer times for next 30 days (offline support)
      await di.sl<PrayerTimesCacheService>().cachePrayerTimes(
        pos.latitude,
        pos.longitude,
      );

      // Auto-detect calculation method if user hasn't manually overridden it
      if (settings.getPrayerMethodAutoDetected()) {
        final autoMethod = PrayerCalculationConstants.methodFromCoordinates(
          pos.latitude, pos.longitude,
        );
        await settings.setPrayerCalculationMethod(autoMethod);
      }

      final calcMethod = settings.getPrayerCalculationMethod();
      final asrMethod = settings.getPrayerAsrMethod();
      final params = PrayerCalculationConstants.getCompleteParameters(
        calculationMethod: calcMethod,
        asrMethod: asrMethod,
      );

      final now = DateTime.now();
      final prayerTimes = PrayerTimes(
        coords,
        DateComponents(now.year, now.month, now.day),
        params,
      );

      if (!mounted) return;
      setState(() {
        _loading = false;
        _coordinates = coords;
        _prayerTimes = prayerTimes;
        _calcMethodId = calcMethod;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is TimeoutException
            ? 'Timed out getting GPS fix. Try again or move to an open area.'
            : e.toString();
      });
    }
  }

  String _permissionError(LocationPermissionState state) {
    switch (state) {
      case LocationPermissionState.serviceDisabled:
        return 'Location services are disabled.';
      case LocationPermissionState.denied:
        return 'Location permission denied.';
      case LocationPermissionState.deniedForever:
        return 'Location permission permanently denied.';
      case LocationPermissionState.granted:
        return '';
    }
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final local = dt.toLocal();
    final tod = TimeOfDay.fromDateTime(local);
    return MaterialLocalizations.of(context).formatTimeOfDay(
      tod,
      alwaysUse24HourFormat: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabicUi = context
        .watch<AppSettingsCubit>()
        .state
        .appLanguageCode
        .toLowerCase()
        .startsWith('ar');

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabicUi ? 'مواقيت الصلاة' : 'Prayer Times'),
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
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdhanSettingsScreen(),
                ),
              );
              // Reload after returning from settings (method may have changed)
              _load();
            },
            icon: const Icon(Icons.settings_rounded),
            tooltip: isArabicUi ? 'إعدادات الأذان' : 'Adhan Settings',
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(
                  isArabicUi: isArabicUi,
                  message: isArabicUi
                      ? 'تعذر الحصول على الموقع/المواقيت: $_error'
                      : 'Could not get location/prayer times: $_error',
                  onOpenSettings: () async {
                    await _location.openAppSettings();
                  },
                  onOpenLocation: () async {
                    await _location.openLocationSettings();
                  },
                )
              : _PrayerTimesBody(
                  isArabicUi: isArabicUi,
                  prayerTimes: _prayerTimes!,
                  coordinates: _coordinates!,
                  calcMethodId: _calcMethodId,
                  formatTime: (dt) => _formatTime(context, dt),
                ),
    );
  }
}

class _PrayerTimesBody extends StatelessWidget {
  final bool isArabicUi;
  final PrayerTimes prayerTimes;
  final Coordinates coordinates;
  final String calcMethodId;
  final String Function(DateTime) formatTime;

  const _PrayerTimesBody({
    required this.isArabicUi,
    required this.prayerTimes,
    required this.coordinates,
    required this.calcMethodId,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          isArabicUi
              ? 'الموقع: ${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}'
              : 'Location: ${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
          textAlign: isArabicUi ? TextAlign.right : TextAlign.left,
        ),
        const SizedBox(height: 12),
        _PrayerTile(
          title: isArabicUi ? 'الفجر' : 'Fajr',
          time: formatTime(prayerTimes.fajr),
        ),
        _PrayerTile(
          title: isArabicUi ? 'الشروق' : 'Sunrise',
          time: formatTime(prayerTimes.sunrise),
        ),
        _PrayerTile(
          title: isArabicUi ? 'الظهر' : 'Dhuhr',
          time: formatTime(prayerTimes.dhuhr),
        ),
        _PrayerTile(
          title: isArabicUi ? 'العصر' : 'Asr',
          time: formatTime(prayerTimes.asr),
        ),
        _PrayerTile(
          title: isArabicUi ? 'المغرب' : 'Maghrib',
          time: formatTime(prayerTimes.maghrib),
        ),
        _PrayerTile(
          title: isArabicUi ? 'العشاء' : 'Isha',
          time: formatTime(prayerTimes.isha),
        ),
        const SizedBox(height: 12),
        Builder(builder: (context) {
          final methodInfo =
              PrayerCalculationConstants.calculationMethods[calcMethodId];
          final methodLabel = methodInfo == null
              ? calcMethodId
              : (isArabicUi ? methodInfo.nameAr : methodInfo.nameEn);
          return Card(
            child: ListTile(
              leading: const Icon(Icons.calculate_rounded, color: AppColors.primary),
              title: Text(
                isArabicUi ? 'طريقة الحساب' : 'Calculation Method',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                methodLabel,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _PrayerTile extends StatelessWidget {
  final String title;
  final String time;

  const _PrayerTile({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 3,
      shadowColor: AppColors.primary.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.secondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.03),
              AppColors.secondary.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.access_time_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              time,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final bool isArabicUi;
  final String message;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLocation;

  const _ErrorState({
    required this.isArabicUi,
    required this.message,
    required this.onOpenSettings,
    required this.onOpenLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: onOpenLocation,
                child: Text(isArabicUi ? 'إعدادات الموقع' : 'Location Settings'),
              ),
              OutlinedButton(
                onPressed: onOpenSettings,
                child: Text(isArabicUi ? 'إعدادات التطبيق' : 'App Settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
