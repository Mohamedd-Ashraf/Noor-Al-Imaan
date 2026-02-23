import 'package:flutter/material.dart';
import 'models/adhkar_category.dart';
import 'models/adhkar_item.dart';

class AdhkarData {
  static List<AdhkarCategory> get categories => [
        _morningAdhkar,
        _eveningAdhkar,
        _afterPrayerAdhkar,
        _sleepAdhkar,
        _wakeUpAdhkar,
        _quranicDuas,
        _eatingDrinkingAdhkar,
        _homeMosqueAdhkar,
        _miscDuas,
      ];

  // ─── أذكار الصباح ─────────────────────────────────────────────────
  static AdhkarCategory get _morningAdhkar => AdhkarCategory(
        id: 'morning',
        titleAr: 'أذكار الصباح',
        titleEn: 'Morning Adhkar',
        subtitleAr: 'من الفجر حتى الضحى',
        subtitleEn: 'From Fajr until mid-morning',
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFFD4AF37),
        items: [
          const AdhkarItem(
            id: 'morning_1',
            arabicText: 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ\n'
                'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ '
                'لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ '
                'يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ '
                'وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
            translationEn:
                'Allah – there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who could intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great. (Ayat al-Kursi)',
            reference: 'البقرة: 255',
            repeatCount: 1,
            virtue:
                'من قالها حين يصبح أُجير من الجن حتى يمسي، ومن قالها حين يمسي أُجير من الجن حتى يصبح',
          ),
          const AdhkarItem(
            id: 'morning_2',
            arabicText:
                'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
            translationEn:
                'Say: He is Allah, the One. Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent. (Surat Al-Ikhlas)',
            reference: 'سورة الإخلاص – قراءة ثلاث مرات',
            repeatCount: 3,
            virtue: 'من قالهن ثلاثاً حين يصبح وحين يمسي كفته من كل شيء',
          ),
          const AdhkarItem(
            id: 'morning_3',
            arabicText:
                'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
            translationEn:
                'Say: I seek refuge in the Lord of daybreak, from the evil of that which He created, and from the evil of darkness when it settles, and from the evil of the blowers in knots, and from the evil of an envier when he envies. (Surat Al-Falaq)',
            reference: 'سورة الفلق – قراءة ثلاث مرات',
            repeatCount: 3,
          ),
          const AdhkarItem(
            id: 'morning_4',
            arabicText:
                'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ',
            translationEn:
                'Say: I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the whisperer who withdraws, who whispers in the breasts of mankind, among jinn and among people. (Surat An-Nas)',
            reference: 'سورة الناس – قراءة ثلاث مرات',
            repeatCount: 3,
          ),
          const AdhkarItem(
            id: 'morning_5',
            arabicText:
                'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
            translationEn:
                'We have reached the morning and at this very time all sovereignty belongs to Allah. Praise is to Allah. None has the right to be worshipped except Allah, alone, without partner; to Him belongs all sovereignty and praise and He is over all things omnipotent. My Lord, I ask You for the good of this day and the good of what follows it, and I seek refuge in You from the evil of this day and the evil of what follows it. My Lord, I seek refuge in You from laziness and the evil of old age. My Lord, I seek refuge in You from torment in the Fire and torment in the grave.',
            reference: 'مسلم 2723',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'morning_6',
            arabicText:
                'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ',
            translationEn:
                'O Allah, by Your leave we have reached the morning and by Your leave we reach the evening, by Your leave we live and die and unto You is our resurrection.',
            reference: 'أبو داود 5068، الترمذي 3391',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'morning_7',
            arabicText:
                'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
            translationEn:
                'O Allah, You are my Lord, none has the right to be worshipped except You. You created me and I am Your servant, and I abide to Your covenant and promise as best I can. I take refuge in You from the evil of which I have committed. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for verily none can forgive sins except You.',
            reference: 'البخاري 6306 – سيد الاستغفار',
            repeatCount: 1,
            virtue:
                'من قالها موقناً بها فمات من يومه دخل الجنة، وكذلك من قالها من الليل',
          ),
          const AdhkarItem(
            id: 'morning_8',
            arabicText:
                'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَٰهَ إِلَّا أَنْتَ',
            translationEn:
                'O Allah, grant my body health, O Allah, grant my hearing health, O Allah, grant my sight health. None has the right to be worshipped except You.',
            reference: 'أبو داود 5090',
            repeatCount: 3,
          ),
          const AdhkarItem(
            id: 'morning_9',
            arabicText:
                'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي',
            translationEn:
                'O Allah, I ask You for pardon and well-being in this life and the next. O Allah, I ask You for pardon and well-being in my religious and worldly affairs, and my family and my wealth. O Allah, conceal my faults and calm my fears.',
            reference: 'ابن ماجه 3871',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'morning_10',
            arabicText:
                'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ',
            translationEn:
                'O Allah, I take refuge in You from anxiety and sorrow, weakness and laziness, miserliness and cowardice, the burden of debts and from being oppressed by men.',
            reference: 'البخاري 6369',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'morning_11',
            arabicText:
                'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
            translationEn:
                'How perfect Allah is and I praise Him.',
            reference: 'مسلم 2692',
            repeatCount: 100,
            virtue:
                'من قالها مئة مرة غُفرت ذنوبه وإن كانت مثل زبد البحر',
          ),
          const AdhkarItem(
            id: 'morning_12',
            arabicText:
                'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
            translationEn:
                'None has the right to be worshipped except Allah, alone, without partner, to Him belongs all sovereignty and praise and He is over all things omnipotent.',
            reference: 'البخاري 3293',
            repeatCount: 10,
            virtue:
                'من قالها عشر مرات حين يصبح كانت له كعِدل أربع رقاب',
          ),
          const AdhkarItem(
            id: 'morning_13',
            arabicText:
                'رَضِيتُ بِاللَّهِ رَبًّا وَبِالْإِسْلَامِ دِينًا وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
            translationEn:
                'I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad (peace be upon him) as my prophet.',
            reference: 'أبو داود 5072',
            repeatCount: 3,
            virtue: 'كان حقاً على الله أن يرضيه يوم القيامة',
          ),
          const AdhkarItem(
            id: 'morning_14',
            arabicText:
                'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ، عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
            translationEn:
                'Allah is sufficient for me; none has the right to be worshipped except Him. Upon Him I rely and He is Lord of the Magnificent Throne.',
            reference: 'أبو داود 5081',
            repeatCount: 7,
            virtue: 'كفاه الله ما أهمه من أمر الدنيا والآخرة',
          ),
        ],
      );

  // ─── أذكار المساء ─────────────────────────────────────────────────
  static AdhkarCategory get _eveningAdhkar => AdhkarCategory(
        id: 'evening',
        titleAr: 'أذكار المساء',
        titleEn: 'Evening Adhkar',
        subtitleAr: 'من العصر حتى المغرب',
        subtitleEn: 'From Asr until Maghrib',
        icon: Icons.nights_stay_rounded,
        color: const Color(0xFF3F51B5),
        items: [
          const AdhkarItem(
            id: 'evening_1',
            arabicText:
                'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ '
                'لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ '
                'يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ '
                'وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
            translationEn:
                'Allah – there is no deity except Him, the Ever-Living, the Sustainer of existence. (Ayat al-Kursi)',
            reference: 'البقرة: 255',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'evening_2',
            arabicText:
                'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
            translationEn:
                'We have reached the evening and at this very time all sovereignty belongs to Allah. My Lord, I ask You for the good of this night and the good of what follows it, and I seek refuge in You from the evil of this night and evil of what follows it. My Lord, I seek refuge in You from laziness and the evil of old age. My Lord, I seek refuge from torment in the Fire and torment in the grave.',
            reference: 'مسلم 2723',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'evening_3',
            arabicText:
                'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ',
            translationEn:
                'O Allah, by Your leave we have reached the evening and by Your leave we reach the morning; by Your leave we live and die and unto You is our return.',
            reference: 'أبو داود 5068، الترمذي 3391',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'evening_4',
            arabicText:
                'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
            translationEn:
                'O Allah, You are my Lord, none has the right to be worshipped except You. You created me and I am Your servant, and I abide to Your covenant and promise as best I can. I take refuge in You from the evil of what I have committed. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for verily none can forgive sins except You. (Sayyid Al-Istighfar)',
            reference: 'البخاري 6306',
            repeatCount: 1,
            virtue:
                'من قالها موقناً بها فمات من ليلته دخل الجنة',
          ),
          const AdhkarItem(
            id: 'evening_5',
            arabicText:
                'اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ وَأُشْهِدُ حَمَلَةَ عَرْشِكَ وَمَلَائِكَتَكَ وَجَمِيعَ خَلْقِكَ أَنَّكَ أَنْتَ اللَّهُ لَا إِلَٰهَ إِلَّا أَنْتَ وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ',
            translationEn:
                'O Allah, I have reached the evening and call on You, the bearers of Your throne, Your angels, and all Your creation to witness that You are Allah, none has the right to be worshipped except You, and that Muhammad is Your servant and messenger.',
            reference: 'أبو داود 5069',
            repeatCount: 4,
            virtue: 'أعتق الله ربعه من النار عن كل قائل',
          ),
          const AdhkarItem(
            id: 'evening_6',
            arabicText:
                'اللَّهُمَّ مَا أَمْسَى بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ',
            translationEn:
                'O Allah, what blessing I or any of Your creation have reached the evening with, is from You alone. You have no partner. All praise and thanks are for You.',
            reference: 'أبو داود 5073',
            repeatCount: 1,
            virtue: 'أدّى شُكر يومه',
          ),
          const AdhkarItem(
            id: 'evening_7',
            arabicText:
                'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَٰهَ إِلَّا أَنْتَ',
            translationEn:
                'O Allah, grant my body health. O Allah, grant my hearing health. O Allah, grant my sight health. None has the right to be worshipped except You.',
            reference: 'أبو داود 5090',
            repeatCount: 3,
          ),
          const AdhkarItem(
            id: 'evening_8',
            arabicText:
                'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
            translationEn:
                'I take refuge in the perfect words of Allah from the evil of what He has created.',
            reference: 'مسلم 2709',
            repeatCount: 3,
            virtue: 'لم تضره حُمة تلك الليلة',
          ),
          const AdhkarItem(
            id: 'evening_9',
            arabicText:
                'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
            translationEn:
                'In the name of Allah with whose name nothing is harmed on earth or in the heavens, and He is the All-Hearing, the All-Knowing.',
            reference: 'أبو داود 5088',
            repeatCount: 3,
            virtue: 'لم تصبه فجأة بلاء',
          ),
          const AdhkarItem(
            id: 'evening_10',
            arabicText:
                'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
            translationEn:
                'How perfect Allah is and I praise Him.',
            reference: 'مسلم 2692',
            repeatCount: 100,
            virtue: 'من قالها مئة مرة غُفرت ذنوبه وإن كانت مثل زبد البحر',
          ),
        ],
      );

  // ─── أذكار بعد الصلاة ─────────────────────────────────────────────
  static AdhkarCategory get _afterPrayerAdhkar => AdhkarCategory(
        id: 'after_prayer',
        titleAr: 'أذكار بعد الصلاة',
        titleEn: 'After Prayer',
        subtitleAr: 'بعد كل صلاة مكتوبة',
        subtitleEn: 'After each obligatory prayer',
        icon: Icons.mosque_rounded,
        color: const Color(0xFF0D5E3A),
        items: [
          const AdhkarItem(
            id: 'after_1',
            arabicText: 'أَسْتَغْفِرُ اللَّهَ',
            translationEn: 'I seek forgiveness from Allah.',
            reference: 'مسلم 591',
            repeatCount: 3,
          ),
          const AdhkarItem(
            id: 'after_2',
            arabicText:
                'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
            translationEn:
                'O Allah, You are As-Salam (Peace) and from You is peace. Blessed are You, O Owner of Majesty and Honour.',
            reference: 'مسلم 591',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'after_3',
            arabicText:
                'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ وَلَا مُعْطِيَ لِمَا مَنَعْتَ وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ',
            translationEn:
                'None has the right to be worshipped except Allah, alone without partner. To Him belongs all sovereignty and praise and He is over all things omnipotent. O Allah, none can withhold what You give, and none can give what You withhold, and no wealth or majesty can benefit anyone, as from You is all wealth and majesty.',
            reference: 'البخاري 844',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'after_4',
            arabicText:
                'سُبْحَانَ اللَّهِ',
            translationEn: 'How perfect Allah is.',
            reference: 'مسلم 595',
            repeatCount: 33,
          ),
          const AdhkarItem(
            id: 'after_5',
            arabicText: 'الْحَمْدُ لِلَّهِ',
            translationEn: 'Praise is to Allah.',
            reference: 'مسلم 595',
            repeatCount: 33,
          ),
          const AdhkarItem(
            id: 'after_6',
            arabicText: 'اللَّهُ أَكْبَرُ',
            translationEn: 'Allah is the greatest.',
            reference: 'مسلم 595',
            repeatCount: 33,
          ),
          const AdhkarItem(
            id: 'after_7',
            arabicText:
                'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
            translationEn:
                'None has the right to be worshipped except Allah, alone without partner. To Him belongs all sovereignty and praise, and He is over all things omnipotent.',
            reference: 'مسلم 597',
            repeatCount: 1,
            virtue: 'غُفرت له خطاياه وإن كانت مثل زبد البحر',
          ),
          const AdhkarItem(
            id: 'after_8',
            arabicText:
                'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
            translationEn:
                'Allah! There is no god ˹worthy of worship˺ except Him, the Ever-Living, All-Sustaining. (Ayat al-Kursi)',
            reference: 'النسائي 1336 – من قرأها دبر كل صلاة لم يمنعه من دخول الجنة إلا أن يموت',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'after_9',
            arabicText:
                'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
            translationEn:
                'O Allah, help me to remember You, to give thanks to You, and to worship You in an excellent manner.',
            reference: 'أبو داود 1522',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'after_10',
            arabicText:
                'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا',
            translationEn:
                'O Allah, I ask You for knowledge that is of benefit, a good provision and deeds that will be accepted.',
            reference: 'ابن ماجه 925 – بعد صلاة الفجر',
            repeatCount: 1,
          ),
        ],
      );

  // ─── أذكار النوم ──────────────────────────────────────────────────
  static AdhkarCategory get _sleepAdhkar => AdhkarCategory(
        id: 'sleep',
        titleAr: 'أذكار النوم',
        titleEn: 'Sleep Adhkar',
        subtitleAr: 'قبل النوم',
        subtitleEn: 'Before going to sleep',
        icon: Icons.bedtime_rounded,
        color: const Color(0xFF512DA8),
        items: [
          const AdhkarItem(
            id: 'sleep_1',
            arabicText:
                'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
            translationEn:
                'In Your name, O Allah, I die and I live.',
            reference: 'البخاري 6324',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'sleep_2',
            arabicText:
                'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
            translationEn:
                'O Allah, protect me from Your punishment on the Day You resurrect Your servants.',
            reference: 'أبو داود 5045',
            repeatCount: 3,
          ),
          const AdhkarItem(
            id: 'sleep_3',
            arabicText:
                'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي وَبِكَ أَرْفَعُهُ، إِنْ أَمْسَكْتَ نَفْسِي فَاغْفِرْ لَهَا وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ',
            translationEn:
                'In Your name my Lord, I lie down and in Your name I rise, so if You should take my soul then have mercy upon it, and if You should return my soul then protect it as You protect Your righteous servants.',
            reference: 'البخاري 6320',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'sleep_4',
            arabicText:
                'اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ وَفَوَّضْتُ أَمْرِي إِلَيْكَ وَوَجَّهْتُ وَجْهِيَ إِلَيْكَ وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ رَغْبَةً وَرَهْبَةً إِلَيْكَ لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ',
            translationEn:
                'O Allah, I submit my soul unto You and I entrust my affair unto You and I turn my face towards You, and I totally rely on You, in hope and fear of You. There is no fleeing from You, and there is no place of protection and safety except with You. I believe in Your Book which You have revealed and in Your Prophet whom You have sent.',
            reference: 'البخاري 247',
            repeatCount: 1,
            virtue: 'من قالها فمات تلك الليلة مات على الفطرة',
          ),
          const AdhkarItem(
            id: 'sleep_5',
            arabicText:
                'سُبْحَانَ اللَّهِ',
            translationEn: 'How perfect Allah is.',
            reference: 'البخاري 3113 – تسبيح فاطمة رضي الله عنها',
            repeatCount: 33,
            virtue: 'خيرٌ لك مما سألت',
          ),
          const AdhkarItem(
            id: 'sleep_6',
            arabicText: 'الْحَمْدُ لِلَّهِ',
            translationEn: 'All praise is for Allah.',
            reference: 'البخاري 3113',
            repeatCount: 33,
          ),
          const AdhkarItem(
            id: 'sleep_7',
            arabicText: 'اللَّهُ أَكْبَرُ',
            translationEn: 'Allah is the greatest.',
            reference: 'البخاري 3113',
            repeatCount: 34,
          ),
          const AdhkarItem(
            id: 'sleep_8',
            arabicText:
                'اللَّهُمَّ رَبَّ السَّمَوَاتِ وَرَبَّ الْأَرْضِ وَرَبَّ الْعَرْشِ الْعَظِيمِ رَبَّنَا وَرَبَّ كُلِّ شَيْءٍ، فَالِقَ الْحَبِّ وَالنَّوَى وَمُنْزِلَ التَّوْرَاةِ وَالْإِنْجِيلِ وَالْقُرْآنِ، أَعُوذُ بِكَ مِنْ شَرِّ كُلِّ شَيْءٍ أَنْتَ آخِذٌ بِنَاصِيَتِهِ، اللَّهُمَّ أَنْتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ وَأَنْتَ الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ وَأَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ، اقْضِ عَنَّا الدَّيْنَ وَأَغْنِنَا مِنَ الْفَقْرِ',
            translationEn:
                'O Allah, Lord of the heavens and Lord of the earth and Lord of the Magnificent Throne. Our Lord and Lord of all things. Splitter of the grain and seed. Revealer of the Torah, the Gospel and the Quran. I take refuge in You from the evil of all things You shall seize by the forlock. O Allah, You are Al-Awwal (the First) and nothing is before You; You are Al-Akhir (the Last) and nothing is after You; You are Az-Zahir (the One above all) and nothing is above You; You are Al-Batin (the Hidden) and nothing is beyond You. Settle our debt for us and spare us from poverty.',
            reference: 'مسلم 2713',
            repeatCount: 1,
          ),
        ],
      );

  // ─── أذكار الاستيقاظ ──────────────────────────────────────────────
  static AdhkarCategory get _wakeUpAdhkar => AdhkarCategory(
        id: 'wakeup',
        titleAr: 'أذكار الاستيقاظ',
        titleEn: 'Waking Up',
        subtitleAr: 'عند الاستيقاظ من النوم',
        subtitleEn: 'Upon waking from sleep',
        icon: Icons.light_mode_rounded,
        color: const Color(0xFFE65100),
        items: [
          const AdhkarItem(
            id: 'wakeup_1',
            arabicText:
                'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
            translationEn:
                'All praise is for Allah who gave us life after having taken it from us, and unto Him is the resurrection.',
            reference: 'البخاري 6312',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'wakeup_2',
            arabicText:
                'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَٰهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
            translationEn:
                'None has the right to be worshipped except Allah, alone without partner. To Him belongs all sovereignty and praise, and He is over all things omnipotent. Glory is to Allah, praise is to Allah, none has the right to be worshipped except Allah, Allah is the greatest, there is no might and no power except by Allah the Exalted, the Magnificent.',
            reference: 'البخاري 1154',
            repeatCount: 1,
            virtue: 'غُفرت له ذنوبه ولو كانت مثل زبد البحر',
          ),
          const AdhkarItem(
            id: 'wakeup_3',
            arabicText:
                'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذَا الْيَوْمِ فَتْحَهُ وَنَصْرَهُ وَنُورَهُ وَبَرَكَتَهُ وَهُدَاهُ وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهِ وَشَرِّ مَا بَعْدَهُ',
            translationEn:
                'O Allah, I ask You for the goodness of this day, its openings, its victories, its light, its blessings, and its guidance, and I take refuge in You from the evil of what is in it and the evil of what follows it.',
            reference: 'أبو داود 5084',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'wakeup_4',
            arabicText:
                'أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ وَعَلَى كَلِمَةِ الْإِخْلَاصِ وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا وَمَا كَانَ مِنَ الْمُشْرِكِينَ',
            translationEn:
                'We rise upon the fitrah (natural disposition) of Islam, and the word of sincerity, and upon the religion of our Prophet Muhammad ﷺ, and upon the nation of our father Ibrahim who was a Hanif (monotheist) and was not of the polytheists.',
            reference: 'أحمد 15436',
            repeatCount: 1,
          ),
        ],
      );

  // ─── أدعية قرآنية ─────────────────────────────────────────────────
  static AdhkarCategory get _quranicDuas => AdhkarCategory(
        id: 'quran',
        titleAr: 'أدعية قرآنية',
        titleEn: 'Quranic Duas',
        subtitleAr: 'أدعية من القرآن الكريم',
        subtitleEn: 'Supplications from the Holy Quran',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF00695C),
        items: [
          const AdhkarItem(
            id: 'quran_1',
            arabicText:
                'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
            translationEn:
                'Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire.',
            reference: 'البقرة: 201',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'quran_2',
            arabicText:
                'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً ۚ إِنَّكَ أَنْتَ الْوَهَّابُ',
            translationEn:
                'Our Lord, let not our hearts deviate after You have guided us and grant us from Yourself mercy. Indeed, You are the Bestower.',
            reference: 'آل عمران: 8',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'quran_3',
            arabicText:
                'رَبَّنَا اغْفِرْ لَنَا ذُنُوبَنَا وَإِسْرَافَنَا فِي أَمْرِنَا وَثَبِّتْ أَقْدَامَنَا وَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
            translationEn:
                'Our Lord, forgive us our sins and the excess [committed] in our affairs and plant firmly our feet and give us victory over the disbelieving people.',
            reference: 'آل عمران: 147',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'quran_4',
            arabicText:
                'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِّن لِّسَانِي يَفْقَهُوا قَوْلِي',
            translationEn:
                'My Lord, expand for me my breast [with assurance] and ease for me my task and untie the knot from my tongue, that they may understand my speech. (Dua of Moses)',
            reference: 'طه: 25-28',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'quran_5',
            arabicText:
                'رَبِّ إِنِّي لِمَا أَنزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
            translationEn:
                'My Lord, indeed I am, for whatever good You would send down to me, in need. (Dua of Moses)',
            reference: 'القصص: 24',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'quran_6',
            arabicText:
                'لَا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
            translationEn:
                'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers. (Dua of Yunus)',
            reference: 'الأنبياء: 87',
            repeatCount: 1,
            virtue:
                'ما دعا بها مسلم في شيء قط إلا استجاب الله له',
          ),
          const AdhkarItem(
            id: 'quran_7',
            arabicText:
                'رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَىٰ وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحًا تَرْضَاهُ وَأَدْخِلْنِي بِرَحْمَتِكَ فِي عِبَادِكَ الصَّالِحِينَ',
            translationEn:
                'My Lord, enable me to be grateful for Your favour which You have bestowed upon me and upon my parents and to do righteousness of which You approve. And admit me by Your mercy into [the ranks of] Your righteous servants.',
            reference: 'النمل: 19',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'quran_8',
            arabicText:
                'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
            translationEn:
                'Our Lord, grant us from among our wives and offspring comfort to our eyes and make us an example for the righteous.',
            reference: 'الفرقان: 74',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'quran_9',
            arabicText:
                'رَبِّ زِدْنِي عِلْمًا',
            translationEn: 'My Lord, increase me in knowledge.',
            reference: 'طه: 114',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'quran_10',
            arabicText:
                'رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ',
            translationEn:
                'Our Lord, forgive me and my parents and the believers the Day the account is established.',
            reference: 'إبراهيم: 41',
            repeatCount: 1,
          ),
        ],
      );

  // ─── أذكار الأكل والشرب ───────────────────────────────────────────
  static AdhkarCategory get _eatingDrinkingAdhkar => AdhkarCategory(
        id: 'eating',
        titleAr: 'أذكار الأكل والشرب',
        titleEn: 'Eating & Drinking',
        subtitleAr: 'قبل الطعام وبعده',
        subtitleEn: 'Before and after meals',
        icon: Icons.restaurant_rounded,
        color: const Color(0xFF8B4513),
        items: [
          const AdhkarItem(
            id: 'eating_1',
            arabicText: 'بِسْمِ اللَّهِ',
            translationEn: 'In the name of Allah.',
            reference: 'أبو داود 3767، الترمذي 1858',
            repeatCount: 1,
            virtue: 'من ذكر اسم الله على طعامه لم يجد الشيطان في طعامه',
          ),
          const AdhkarItem(
            id: 'eating_2',
            arabicText:
                'بِسْمِ اللَّهِ أَوَّلَهُ وَآخِرَهُ',
            translationEn:
                'In the name of Allah at its beginning and at its end. (If one forgets at the beginning)',
            reference: 'أبو داود 3767',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'eating_3',
            arabicText:
                'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
            translationEn:
                'Praise is to Allah Who has fed me this and provided it for me without any might or power on my part.',
            reference: 'أبو داود 4023، الترمذي 3458',
            repeatCount: 1,
            virtue: 'غُفر له ما تقدم من ذنبه',
          ),
          const AdhkarItem(
            id: 'eating_4',
            arabicText:
                'الْحَمْدُ لِلَّهِ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ غَيْرَ مَكْفِيٍّ وَلَا مُوَدَّعٍ وَلَا مُسْتَغْنًى عَنْهُ رَبَّنَا',
            translationEn:
                'All praise is to Allah, praise that is abundant, pure and full of blessing, that is not offered to show independence from Him, nor the kind offered when bidding farewell, nor the kind that can be done without, O our Lord.',
            reference: 'البخاري 5458',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'eating_5',
            arabicText:
                'اللَّهُمَّ بَارِكْ لَنَا فِيهِ وَأَطْعِمْنَا خَيْرًا مِنْهُ',
            translationEn:
                'O Allah, bless us in it and feed us with what is better than it. (When drinking milk)',
            reference: 'الترمذي 3455',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'eating_6',
            arabicText:
                'اللَّهُمَّ أَطْعِمْ مَنْ أَطْعَمَنِي وَاسْقِ مَنْ سَقَانِي',
            translationEn:
                'O Allah, feed the one who fed me and give drink to the one who gave me drink.',
            reference: 'مسلم 2055',
            repeatCount: 1,
          ),
        ],
      );

  // ─── أذكار الدخول والخروج ──────────────────────────────────────────
  static AdhkarCategory get _homeMosqueAdhkar => AdhkarCategory(
        id: 'home_mosque',
        titleAr: 'أذكار الدخول والخروج',
        titleEn: 'Entering & Leaving',
        subtitleAr: 'دخول المنزل والمسجد والخروج',
        subtitleEn: 'Home, mosque, and trip',
        icon: Icons.home_rounded,
        color: const Color(0xFF1565C0),
        items: [
          const AdhkarItem(
            id: 'entry_1',
            arabicText:
                'بِسْمِ اللَّهِ وَلَجْنَا وَبِسْمِ اللَّهِ خَرَجْنَا وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا',
            translationEn:
                'In the name of Allah we enter and in the name of Allah we leave, and upon Allah our Lord we rely.',
            reference: 'أبو داود 5096',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'entry_2',
            arabicText:
                'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ الْمَوْلِجِ وَخَيْرَ الْمَخْرَجِ بِسْمِ اللَّهِ وَلَجْنَا وَبِسْمِ اللَّهِ خَرَجْنَا وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا',
            translationEn:
                'O Allah, I ask You for the good of the entrance and the good of the exit. In the name of Allah we enter, in the name of Allah we leave, and upon Allah our Lord we rely.',
            reference: 'أبو داود 5096',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'entry_3',
            arabicText:
                'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
            translationEn:
                'O Allah, open the gates of Your mercy for me. (Entering the mosque)',
            reference: 'مسلم 713',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'entry_4',
            arabicText:
                'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
            translationEn:
                'O Allah, I ask You of Your bounty. (Leaving the mosque)',
            reference: 'مسلم 713',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'entry_5',
            arabicText:
                'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
            translationEn:
                'In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah. (Leaving home)',
            reference: 'أبو داود 5095',
            repeatCount: 1,
            virtue: 'يقال له: كُفيت ووُقيت وهُديت',
          ),
          const AdhkarItem(
            id: 'entry_6',
            arabicText:
                'اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى وَمِنَ الْعَمَلِ مَا تَرْضَى، اللَّهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هَذَا وَاطْوِ عَنَّا بُعْدَهُ، اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ وَالْخَلِيفَةُ فِي الْأَهْلِ',
            translationEn:
                'O Allah, we ask You on this journey for goodness and piety, and for works that are pleasing to You. O Allah, lighten this journey for us and make its distance easy for us. O Allah, You are our Companion on the road and the One Who stays behind to look after the family.',
            reference: 'مسلم 1342 – دعاء السفر',
            repeatCount: 1,
          ),
        ],
      );

  // ─── أدعية متنوعة ─────────────────────────────────────────────────
  static AdhkarCategory get _miscDuas => AdhkarCategory(
        id: 'misc',
        titleAr: 'أدعية متنوعة',
        titleEn: 'Miscellaneous Duas',
        subtitleAr: 'أدعية جامعة مأثورة',
        subtitleEn: 'General authentic supplications',
        icon: Icons.volunteer_activism_rounded,
        color: const Color(0xFF558B2F),
        items: [
          const AdhkarItem(
            id: 'misc_1',
            arabicText:
                'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْجَنَّةَ وَأَعُوذُ بِكَ مِنَ النَّارِ',
            translationEn:
                'O Allah, I ask You for Paradise and I seek refuge in You from the Fire.',
            reference: 'أبو داود 792',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'misc_2',
            arabicText:
                'اللَّهُمَّ اغْفِرْ لِي وَارْحَمْنِي وَاهْدِنِي وَعَافِنِي وَارْزُقْنِي',
            translationEn:
                'O Allah, forgive me, have mercy on me, guide me, give me health and grant me provision.',
            reference: 'مسلم 2697',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'misc_3',
            arabicText:
                'اللَّهُمَّ إِنِّي أَعُوذُ بِرِضَاكَ مِنْ سَخَطِكَ وَبِمُعَافَاتِكَ مِنْ عُقُوبَتِكَ وَأَعُوذُ بِكَ مِنْكَ لَا أُحْصِي ثَنَاءً عَلَيْكَ أَنْتَ كَمَا أَثْنَيْتَ عَلَى نَفْسِكَ',
            translationEn:
                'O Allah, I seek refuge in Your pleasure from Your anger, and in Your forgiveness from Your punishment, and I seek refuge in You from You. I cannot enumerate Your praise, You are as You have praised Yourself.',
            reference: 'مسلم 486',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'misc_4',
            arabicText:
                'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنَ الْخَيْرِ كُلِّهِ عَاجِلِهِ وَآجِلِهِ مَا عَلِمْتُ مِنْهُ وَمَا لَمْ أَعْلَمْ وَأَعُوذُ بِكَ مِنَ الشَّرِّ كُلِّهِ عَاجِلِهِ وَآجِلِهِ مَا عَلِمْتُ مِنْهُ وَمَا لَمْ أَعْلَمْ',
            translationEn:
                'O Allah, I ask You for all good, immediate and in the future, that which I know and that which I do not know. And I seek refuge in You from all evil, immediate and in the future, that which I know and that which I do not know.',
            reference: 'ابن ماجه 3846',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'misc_5',
            arabicText:
                'اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي وَاجْعَلِ الْحَيَاةَ زِيَادَةً لِي فِي كُلِّ خَيْرٍ وَاجْعَلِ الْمَوْتَ رَاحَةً لِي مِنْ كُلِّ شَرٍّ',
            translationEn:
                'O Allah, set right for me my religion which is the safeguard of my affairs. And set right for me the affairs of my world wherein is my livelihood. And set right for me my Hereafter on which depends my after-life. And make the life for me a source of abundance for every good, and make my death a source of comfort for me protecting me against every evil.',
            reference: 'مسلم 2720',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'misc_6',
            arabicText:
                'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا أَنْتَ أَسْتَغْفِرُكَ وَأَتُوبُ إِلَيْكَ',
            translationEn:
                'How perfect You are O Allah, and all praise is for You, I bear witness that none has the right to be worshipped except You. I seek Your forgiveness and turn to You in repentance. (Kaffarah al-Majlis)',
            reference: 'الترمذي 3433',
            repeatCount: 1,
            virtue:
                'كفارة المجلس – من قالها في المجلس صارت كفارةً له',
          ),
          const AdhkarItem(
            id: 'misc_7',
            arabicText:
                'اللَّهُمَّ إِنِّي ظَلَمْتُ نَفْسِي ظُلْمًا كَثِيرًا وَلَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ فَاغْفِرْ لِي مَغْفِرَةً مِنْ عِنْدِكَ وَارْحَمْنِي إِنَّكَ أَنْتَ الْغَفُورُ الرَّحِيمُ',
            translationEn:
                'O Allah, I have greatly wronged myself and no one forgives sins but You. So grant me forgiveness and have mercy on me. Surely, you are Forgiving, Merciful.',
            reference: 'البخاري 834، مسلم 2705',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'misc_8',
            arabicText:
                'اللَّهُمَّ اجْعَلْنِي مِنَ الَّذِينَ إِذَا أَحْسَنُوا اسْتَبْشَرُوا وَإِذَا أَسَاءُوا اسْتَغْفَرُوا',
            translationEn:
                'O Allah, make me of those who, when they do good, feel happiness, and when they do evil, seek forgiveness.',
            reference: 'ابن ماجه 3820',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'misc_9',
            arabicText:
                'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
            translationEn:
                'O Ever Living, O Self-Sustaining and Supporter of all, by Your mercy I seek assistance. Rectify for me all of my affairs and do not leave me to myself, even for the blink of an eye.',
            reference: 'السلسلة الصحيحة 227',
            repeatCount: 1,
          ),
          const AdhkarItem(
            id: 'misc_10',
            arabicText:
                'اللَّهُمَّ لَكَ أَسْلَمْتُ وَبِكَ آمَنْتُ وَعَلَيْكَ تَوَكَّلْتُ وَإِلَيْكَ أَنَبْتُ وَبِكَ خَاصَمْتُ اللَّهُمَّ إِنِّي أَعُوذُ بِعِزَّتِكَ لَا إِلَٰهَ إِلَّا أَنْتَ أَنْ تُضِلَّنِي أَنْتَ الْحَيُّ الَّذِي لَا يَمُوتُ وَالْجِنُّ وَالْإِنْسُ يَمُوتُونَ',
            translationEn:
                'O Allah, to You I have submitted, and in You I have believed, and in You I put my trust, and to You I turn repentantly, and for Your sake I dispute. O Allah, I seek refuge in Your glory – there is no deity except You – from being led astray. You are the Ever-Living Who does not die, while the jinn and mankind die.',
            reference: 'البخاري 7383، مسلم 2717',
            repeatCount: 1,
          ),
        ],
      );
}
