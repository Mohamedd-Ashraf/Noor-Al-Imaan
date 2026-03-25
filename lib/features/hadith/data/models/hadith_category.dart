import 'package:flutter/material.dart';
import 'hadith_item.dart';

class HadithCategory {
  final String id;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final IconData icon;
  final Color color;
  final List<HadithItem> items;

  const HadithCategory({
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
