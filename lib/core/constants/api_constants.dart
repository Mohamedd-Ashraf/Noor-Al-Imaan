class ApiConstants {
  static const String baseUrl = 'https://api.alquran.cloud/v1';
  
  // Endpoints
  static const String surahEndpoint = '/surah';
  static const String ayahEndpoint = '/ayah';
  static const String juzEndpoint = '/juz';
  static const String editionEndpoint = '/edition';
  static const String searchEndpoint = '/search';
  
  // Default edition
  static const String defaultEdition = 'quran-uthmani';
  static const String simpleEdition = 'quran-simple';
  static const String defaultTranslation = 'en.asad';

  // ─── Tafsir / Commentary editions ────────────────────────────────────────
  // Arabic tafsirs
  static const String tafsirMuyassar  = 'ar.muyassar';   // التفسير الميسر
  static const String tafsirJalalayn  = 'ar.jalalayn';   // تفسير الجلالين
  static const String tafsirWahidi    = 'ar.wahidi';     // أسباب النزول
  static const String tafsirQurtubi   = 'ar.qurtubi';    // تفسير القرطبي
  static const String tafsirMiqbas    = 'ar.miqbas';     // تنوير المقباس (ابن عباس)
  static const String tafsirWaseet    = 'ar.waseet';     // التفسير الوسيط
  static const String tafsirBaghawi   = 'ar.baghawi';    // تفسير البغوي

  // English translations / commentaries
  static const String tafsirAsad      = 'en.asad';       // Muhammad Asad
  static const String tafsirMaududi   = 'en.maududi';    // Maududi
  static const String tafsirPickthall = 'en.pickthall';  // Pickthall

  // Ordered list used by the Tafsir screen
  static const List<Map<String, String>> tafsirEditions = [
    {
      'id'      : tafsirMuyassar,
      'nameAr'  : 'الميسر',
      'nameEn'  : 'Al-Muyassar (AR)',
      'lang'    : 'ar',
    },
    {
      'id'      : tafsirJalalayn,
      'nameAr'  : 'الجلالين',
      'nameEn'  : 'Al-Jalalayn (AR)',
      'lang'    : 'ar',
    },
    {
      'id'      : tafsirQurtubi,
      'nameAr'  : 'القرطبي',
      'nameEn'  : 'Al-Qurtubi (AR)',
      'lang'    : 'ar',
    },
    {
      'id'      : tafsirBaghawi,
      'nameAr'  : 'البغوي',
      'nameEn'  : 'Al-Baghawi (AR)',
      'lang'    : 'ar',
    },
    {
      'id'      : tafsirWaseet,
      'nameAr'  : 'الوسيط',
      'nameEn'  : 'Al-Waseet (AR)',
      'lang'    : 'ar',
    },
    {
      'id'      : tafsirMiqbas,
      'nameAr'  : 'ابن عباس',
      'nameEn'  : 'Ibn Abbas (AR)',
      'lang'    : 'ar',
    },
    {
      'id'      : tafsirWahidi,
      'nameAr'  : 'أسباب النزول',
      'nameEn'  : 'Al-Wahidi (AR)',
      'lang'    : 'ar',
    },
    {
      'id'      : tafsirAsad,
      'nameAr'  : 'محمد أسد',
      'nameEn'  : 'Asad (EN)',
      'lang'    : 'en',
    },
    {
      'id'      : tafsirMaududi,
      'nameAr'  : 'المودودي',
      'nameEn'  : 'Maududi (EN)',
      'lang'    : 'en',
    },
    {
      'id'      : tafsirPickthall,
      'nameAr'  : 'بيكثال',
      'nameEn'  : 'Pickthall (EN)',
      'lang'    : 'en',
    },
  ];
}
