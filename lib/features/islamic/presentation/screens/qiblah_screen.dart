import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/prayer_times_cache_service.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/di/injection_container.dart' as di;

class QiblahScreen extends StatefulWidget {
  const QiblahScreen({super.key});

  @override
  State<QiblahScreen> createState() => _QiblahScreenState();
}

class _QiblahScreenState extends State<QiblahScreen> {
  final LocationService _location = const LocationService();

  bool _loading = true;
  String? _error;
  double? _bearing;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
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
      final qibla = Qibla(coords);
      final bearing = qibla.direction;

      // Save location to local storage for future use
      await di.sl<SettingsService>().setLastKnownCoordinates(
        pos.latitude,
        pos.longitude,
      );

      // Cache prayer times for next 30 days (offline support)
      await di.sl<PrayerTimesCacheService>().cachePrayerTimes(
        pos.latitude,
        pos.longitude,
      );

      if (!mounted) return;
      setState(() {
        _loading = false;
        _lat = pos.latitude;
        _lng = pos.longitude;
        _bearing = bearing;
      });
    } catch (e) {
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
        title: Text(isArabicUi ? 'القبلة' : 'Qiblah'),
        centerTitle: true,
        actions: [
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
                  message: _arabicOrEnglish(
                    isArabicUi,
                    ar: 'تعذر الحصول على الموقع/القبلة: $_error',
                    en: 'Could not get location/Qiblah: $_error',
                  ),
                  onOpenSettings: () async {
                    await _location.openAppSettings();
                  },
                  onOpenLocation: () async {
                    await _location.openLocationSettings();
                  },
                )
              : _QiblahBody(
                  isArabicUi: isArabicUi,
                  bearing: _bearing ?? 0,
                  lat: _lat,
                  lng: _lng,
                ),
    );
  }

  String _arabicOrEnglish(bool isArabicUi, {required String ar, required String en}) {
    return isArabicUi ? ar : en;
  }
}

class _QiblahBody extends StatelessWidget {
  final bool isArabicUi;
  final double bearing;
  final double? lat;
  final double? lng;

  const _QiblahBody({
    required this.isArabicUi,
    required this.bearing,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    final bearingText = '${bearing.toStringAsFixed(1)}°';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            isArabicUi ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.explore, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabicUi ? 'اتجاه القبلة' : 'Qiblah Bearing',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isArabicUi
                              ? '$bearingText من الشمال الحقيقي'
                              : '$bearingText from true north',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (lat != null && lng != null)
            Text(
              isArabicUi
                  ? 'الموقع: ${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'
                  : 'Location: ${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: isArabicUi ? TextAlign.right : TextAlign.left,
            ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isArabicUi
                    ? 'ملاحظة: هذه الصفحة تعرض زاوية القبلة فقط. لإظهار سهم متحرك حسب اتجاه الهاتف، يمكن إضافة مستشعر البوصلة لاحقاً.'
                    : 'Note: This page shows the Qiblah bearing only. To show a live arrow aligned with your phone heading, we can add a compass sensor later.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: isArabicUi ? TextAlign.right : TextAlign.left,
              ),
            ),
          ),
        ],
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
          Text(
            message,
            textAlign: TextAlign.center,
          ),
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
