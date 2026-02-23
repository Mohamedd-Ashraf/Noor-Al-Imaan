import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../features/quran/domain/usecases/get_ayah.dart';
import 'tafsir_state.dart';

class TafsirCubit extends Cubit<TafsirState> {
  final GetAyah _getAyah;

  // Reference stored so we can re-fetch when edition changes.
  late int _surahNumber;
  late int _ayahNumber;

  TafsirCubit(this._getAyah)
      : super(
          TafsirState.initial(ApiConstants.tafsirMuyassar),
        );

  /// Must be called once after the cubit is provided.
  Future<void> init({
    required int surahNumber,
    required int ayahNumber,
    String? initialEdition,
  }) async {
    _surahNumber = surahNumber;
    _ayahNumber = ayahNumber;
    await _fetch(initialEdition ?? ApiConstants.tafsirMuyassar);
  }

  /// Switch to a different tafsir edition and re-fetch.
  Future<void> selectEdition(String edition) async {
    if (edition == state.selectedEdition && state.status == TafsirStatus.loaded) {
      return; // already showing this edition
    }
    await _fetch(edition);
  }

  Future<void> retry() async => _fetch(state.selectedEdition);

  Future<void> _fetch(String edition) async {
    emit(state.copyWith(
      status: TafsirStatus.loading,
      selectedEdition: edition,
      tafsirText: '',
      errorMessage: '',
    ));

    final reference = '$_surahNumber:$_ayahNumber';
    final result = await _getAyah(
      GetAyahParams(reference: reference, edition: edition),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: TafsirStatus.error,
        errorMessage: failure.message,
      )),
      (ayah) => emit(state.copyWith(
        status: TafsirStatus.loaded,
        tafsirText: ayah.text,
      )),
    );
  }
}
