import 'package:flutter/material.dart';
import 'adhkar_item.dart';

class AdhkarCategory {
  final String id;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final IconData icon;
  final Color color;
  final List<AdhkarItem> items;

  const AdhkarCategory({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.icon,
    required this.color,
    required this.items,
  });

  int get count => items.length;
}
