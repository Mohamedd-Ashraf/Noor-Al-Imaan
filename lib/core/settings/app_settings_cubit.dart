import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/settings_service.dart';

class AppSettingsState extends Equatable {
  final double arabicFontSize;
  final double translationFontSize;
  final bool darkMode;
  final bool showTranslation;
  final String appLanguageCode;
  final bool useUthmaniScript;
  final bool pageFlipRightToLeft;
  final String diacriticsColorMode; // 'same' or 'different'
  final String quranEdition; // API edition identifier e.g. 'quran-uthmani'
  final String quranFont;   // font key e.g. 'amiri_quran'

  const AppSettingsState({
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.darkMode,
    required this.showTranslation,
    required this.appLanguageCode,
    required this.useUthmaniScript,
    required this.pageFlipRightToLeft,
    required this.diacriticsColorMode,
    required this.quranEdition,
    required this.quranFont,
  });

  factory AppSettingsState.initial(SettingsService service) {
    return AppSettingsState(
      arabicFontSize: service.getArabicFontSize(),
      translationFontSize: service.getTranslationFontSize(),
      darkMode: service.getDarkMode(),
      showTranslation: service.getShowTranslation(),
      appLanguageCode: service.getAppLanguage(),
      useUthmaniScript: service.getUseUthmaniScript(),
      pageFlipRightToLeft: service.getPageFlipRightToLeft(),
      diacriticsColorMode: service.getDiacriticsColorMode(),
      quranEdition: service.getQuranEdition(),
      quranFont: service.getQuranFont(),
    );
  }

  AppSettingsState copyWith({
    double? arabicFontSize,
    double? translationFontSize,
    bool? darkMode,
    bool? showTranslation,
    String? appLanguageCode,
    bool? useUthmaniScript,
    bool? pageFlipRightToLeft,
    String? diacriticsColorMode,
    String? quranEdition,
    String? quranFont,
  }) {
    return AppSettingsState(
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      darkMode: darkMode ?? this.darkMode,
      showTranslation: showTranslation ?? this.showTranslation,
      appLanguageCode: appLanguageCode ?? this.appLanguageCode,
      useUthmaniScript: useUthmaniScript ?? this.useUthmaniScript,
      pageFlipRightToLeft: pageFlipRightToLeft ?? this.pageFlipRightToLeft,
      diacriticsColorMode: diacriticsColorMode ?? this.diacriticsColorMode,
      quranEdition: quranEdition ?? this.quranEdition,
      quranFont: quranFont ?? this.quranFont,
    );
  }

  @override
  List<Object?> get props => [
    arabicFontSize,
    translationFontSize,
    darkMode,
    showTranslation,
    appLanguageCode,
    useUthmaniScript,
    pageFlipRightToLeft,
    diacriticsColorMode,
    quranEdition,
    quranFont,
  ];
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  final SettingsService _service;

  AppSettingsCubit(this._service) : super(AppSettingsState.initial(_service));

  Future<void> setArabicFontSize(double value) async {
    await _service.setArabicFontSize(value);
    emit(state.copyWith(arabicFontSize: value));
  }

  Future<void> setTranslationFontSize(double value) async {
    await _service.setTranslationFontSize(value);
    emit(state.copyWith(translationFontSize: value));
  }

  Future<void> setDarkMode(bool value) async {
    await _service.setDarkMode(value);
    emit(state.copyWith(darkMode: value));
  }

  Future<void> setShowTranslation(bool value) async {
    await _service.setShowTranslation(value);
    emit(state.copyWith(showTranslation: value));
  }

  Future<void> setAppLanguage(String languageCode) async {
    await _service.setAppLanguage(languageCode);
    emit(state.copyWith(appLanguageCode: languageCode));
  }

  Future<void> setUseUthmaniScript(bool value) async {
    await _service.setUseUthmaniScript(value);
    emit(state.copyWith(useUthmaniScript: value));
  }

  Future<void> setPageFlipRightToLeft(bool value) async {
    await _service.setPageFlipRightToLeft(value);
    emit(state.copyWith(pageFlipRightToLeft: value));
  }

  Future<void> setDiacriticsColorMode(String mode) async {
    print('⚙️ setDiacriticsColorMode called with: $mode');
    await _service.setDiacriticsColorMode(mode);
    print('⚙️ Emitting new state with diacriticsColorMode: $mode');
    emit(state.copyWith(diacriticsColorMode: mode));
    print('⚙️ State emitted. Current state: ${state.diacriticsColorMode}');
  }

  Future<void> setQuranEdition(String edition) async {
    await _service.setQuranEdition(edition);
    emit(state.copyWith(quranEdition: edition));
  }

  Future<void> setQuranFont(String font) async {
    await _service.setQuranFont(font);
    emit(state.copyWith(quranFont: font));
  }
}
