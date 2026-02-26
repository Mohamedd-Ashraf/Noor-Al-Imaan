import 'package:flutter/material.dart';

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
