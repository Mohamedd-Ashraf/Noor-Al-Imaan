import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/prayer_times_cache_service.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/di/injection_container.dart' as di;

import '../../../../core/widgets/coming_soon_screen.dart';

class QiblahScreen extends StatelessWidget {
  const QiblahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      titleEn: 'Qiblah',
      titleAr: 'القبلة',
      icon: Icons.compass_calibration_rounded,
    );
  }
}
