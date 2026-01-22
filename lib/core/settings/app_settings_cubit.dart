import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/settings_service.dart';

class AppSettingsState extends Equatable {
  final double arabicFontSize;
  final double translationFontSize;
  final bool darkMode;
  final bool showTranslation;
  final String appLanguageCode;

  const AppSettingsState({
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.darkMode,
    required this.showTranslation,
    required this.appLanguageCode,
  });

  factory AppSettingsState.initial(SettingsService service) {
    return AppSettingsState(
      arabicFontSize: service.getArabicFontSize(),
      translationFontSize: service.getTranslationFontSize(),
      darkMode: service.getDarkMode(),
      showTranslation: service.getShowTranslation(),
      appLanguageCode: service.getAppLanguage(),
    );
  }

  AppSettingsState copyWith({
    double? arabicFontSize,
    double? translationFontSize,
    bool? darkMode,
    bool? showTranslation,
    String? appLanguageCode,
  }) {
    return AppSettingsState(
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      darkMode: darkMode ?? this.darkMode,
      showTranslation: showTranslation ?? this.showTranslation,
      appLanguageCode: appLanguageCode ?? this.appLanguageCode,
    );
  }

  @override
  List<Object?> get props => [arabicFontSize, translationFontSize, darkMode, showTranslation, appLanguageCode];
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
}
