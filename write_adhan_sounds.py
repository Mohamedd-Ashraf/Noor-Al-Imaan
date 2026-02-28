"""Rewrites adhan_sounds.dart with confirmed real archive.org URLs."""
import pathlib

TARGET = pathlib.Path(r"e:\Quraan\quraan\lib\core\constants\adhan_sounds.dart")

CONTENT = r"""/// Describes a single selectable Adhan sound.
class AdhanSoundInfo {
  final String id;
  final String nameAr;
  final String nameEn;
  final String muezzinAr;
  final String muezzinEn;
  final String mosqueAr;
  final String mosqueEn;
  final bool isOnline;
  final String? url;

  const AdhanSoundInfo({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.muezzinAr = '',
    this.muezzinEn = '',
    this.mosqueAr = '',
    this.mosqueEn = '',
    this.isOnline = false,
    this.url,
  });
}

/// All available Adhan sounds.
///
/// Local [id]s must match files under android/app/src/main/res/raw/.
/// Online sounds are downloaded and cached to the app documents folder.
/// Online URLs are from archive.org / Public Domain (CC0 / Public Domain Mark 1.0).
class AdhanSounds {
  static const String defaultId = 'adhan_1';

  // ─── 10 local sounds bundled with the app ────────────────────────────────

  static const List<AdhanSoundInfo> local = [
    AdhanSoundInfo(
      id: 'adhan_1',
      nameAr: 'أذان المسجد الحرام',
      nameEn: 'Makkah Grand Mosque',
      muezzinAr: 'عبدالله الخشالات',
      muezzinEn: 'Abdullah Al-Khoshalat',
      mosqueAr: 'المسجد الحرام، مكة المكرمة',
      mosqueEn: 'Al-Masjid Al-Haram, Makkah',
    ),
    AdhanSoundInfo(
      id: 'adhan_2',
      nameAr: 'أذان المسجد النبوي',
      nameEn: 'Prophet\'s Mosque, Madinah',
      muezzinAr: 'علي أحمد مُلا',
      muezzinEn: 'Ali Ahmad Mulla',
      mosqueAr: 'المسجد النبوي، المدينة المنورة',
      mosqueEn: 'Al-Masjid An-Nabawi, Madinah',
    ),
    AdhanSoundInfo(
      id: 'adhan_3',
      nameAr: 'أذان مشاري العفاسي',
      nameEn: 'Mishary Rashid Al-Afasy',
      muezzinAr: 'مشاري راشد العفاسي',
      muezzinEn: 'Mishary Rashid Al-Afasy',
      mosqueAr: 'الكويت',
      mosqueEn: 'Kuwait',
    ),
    AdhanSoundInfo(
      id: 'adhan_4',
      nameAr: 'أذان الأزهر الشريف',
      nameEn: 'Al-Azhar Grand Mosque',
      muezzinAr: 'مؤذنو الأزهر',
      muezzinEn: 'Al-Azhar Muezzins',
      mosqueAr: 'الجامع الأزهر، القاهرة',
      mosqueEn: 'Al-Azhar Mosque, Cairo',
    ),
    AdhanSoundInfo(
      id: 'adhan_5',
      nameAr: 'أذان تركي كلاسيكي',
      nameEn: 'Turkish Classic Adhan',
      muezzinAr: 'مؤذن الديانة التركية',
      muezzinEn: 'Diyanet Official Muezzin',
      mosqueAr: 'إسطنبول، تركيا',
      mosqueEn: 'Istanbul, Turkey',
    ),
    AdhanSoundInfo(
      id: 'adhan_6',
      nameAr: 'أذان ماليزيا',
      nameEn: 'Malaysian Adhan',
      muezzinAr: 'مؤذن المسجد الوطني',
      muezzinEn: 'National Mosque Muezzin',
      mosqueAr: 'المسجد الوطني، كوالالمبور',
      mosqueEn: 'National Mosque, Kuala Lumpur',
    ),
    AdhanSoundInfo(
      id: 'adhan_7',
      nameAr: 'أذان مصر الكلاسيكي',
      nameEn: 'Egyptian Classic Adhan',
      muezzinAr: 'محمد رفعت',
      muezzinEn: 'Muhammad Rifaat',
      mosqueAr: 'القاهرة، مصر',
      mosqueEn: 'Cairo, Egypt',
    ),
    AdhanSoundInfo(
      id: 'adhan_8',
      nameAr: 'أذان العراق التقليدي',
      nameEn: 'Iraqi Traditional Adhan',
      muezzinAr: 'مؤذن الجامع الكبير',
      muezzinEn: 'Grand Mosque Muezzin',
      mosqueAr: 'بغداد، العراق',
      mosqueEn: 'Baghdad, Iraq',
    ),
    AdhanSoundInfo(
      id: 'adhan_9',
      nameAr: 'أذان المغرب الأندلسي',
      nameEn: 'Moroccan Andalusian Adhan',
      muezzinAr: 'مؤذن جامع القرويين',
      muezzinEn: 'Al-Qarawiyyin Mosque Muezzin',
      mosqueAr: 'جامع القرويين، فاس',
      mosqueEn: 'Al-Qarawiyyin Mosque, Fes',
    ),
    AdhanSoundInfo(
      id: 'adhan_10',
      nameAr: 'أذان باكستان',
      nameEn: 'Pakistani Adhan',
      muezzinAr: 'مؤذن المسجد البادشاهي',
      muezzinEn: 'Badshahi Mosque Muezzin',
      mosqueAr: 'المسجد البادشاهي، لاهور',
      mosqueEn: 'Badshahi Mosque, Lahore',
    ),
  ];

  // ─── 8 online sounds (streamed / cached) ─────────────────────────────────
  // Source: archive.org/details/adhan.notifications  (Public Domain Mark 1.0)
  // Confirmed real file names via archive.org metadata API.

  static const String _base =
      'https://archive.org/download/adhan.notifications/';

  static const List<AdhanSoundInfo> online = [
    AdhanSoundInfo(
      id: 'online_ahmed_imadi',
      nameAr: 'أذان أحمد العمادي',
      nameEn: 'Ahmed Al-Imadi Adhan',
      muezzinAr: 'أحمد العمادي',
      muezzinEn: 'Ahmed Al-Imadi',
      mosqueAr: 'قطر',
      mosqueEn: 'Qatar',
      isOnline: true,
      url: '${_base}Ahmed_al_Imadi_Adhan.mp3',
    ),
    AdhanSoundInfo(
      id: 'online_majed_hamathani',
      nameAr: 'أذان ماجد الحمثاني',
      nameEn: 'Majed Al-Hamathani Adhan',
      muezzinAr: 'ماجد الحمثاني',
      muezzinEn: 'Majed Al-Hamathani',
      mosqueAr: 'المملكة العربية السعودية',
      mosqueEn: 'Saudi Arabia',
      isOnline: true,
      url: '${_base}Majed_al_Hamathani_Adhan.mp3',
    ),
    AdhanSoundInfo(
      id: 'online_afasy_fajr',
      nameAr: 'أذان الفجر — مشاري العفاسي',
      nameEn: 'Fajr Adhan — Mishary Al-Afasy',
      muezzinAr: 'مشاري راشد العفاسي',
      muezzinEn: 'Mishary Rashid Al-Afasy',
      mosqueAr: 'الكويت',
      mosqueEn: 'Kuwait',
      isOnline: true,
      url: '${_base}Mishary_Rashid_al_Afasy_Fajr_Adhan.mp3',
    ),
    AdhanSoundInfo(
      id: 'online_mokhtar_slimane',
      nameAr: 'أذان مختار حاج سليمان',
      nameEn: 'Mokhtar Hadj Slimane Adhan',
      muezzinAr: 'مختار حاج سليمان',
      muezzinEn: 'Mokhtar Hadj Slimane',
      mosqueAr: 'الجزائر',
      mosqueEn: 'Algeria',
      isOnline: true,
      url: '${_base}Mokhtar_Hadj_Slimane_Adhan.mp3',
    ),
    AdhanSoundInfo(
      id: 'online_nasser_qatami',
      nameAr: 'أذان ناصر القطامي',
      nameEn: 'Nasser Al-Qatami Adhan',
      muezzinAr: 'ناصر القطامي',
      muezzinEn: 'Nasser Al-Qatami',
      mosqueAr: 'الكويت',
      mosqueEn: 'Kuwait',
      isOnline: true,
      url: '${_base}Nasser_al_Qatami_Adhan.mp3',
    ),
    AdhanSoundInfo(
      id: 'online_ahmed_imadi_dua',
      nameAr: 'أذان + دعاء — أحمد العمادي',
      nameEn: 'Adhan + Dua — Ahmed Al-Imadi',
      muezzinAr: 'أحمد العمادي',
      muezzinEn: 'Ahmed Al-Imadi',
      mosqueAr: 'قطر',
      mosqueEn: 'Qatar',
      isOnline: true,
      url: '${_base}Ahmed_al_Imadi_Adhan_with_Dua.mp3',
    ),
    AdhanSoundInfo(
      id: 'online_majed_hamathani_dua',
      nameAr: 'أذان + دعاء — ماجد الحمثاني',
      nameEn: 'Adhan + Dua — Majed Al-Hamathani',
      muezzinAr: 'ماجد الحمثاني',
      muezzinEn: 'Majed Al-Hamathani',
      mosqueAr: 'المملكة العربية السعودية',
      mosqueEn: 'Saudi Arabia',
      isOnline: true,
      url: '${_base}Majed_al_Hamathani_Adhan_with_Dua.mp3',
    ),
    AdhanSoundInfo(
      id: 'online_nasser_qatami_dua',
      nameAr: 'أذان + دعاء — ناصر القطامي',
      nameEn: 'Adhan + Dua — Nasser Al-Qatami',
      muezzinAr: 'ناصر القطامي',
      muezzinEn: 'Nasser Al-Qatami',
      mosqueAr: 'الكويت',
      mosqueEn: 'Kuwait',
      isOnline: true,
      url: '${_base}Nasser_al_Qatami_Adhan_with_Dua.mp3',
    ),
  ];

  static List<AdhanSoundInfo> get all => [...local, ...online];

  static AdhanSoundInfo findById(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => local.first);
}
"""

TARGET.write_text(CONTENT, encoding='utf-8')
print(f"Done — {TARGET.stat().st_size:,} bytes")
