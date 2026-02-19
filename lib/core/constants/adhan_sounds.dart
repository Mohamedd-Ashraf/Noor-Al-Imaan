/// Describes a single selectable Adhan sound.
class AdhanSoundInfo {
  final String id; // matches Android res/raw file name (no extension)
  final String nameAr;
  final String nameEn;

  const AdhanSoundInfo({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });
}

/// All available Adhan sounds bundled in the app.
/// The [id] must match a file in `android/app/src/main/res/raw/`.
class AdhanSounds {
  static const String defaultId = 'adhan_1';

  static const List<AdhanSoundInfo> all = [
    AdhanSoundInfo(id: 'adhan_1',  nameAr: 'أذان ١', nameEn: 'Adhan 1'),
    AdhanSoundInfo(id: 'adhan_2',  nameAr: 'أذان ٢', nameEn: 'Adhan 2'),
    AdhanSoundInfo(id: 'adhan_3',  nameAr: 'أذان ٣', nameEn: 'Adhan 3'),
    AdhanSoundInfo(id: 'adhan_4',  nameAr: 'أذان ٤', nameEn: 'Adhan 4'),
    AdhanSoundInfo(id: 'adhan_5',  nameAr: 'أذان ٥', nameEn: 'Adhan 5'),
    AdhanSoundInfo(id: 'adhan_6',  nameAr: 'أذان ٦', nameEn: 'Adhan 6'),
    AdhanSoundInfo(id: 'adhan_7',  nameAr: 'أذان ٧', nameEn: 'Adhan 7'),
    AdhanSoundInfo(id: 'adhan_8',  nameAr: 'أذان ٨', nameEn: 'Adhan 8'),
    AdhanSoundInfo(id: 'adhan_9',  nameAr: 'أذان ٩', nameEn: 'Adhan 9'),
    AdhanSoundInfo(id: 'adhan_10', nameAr: 'أذان ١٠', nameEn: 'Adhan 10'),
  ];

  static AdhanSoundInfo findById(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
