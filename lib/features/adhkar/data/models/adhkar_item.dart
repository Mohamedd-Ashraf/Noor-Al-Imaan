class AdhkarItem {
  final String id;
  final String arabicText;
  final String translationEn;
  final String reference;
  final int repeatCount;
  final String? virtue; // fadl/benefit info in Arabic

  const AdhkarItem({
    required this.id,
    required this.arabicText,
    required this.translationEn,
    required this.reference,
    this.repeatCount = 1,
    this.virtue,
  });
}
